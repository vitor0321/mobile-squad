---
name: delivery-artifacts
description: Contrato de documentos do mobile-squad — pastas, templates, status das tasks, vereditos e o bloco de retorno "## Resultado". Use sempre que um agente do squad for ler ou escrever PRD, UX_SPEC, task, parecer, plano de testes ou relatório em docs/delivery/.
---

# Documentos do squad

Todo trabalho do squad vira documento Markdown no repo do app. Documento é o único canal entre os
agentes: o que não está escrito não foi combinado.

## Onde ficam

```
docs/delivery/
  PROJECT_CONTEXT.md                     /squad-init
  <feature-slug>/
    PRD.md                               product-manager
    UX_SPEC.md                           mobile-designer
    tasks/
      T-001-<slug>.md                    product-manager (+ orientação do tech-lead)
    reviews/
      TASK_REVIEW.md                     tech-lead
      T-001/
        TEST_PLAN.md                     qa-engineer
        CODE_REVIEW-r1.md                senior-reviewer
        UI_REVIEW-r1.md                  mobile-designer (só tasks com ui: true)
        ACCEPTANCE.md                    tech-lead
    DELIVERY_REPORT.md                   orquestrador (/deliver)
```

`<feature-slug>` é kebab-case curto (`convite-por-link`). Tasks numeradas por feature: `T-001`,
`T-002`… O sufixo `-rN` é a rodada de revisão (r1, r2, r3). **Nunca sobrescreva o parecer de uma
rodada anterior**; cada rodada é um arquivo novo. `TASK_REVIEW.md`, `TEST_PLAN.md` e
`ACCEPTANCE.md` são atualizados no lugar, com uma seção nova por rodada.

## Templates

Ficam em `${CLAUDE_PLUGIN_ROOT}/skills/delivery-artifacts/templates/`. Copie o template, preencha
todas as seções e apague os comentários `<!-- -->`. Seção sem conteúdo recebe `N/A — <motivo>`,
nunca é removida.

| Documento | Template |
|---|---|
| Contexto do app | `PROJECT_CONTEXT.md` |
| PRD | `PRD.md` |
| Especificação de UX | `UX_SPEC.md` |
| Task | `TASK.md` |
| Revisão das tasks | `TASK_REVIEW.md` |
| Plano de testes | `TEST_PLAN.md` |
| Revisão de código e testes | `CODE_REVIEW.md` |
| Revisão de UI | `UI_REVIEW.md` |
| Aceite | `ACCEPTANCE.md` |
| Relatório de entrega | `DELIVERY_REPORT.md` |

## Status da task

O status vive no frontmatter da task e no histórico dela. Só o dono da transição a faz:

| De → Para | Quem |
|---|---|
| (nova) → `draft` | product-manager |
| `draft` → `ready` | orquestrador, após `TASK_REVIEW` aprovado |
| `ready` / `changes_requested` → `in_progress` | orquestrador, ao despachar o Dev |
| `in_progress` → `implemented` | kmp-developer |
| `implemented` → `tested` | qa-engineer |
| `tested` → `reviewed` | orquestrador, com `CODE_REVIEW` (e `UI_REVIEW` se `ui: true`) aprovados |
| `reviewed` → `accepted` | tech-lead, com `ACCEPTANCE` aprovado |
| revisão reprovada → `changes_requested` | orquestrador, incrementa `rework_count` |
| qualquer → `blocked` | quem encontrou o impedimento, com motivo no histórico |

`rework_count` máximo 2. Uma terceira reprovação leva a task a `blocked` e o pipeline para.

Toda mudança de status acrescenta uma linha no histórico da task:
`| 2026-09-19 | implemented | kmp-developer | resumo em uma linha |`.

## Veredito e severidade

Pareceres (`TASK_REVIEW`, `CODE_REVIEW`, `UI_REVIEW`, `ACCEPTANCE`) têm veredito `APPROVED` ou
`CHANGES_REQUESTED`, nada além disso.

| Severidade | Significado | Reprova? |
|---|---|---|
| `blocker` | Quebra build, perde dado, crash, falha de segurança, critério de aceite não atendido | Sim |
| `major` | Bug provável, violação de regra do app (`CLAUDE.md`), a11y/i18n quebrados, teste que não testa o que diz | Sim |
| `minor` | Melhoria, legibilidade, nome, sugestão | Não; vai para o relatório |

Um parecer com qualquer `blocker` ou `major` aberto é `CHANGES_REQUESTED`. Sem eles, é `APPROVED`.

Cada apontamento tem id estável: prefixo do documento + rodada + número. `TR1-02` (TASK_REVIEW),
`CR1-03` (CODE_REVIEW), `UI2-01` (UI_REVIEW), `AC1-01` (ACCEPTANCE), `QA1-01` (bug achado pelo QA).
Quem corrige responde por id.

## Bloco de retorno

Todo agente termina a resposta ao orquestrador com este bloco, neste formato:

```
## Resultado
status: <novo status da task; para PRD/UX_SPEC: draft | aguardando-aprovacao>
documento: <caminho do documento escrito ou atualizado>
veredito: APPROVED | CHANGES_REQUESTED
perguntas:
  - <pergunta ao usuário>
```

`veredito` só para quem emite parecer. `perguntas` só quando o agente precisa do usuário e parou
por isso; nesse caso o documento fica como rascunho e o status não avança. Campos que não se
aplicam são omitidos.

## Regras que valem para todos

- Nunca faça commit, push ou feche issue. O squad entrega mudanças no working tree e um relatório.
- Bug fora do escopo da task: registre em "Achados fora de escopo" do seu documento; não corrija.
- O `CLAUDE.md` do app prevalece sobre qualquer regra genérica do plugin.
- Não invente o que o usuário não disse. Na dúvida sobre produto, pergunte (PM/Designer) ou
  registre como premissa explícita.
