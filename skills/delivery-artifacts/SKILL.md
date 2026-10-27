---
name: delivery-artifacts
description: Contrato de documentos do mobile-squad — pastas, templates, status das tasks, vereditos, ids de apontamento e o bloco de retorno "## Resultado". Use sempre que um agente do squad for ler ou escrever PRD, UX_SPEC, task, parecer, plano de testes ou relatório em docs/delivery/.
---

# Documentos do squad

Documento é o único canal entre os agentes: o que não está escrito não foi combinado.

```
docs/delivery/
  PROJECT_CONTEXT.md   verify.conf            /squad-init
  <feature-slug>/
    PRD.md  UX_SPEC.md                         product-manager, mobile-designer
    tasks/T-001-<slug>.md                      product-manager (+ orientação do tech-lead)
    reviews/TASK_REVIEW.md                     tech-lead
    reviews/T-001/TEST_PLAN.md                 qa-engineer
    reviews/T-001/CODE_REVIEW-r1.md            senior-reviewer
    reviews/T-001/UI_REVIEW-r1.md              mobile-designer (só ui: true)
    reviews/T-001/ACCEPTANCE.md                orquestrador, ou tech-lead se risk: high
    DELIVERY_REPORT.md                         orquestrador
```

- Parecer com `-rN` é um arquivo novo por rodada; **nunca sobrescreva uma rodada anterior**.
  `TASK_REVIEW`, `TEST_PLAN` e `ACCEPTANCE` ganham uma seção nova por rodada.
- Templates: `${CLAUDE_PLUGIN_ROOT}/skills/delivery-artifacts/templates/<DOCUMENTO>.md`. Preencha
  todas as seções e apague os comentários `<!-- -->`. Seção sem conteúdo: `N/A — <motivo>`.
- Escreva curto. Tabela lista só o que tem conteúdo; checklist registra só o que falhou.

## Verificação

Nunca rode Gradle direto para build/test/lint/ios-compile. Use `<verify>` =
`${CLAUDE_PLUGIN_ROOT}/scripts/verify.sh`, na raiz do app:

- `bash <verify> --auto`: build, test, lint e ios-compile se o working tree toca `commonMain`;
- `bash <verify> test`: só um comando.

Ele imprime `PASS`/`FAIL` por comando e as linhas de erro; o log completo fica em
`.squad/logs/<nome>.log`. Leia o log só se o trecho não bastar, e com `grep`/`tail`, nunca inteiro.

## Status da task

Vive no frontmatter e no histórico da task. Só o dono da transição a faz:

| Para | Quem |
|---|---|
| `draft` | product-manager |
| `ready`, `in_progress`, `reviewed`, `changes_requested` | orquestrador |
| `implemented` | kmp-developer |
| `tested` | qa-engineer |
| `accepted` | orquestrador (gate) ou tech-lead (`risk: high`) |
| `blocked` | quem encontrou o impedimento, com motivo |

Toda mudança acrescenta uma linha no histórico: `| 2026-09-19 | implemented | kmp-developer | resumo |`.

## Veredito, severidade e ids

Pareceres têm veredito `APPROVED` ou `CHANGES_REQUESTED`, nada além disso.

| Severidade | Significado | Reprova? |
|---|---|---|
| `blocker` | Quebra build, perde dado, crash, falha de segurança, critério de aceite não atendido | Sim |
| `major` | Bug provável, violação do `CLAUDE.md` do app, a11y/i18n quebrados, teste que não testa o que diz | Sim |
| `minor` | Melhoria, legibilidade, nome, sugestão | Não; vai para o relatório |

Qualquer `blocker`/`major` aberto = `CHANGES_REQUESTED`.

Id = prefixo + rodada + número, ex. `CR2-03`. Quem corrige responde por id.

| Prefixo | Origem | Quem corrige |
|---|---|---|
| `TR` | TASK_REVIEW | product-manager |
| `CR` | CODE_REVIEW, código de produção | kmp-developer |
| `CT` | CODE_REVIEW, testes | qa-engineer |
| `UI` | UI_REVIEW | kmp-developer |
| `QA` | bug de produção achado pelo QA | kmp-developer |
| `VF` | verificação vermelha no gate | kmp-developer |
| `AC` | ACCEPTANCE do tech-lead | kmp-developer |

## Bloco de retorno

Sua última mensagem ao orquestrador é **só** este bloco, mais no máximo 3 linhas de resumo. O
detalhe está no documento; não o repita.

```
## Resultado
status: <novo status da task; para PRD/UX_SPEC: draft | aguardando-aprovacao>
documento: <caminho do documento escrito ou atualizado>
veredito: APPROVED | CHANGES_REQUESTED
apontamentos: <ids abertos, ex. CR1-01, CT1-02>
arquivos: <arquivos de código/teste que você alterou nesta rodada>
perguntas:
  - <pergunta ao usuário>
```

Omita campos que não se aplicam. `perguntas` só quando você parou por precisar do usuário.

## Regras que valem para todos

- Nunca faça commit, push, stash ou feche issue.
- Bug fora do escopo da task: registre em "Achados fora de escopo"; não corrija.
- O `CLAUDE.md` do app prevalece sobre qualquer regra do plugin.
- Não invente o que o usuário não disse: pergunte (PM/Designer) ou registre como premissa.
