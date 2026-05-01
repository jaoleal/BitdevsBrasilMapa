{
  description = "BitDevs Brasil Map";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, self', ... }:
        {
          checks.validate =
            pkgs.runCommand "validate-bitdevs-json"
              {
                nativeBuildInputs = [ pkgs.jq ];
                src = ./bitdevs.json;
              }
              ''
                FILE="$src"
                errors=0

                if ! jq empty "$FILE" 2>/dev/null; then
                  echo "ERRO: JSON malformado"
                  exit 1
                fi

                count=$(jq length "$FILE")
                echo "Encontrados $count grupos"

                dupes=$(jq -r '.[].id' "$FILE" | sort | uniq -d)
                if [[ -n "$dupes" ]]; then
                  echo "ERRO: IDs duplicados: $dupes"
                  errors=$((errors + 1))
                fi

                for i in $(seq 0 $((count - 1))); do
                  entry=$(jq ".[$i]" "$FILE")
                  id=$(echo "$entry" | jq -r '.id')

                  if ! echo "$id" | grep -qE '^[a-z0-9-]+$'; then
                    echo "ERRO [$id]: id não é slug válido (use apenas a-z, 0-9, -)"
                    errors=$((errors + 1))
                  fi

                  for field in nome cidade estado; do
                    val=$(echo "$entry" | jq -r ".$field // empty")
                    if [[ -z "$val" ]]; then
                      echo "ERRO [$id]: campo '$field' ausente ou vazio"
                      errors=$((errors + 1))
                    fi
                  done

                  regradata_null=$(echo "$entry" | jq '.regradata == null')
                  if [[ "$regradata_null" == "false" ]]; then
                    semana=$(echo "$entry" | jq '.regradata.semana // empty')
                    if [[ -z "$semana" ]] || ! echo "$semana" | grep -qE '^-?[12]$'; then
                      echo "ERRO [$id]: regradata.semana inválido ($semana) — esperado: 1, 2, -1, -2"
                      errors=$((errors + 1))
                    fi

                    dia=$(echo "$entry" | jq '.regradata.dia // empty')
                    if [[ -z "$dia" ]] || ! echo "$dia" | grep -qE '^[0-6]$'; then
                      echo "ERRO [$id]: regradata.dia inválido ($dia) — esperado: 0-6"
                      errors=$((errors + 1))
                    fi
                  fi
                done

                if [[ $errors -gt 0 ]]; then
                  echo "Validação falhou com $errors erro(s)"
                  exit 1
                fi

                echo "Validação OK"
                touch $out
              '';

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.python3Packages.livereload
              pkgs.jq
            ];

            shellHook = ''
              echo "Rode livereload -p 8000 ."
              echo "E acesse o site em: http://localhost:8000"
            '';
          };
        };
    };
}
