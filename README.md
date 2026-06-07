# Mapa dos BitDevs hospedados no Brasil.

Serve pra responder:

- Bitdevs X acontece em qual data ?
- Bitdevs X acontece no mesmo dia que Bitdevs Y ?
- Tem algum link de evento para Bitdevs X ? Se sim, Qual ?

🌐 **[jaoleal.github.io/BitdevsBrasilMapa](https://jaoleal.github.io/BitdevsBrasilMapa)**

---

## Sumario

- [Adicionar cidade / Corrigir data](#quero-adicionar-minha-cidade--corrigir-uma-data)
  - [Formato](#formato)
  - [Regra de recorrencia](#regra-de-recorrência-regradata)
  - [Checklist do PR](#checklist-do-pr)
- [Como se tornar assinante](#como-se-tornar-assinante)
  - [Pre-requisitos](#pré-requisitos)
  - [Passo 1: Gerar sua chave PGP](#passo-1-gerar-sua-chave-pgp)
  - [Passo 2: Publicar sua chave](#passo-2-publicar-sua-chave)
  - [Passo 3: Assinar um BitDev](#passo-3-assinar-um-bitdev)
  - [Passo 4: Adicionar-se ao assinantes.json](#passo-4-adicionar-se-ao-assinantesjson)
  - [Passo 5: Abrir o PR](#passo-5-abrir-o-pr)
  - [Verificando assinaturas](#verificando-assinaturas)
  - [Reassinando apos alteracoes](#reassinando-após-alterações)
- [Desenvolvimento local](#desenvolvimento-local)

---

## Quero adicionar minha cidade / Corrigir uma data

Abra um PR editando o arquivo [`bitdevs.json`](./bitdevs.json).

### Formato

```json
{
  "id": "sp", // identificador único, sigla da cidade de preferencia
  "nome": "BitDevs São Paulo",
  "cidade": "São Paulo",
  "estado": "SP",
  "regradata": { "semana": -1, "dia": 4 },
  "horario": "19:00", // horário local (opcional)
  "linktopicos": "https://...", // site ou meetup (opcional)
  "linkevento": "https://...",
  "notes": "Última terça-feira, aperte a campainha tres vezes" // descrição humana da regra e instrucoes adversas
}
```

### Regra de recorrência (`regradata`)

| campo    | valores                                                             |
| -------- | ------------------------------------------------------------------- |
| `semana` | `1` primeiro · `2` segundo · `-1` último · `-2` penúltimo           |
| `dia`    | `0` dom · `1` seg · `2` ter · `3` qua · `4` qui · `5` sex · `6` sáb |

**Exemplos:**

| Regra em português            | JSON                         |
| ----------------------------- | ---------------------------- |
| Última quinta-feira do mês    | `{ "semana": -1, "dia": 4 }` |
| Penúltima quarta-feira do mês | `{ "semana": -2, "dia": 3 }` |
| Segunda terça-feira do mês    | `{ "semana": 2,  "dia": 2 }` |
| Primeiro sábado do mês        | `{ "semana": 1,  "dia": 6 }` |

---

## Como se tornar assinante

Assinantes sao pessoas que verificam e atestam que as informacoes de data e local dos BitDevs estao corretas. Ao assinar, voce confirma publicamente que determinado BitDev acontece na data indicada. Sua assinatura e identidade ficam visiveis na secao "Assinantes" do site.

### Pré-requisitos

- Uma conta no GitHub
- GPG instalado na sua maquina (`gpg --version` pra verificar)
- Familiaridade basica com terminal e Git

### Passo 1: Gerar sua chave PGP

Se voce ja tem uma chave PGP, pode pular este passo.

Existem varios tutoriais na internet que podem te ajudar melhor, por exemplo, [do proprio github.](https://docs.github.com/pt/authentication/managing-commit-signature-verification/generating-a-new-gpg-key)

```sh
gpg --list-keys --keyid-format long
```

O fingerprint eh a string de 40 caracteres hexadecimais, ex: `79F498EF30E0E2F32AC99AD4851C2EF386C0A2E4`.

### Passo 2: Publicar sua chave

Sua chave publica precisa estar disponivel para que outros possam verificar sua assinatura.

1. Exporte sua chave publica para o repositorio:
   ```sh
   gpg --armor --export seu-email@exemplo.com > chaves/seu-usuario.asc
   ```
2. (Recomendado) Publique tambem no GitHub para servir como fallback:
   - Va em **GitHub > Settings > SSH and GPG keys > New GPG key**
   - Cole a chave publica e salve
   - Apos isso, sua chave ficara disponivel em `https://github.com/seu-usuario.gpg`

### Passo 3: Assinar um BitDev

Cada assinatura eh feita sobre a entrada isolada de um BitDev no `bitdevs.json`, extraida com `jq`. Isso garante que alteracoes em outras cidades nao invalidem sua assinatura.

```sh
# Extraia a entrada e assine
jq '.[] | select(.id == "sp")' bitdevs.json \
  | gpg --detach-sign --armor -o assinaturas/sp/seu-usuario.asc
```

Substitua `"sp"` pelo `id` do BitDev que voce quer assinar e `seu-usuario` pelo seu username do GitHub.

Voce pode assinar quantos BitDevs quiser — basta repetir o processo para cada `id`.

### Passo 4: Adicionar-se ao assinantes.json

Edite o arquivo [`assinantes.json`](./assinantes.json) e adicione sua entrada:

```json
{
  "nome": "seu-usuario",
  "chave_pgp": "SEU_FINGERPRINT_DE_40_CARACTERES",
  "bitdevs_ids": ["sp", "bh"]
}
```

| campo         | descricao                                                 |
| ------------- | --------------------------------------------------------- |
| `nome`        | Seu username do GitHub                                    |
| `chave_pgp`   | Fingerprint completo da sua chave PGP (40 caracteres hex) |
| `bitdevs_ids` | Lista dos `id`s dos BitDevs que voce assinou              |

O avatar e o link para seu perfil sao derivados automaticamente do `nome`.

### Passo 5: Abrir o PR

Seu PR deve conter:

1. Sua chave publica em `chaves/seu-usuario.asc`
2. Os arquivos `.asc` em `assinaturas/<id>/seu-usuario.asc` para cada BitDev assinado
3. Sua entrada adicionada no `assinantes.json`

O CI vai verificar automaticamente se suas assinaturas sao validas contra as entradas correspondentes no `bitdevs.json`. Se alguma assinatura for invalida, o CI vai falhar.

### Verificando assinaturas

Para verificar manualmente se uma assinatura eh valida:

```sh
# Importe a chave publica do assinante (local, sem internet)
gpg --import chaves/seu-usuario.asc

# Verifique a assinatura
jq '.[] | select(.id == "sp")' bitdevs.json \
  | gpg --verify assinaturas/sp/seu-usuario.asc -
```

Se a entrada no JSON nao foi alterada desde a assinatura, a verificacao passa.

### Reassinando após alterações

Se a entrada de um BitDev for alterada no `bitdevs.json` (ex: mudanca de horario ou dia), todas as assinaturas daquele BitDev serao invalidadas. Os assinantes devem gerar novas assinaturas:

```sh
jq '.[] | select(.id == "sp")' bitdevs.json \
  | gpg --detach-sign --armor -o assinaturas/sp/seu-usuario.asc
```

---

## Desenvolvimento local

```sh
# qualquer servidor estático serve
python3 -m http.server 8080
# acesse http://localhost:8080
```

Pra quem eh chad e usa nix, o devshell provem livereload.
