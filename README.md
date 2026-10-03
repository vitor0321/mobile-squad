# mobile-squad

Plugin do Claude Code com um time de agentes para entregar features em apps Kotlin Multiplatform /
Compose Multiplatform.

| Agente | Papel |
|---|---|
| `product-manager` | Discovery, PRD, quebra em tasks, issues no GitHub |
| `mobile-designer` | UX_SPEC antes das tasks; revisão de UI depois do código |
| `tech-lead` | Revisão das tasks antes do código; aceite depois |
| `kmp-developer` | Implementação KMP/CMP |
| `qa-engineer` | Plano de testes e testes automatizados |
| `senior-reviewer` | Revisão de código e de testes |

Revisores (Tech Lead, Designer, Revisor Sênior) não editam código: escrevem pareceres. O pipeline
**nunca faz commit, push nem fecha issue**.

## Fluxo

```
/squad-init  → docs/delivery/PROJECT_CONTEXT.md

/discover "ideia"                                     (interativo)
  PM pergunta ↔ você responde → PRD.md → você aprova
  Designer → UX_SPEC.md → você aprova                 (se há UI)

/deliver <slug> [--gate] [--no-issues] [--only T-NNN] (automático)
  PM cria tasks → Tech Lead revisa (máx. 2 rodadas) → issues no GitHub
  [--gate: você revisa as tasks]
  para cada task:
    Dev implementa → QA testa → Revisor Sênior ∥ Designer (se ui) → Tech Lead aceita
    reprovou? volta ao Dev (máx. 2 retrabalhos; depois bloqueia e chama você)
  DELIVERY_REPORT.md com sugestão de commit e PR
```

## Instalação

```bash
claude plugin marketplace add ~/Developer/mobile-squad
```

```bash
claude plugin install mobile-squad@mobile-squad
```

Reinicie a sessão do Claude Code. Os comandos aparecem como `/mobile-squad:squad-init`,
`/mobile-squad:discover` e `/mobile-squad:deliver` (ou sem prefixo, se não houver conflito).

Depois de editar o plugin: `claude plugin marketplace update mobile-squad` e
`claude plugin update mobile-squad@mobile-squad`.

## Uso num app

1. Na raiz do app: `/squad-init`. Confira os comandos de verificação sugeridos.
2. `/discover "jogadores podem convidar amigos para uma partida por link"`.
3. `/deliver convite-por-link --gate` na primeira vez; depois, sem `--gate` se confiar nas tasks.
4. Leia `docs/delivery/<slug>/DELIVERY_REPORT.md`, revise o diff e commite quando quiser.

## Documentos gerados no app

```
docs/delivery/
  PROJECT_CONTEXT.md
  <slug>/
    PRD.md
    UX_SPEC.md
    tasks/T-001-<slug>.md
    reviews/
      TASK_REVIEW.md
      T-001/TEST_PLAN.md
      T-001/CODE_REVIEW-r1.md
      T-001/UI_REVIEW-r1.md
      T-001/ACCEPTANCE.md
    DELIVERY_REPORT.md
```

Templates e regras (status, vereditos, severidades) em
[`skills/delivery-artifacts`](skills/delivery-artifacts/SKILL.md).

## Customização por app

- Regras do app vão no `CLAUDE.md` dele; todos os agentes o leem e ele prevalece sobre o plugin.
- Comandos de verificação ficam no `PROJECT_CONTEXT.md`; edite à mão se mudarem.
- Conhecimento genérico: [`kmp-standards`](skills/kmp-standards/SKILL.md) e
  [`mobile-ux-standards`](skills/mobile-ux-standards/SKILL.md).

## Desenvolvimento do plugin

```bash
bash scripts/check.sh
```

Valida a estrutura (agentes, skills, templates, papéis de só leitura, vereditos, ausência de
instruções de commit) e roda `claude plugin validate`.

Design: [`docs/specs`](docs/specs/2026-09-19-mobile-squad-design.md). Plano:
[`docs/plans`](docs/plans/2026-09-19-mobile-squad.md).
