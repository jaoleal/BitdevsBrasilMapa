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
- [Assinando seu BitDev](#assinando-seu-bitdev)
  - [Como assinar](#como-assinar)
  - [Como verificar](#como-verificar)
  - [No PR](#no-pr)
  - [Secao de assinantes no site](#seção-de-assinantes-no-site)
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

## Assinando seu BitDev

Cada contribuidor assina **apenas a sua propria entrada** no `bitdevs.json`, isolada com `jq`. Assim, quando outra cidade eh adicionada ou alterada, a sua assinatura continua valida.

As assinaturas ficam no diretorio [`assinaturas/`](./assinaturas/), nomeadas pelo `id` da entrada: `assinaturas/<id>.asc`.

### Como assinar

```sh
# extrai sua entrada e assina
jq '.[] | select(.id == "sp")' bitdevs.json | gpg --detach-sign --armor -o assinaturas/sp.asc
```

Substitua `"sp"` pelo `id` do seu BitDev.

### Como verificar

```sh
# extrai a mesma entrada e verifica contra a assinatura
jq '.[] | select(.id == "sp")' bitdevs.json | gpg --verify assinaturas/sp.asc -
```

Se a entrada no JSON nao foi alterada desde a assinatura, a verificacao passa.

### No PR

- Inclua o arquivo `assinaturas/<id>.asc` junto com sua alteracao no `bitdevs.json`
- Sua chave publica deve estar disponivel em um keyserver ou no seu perfil do GitHub (`https://github.com/<usuario>.gpg`)
- Se voce alterar sua entrada, reassine e atualize o `.asc`

### Seção de assinantes no site

Quando um `.asc` eh mergeado no master, um workflow do CI gera automaticamente o arquivo `assinantes.json` com:

- **Avatar** do GitHub (via `https://github.com/<user>.png`)
- **Link** para o perfil do GitHub
- **Fingerprint PGP** extraido da assinatura
- **ID do BitDev** correspondente

Esses dados alimentam a secao "Assinantes" no site. Nao eh necessario editar `assinantes.json` manualmente — o CI cuida disso.

---

## Desenvolvimento local

```sh
# qualquer servidor estático serve
python3 -m http.server 8080
# acesse http://localhost:8080
```

Pra quem eh chad e usa nix, o devshell provem livereload.
