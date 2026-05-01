# Mapa dos BitDevs hospedados no Brasil.

Serve pra responder:

- Bitdevs X acontece em qual data ?
- Bitdevs X acontece no mesmo dia que Bitdevs Y ?
- Tem algum link de evento para Bitdevs X ? Se sim, Qual ?

🌐 **[bitdevs-br.github.io](https://SEU_ORG.github.io/bitdevs-br)**

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
  "regradata": { "semana": -1, "dia": 2 },
  "horario": "19:00", // horário local (opcional)
  "linktopicos": "https://...", // site ou meetup (opcional)
  "linkevento": "https://..."
  "notes": "Última terça-feira, aperte a campainha tres vezes" // descrição humana da regra e instrucoes adversas
}
```

### Regra de recorrência (`rule`)

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

### Checklist do PR

- [ ] `id` é único e em slug curto (ex: `"fortaleza"`)
- [ ] `rule` foi testada — a data gerada bate com os encontros anteriores
- [ ] `notes` descreve a regra em português para humanos

## Desenvolvimento local

```sh
# qualquer servidor estático serve
python3 -m http.server 8080
# acesse http://localhost:8080
```

Pra quem eh chad e usa nix, o devshell provem livereload.
