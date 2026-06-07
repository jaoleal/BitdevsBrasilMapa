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
        let
          # Arquivos do repositorio como inputs do nix store
          bitdevs-json = ./bitdevs.json;
          assinantes-json = ./assinantes.json;
          assinaturas = ./assinaturas;
          chaves = ./chaves;
          src = ./.;

          mkValidateBitdevs =
            file:
            pkgs.writeShellApplication {
              name = "validate-bitdevs";
              runtimeInputs = [ pkgs.jq ];
              text = ''
                FILE="${file}"
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
              '';
            };

          fmt = pkgs.writeShellApplication {
            name = "fmt";
            runtimeInputs = [
              pkgs.prettier
              pkgs.nixfmt
              pkgs.findutils
            ];
            text = ''
              echo "Formatando JSON, YAML, CSS, HTML..."
              prettier --write '**/*.json' '**/*.yml' '**/*.css' '**/*.html' \
                --ignore-path .gitignore 2>/dev/null || true

              echo "Formatando Nix..."
              find . -name '*.nix' -exec nixfmt {} +

              echo "Formatação concluída"
            '';
          };

          fmt-check = pkgs.writeShellApplication {
            name = "fmt-check";
            runtimeInputs = [
              pkgs.prettier
              pkgs.nixfmt
              pkgs.findutils
            ];
            text = ''
              errors=0

              echo "Verificando formatação JSON, YAML, CSS, HTML..."
              if ! prettier --check '**/*.json' '**/*.yml' '**/*.css' '**/*.html' \
                --ignore-path .gitignore 2>/dev/null; then
                errors=$((errors + 1))
              fi

              echo "Verificando formatação Nix..."
              if ! find . -name '*.nix' -exec nixfmt --check {} +; then
                errors=$((errors + 1))
              fi

              if [[ $errors -gt 0 ]]; then
                echo "ERRO: arquivos não formatados. Rode 'nix run .#fmt' para corrigir."
                exit 1
              fi

              echo "Formatação OK"
            '';
          };

          mkVerificarAssinaturas =
            {
              bitdevsJson,
              assinantesJson,
              assinaturasDir,
              chavesDir,
            }:
            pkgs.writeShellApplication {
              name = "verificar-assinaturas";
              runtimeInputs = [
                pkgs.jq
                pkgs.gnupg
                pkgs.curl
                pkgs.gawk
              ];
              text = ''
                failed=0
                total=0

                for asc in ${assinaturasDir}/*/*.asc; do
                  [ -f "$asc" ] || continue
                  total=$((total + 1))

                  bitdev_id=$(basename "$(dirname "$asc")")
                  github_user=$(basename "$asc" .asc)

                  echo "--- Verificando: $asc (bitdev=$bitdev_id, user=$github_user) ---"

                  # Verificar que bitdev_id existe em bitdevs.json
                  entry=$(jq -e --arg id "$bitdev_id" '.[] | select(.id == $id)' ${bitdevsJson} 2>/dev/null)
                  if [ -z "$entry" ]; then
                    echo "ERRO: bitdev_id '$bitdev_id' nao encontrado em bitdevs.json"
                    failed=$((failed + 1))
                    continue
                  fi

                  # Importar chave: preferir local, fallback GitHub
                  key_file="${chavesDir}/''${github_user}.asc"
                  if [ -f "$key_file" ]; then
                    echo "Importando chave local de $key_file"
                    gpg --import "$key_file" 2>/dev/null
                  else
                    echo "Chave local nao encontrada, buscando de https://github.com/$github_user.gpg"
                    if ! curl -sf "https://github.com/$github_user.gpg" | gpg --import 2>/dev/null; then
                      echo "ERRO: nao foi possivel importar a chave PGP de $github_user"
                      failed=$((failed + 1))
                      continue
                    fi
                  fi

                  # Validar fingerprint contra assinantes.json (quando chave local existe)
                  if [ -f "$key_file" ]; then
                    expected_fp=$(jq -r --arg nome "$github_user" \
                      '.[] | select(.nome == $nome) | .chave_pgp' ${assinantesJson})
                    imported_fp=$(gpg --with-colons --import-options show-only --import "$key_file" 2>/dev/null \
                      | awk -F: '/^fpr:/{print $10; exit}')
                    if [ -n "$expected_fp" ] && [ -n "$imported_fp" ] && [ "$expected_fp" != "$imported_fp" ]; then
                      echo "ERRO: fingerprint da chave ($imported_fp) nao bate com assinantes.json ($expected_fp)"
                      failed=$((failed + 1))
                      continue
                    fi
                  fi

                  # Verificar assinatura contra o entry extraido
                  if echo "$entry" | gpg --verify "$asc" - 2>&1; then
                    echo "OK: assinatura valida"
                  else
                    echo "ERRO: assinatura invalida para $asc"
                    failed=$((failed + 1))
                  fi

                  echo ""
                done

                echo "=== Resultado: $((total - failed))/$total assinaturas validas ==="

                if [ $failed -gt 0 ]; then
                  echo "FALHA: $failed assinatura(s) invalida(s)"
                  exit 1
                fi

                echo "Todas as assinaturas sao validas!"
              '';
            };
        in
        {
          apps.validate-bitdevs = {
            type = "app";
            program = "${mkValidateBitdevs "bitdevs.json"}/bin/validate-bitdevs";
          };

          apps.verificar-assinaturas = {
            type = "app";
            program = "${
              mkVerificarAssinaturas {
                bitdevsJson = "bitdevs.json";
                assinantesJson = "assinantes.json";
                assinaturasDir = "assinaturas";
                chavesDir = "chaves";
              }
            }/bin/verificar-assinaturas";
          };

          apps.fmt = {
            type = "app";
            program = "${fmt}/bin/fmt";
          };

          apps.fmt-check = {
            type = "app";
            program = "${fmt-check}/bin/fmt-check";
          };

          checks.validate-bitdevs = pkgs.runCommand "validate-bitdevs" { } ''
            ${mkValidateBitdevs bitdevs-json}/bin/validate-bitdevs
            touch $out
          '';

          checks.verificar-assinaturas = pkgs.runCommand "verificar-assinaturas" { } ''
            export HOME=$(mktemp -d)
            export GNUPGHOME="$HOME/.gnupg"
            mkdir -p "$GNUPGHOME"
            chmod 700 "$GNUPGHOME"
            ${
              mkVerificarAssinaturas {
                bitdevsJson = bitdevs-json;
                assinantesJson = assinantes-json;
                assinaturasDir = assinaturas;
                chavesDir = chaves;
              }
            }/bin/verificar-assinaturas
            touch $out
          '';

          checks.fmt = pkgs.runCommand "fmt-check" { } ''
            cd ${src}
            ${fmt-check}/bin/fmt-check
            touch $out
          '';

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.python3Packages.livereload
              pkgs.jq
              pkgs.prettier
              pkgs.nixfmt
            ];

            shellHook = ''
              echo "Rode livereload -p 8000 ."
              echo "E acesse o site em: http://localhost:8000"
            '';
          };
        };
    };
}
