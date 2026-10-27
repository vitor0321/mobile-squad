# mobile-squad


Plugin do Claude Code com um time de agentes para entregar features em apps Kotlin Multiplatform /
Compose Multiplatform.

| Agente | Papel |
|---|---|
| `product-manager` | Discovery, PRD, quebra em tasks |
| `mobile-designer` | UX_SPEC antes das tasks; revisão de UI depois do código |
| `tech-lead` | Revisão das tasks e risco de cada uma; aceite das tasks `risk: high` |
| `kmp-developer` | Implementação KMP/CMP |
| `qa-engineer` | Plano de testes e testes automatizados |
| `senior-reviewer` | Revisão de código e de testes |

Revisores (Tech Lead, Designer, Revisor Sênior) não editam código: escrevem pareceres. O pipeline
**nunca faz commit, push nem fecha issue**. Essas regras são garantidas por hook
([`hooks/guard.sh`](hooks/guard.sh)), não só pelo prompt: commit/push/stash/descarte de mudanças
bloqueados para os agentes do squad (e para a sessão principal enquanto `/deliver` roda), revisores
só escrevem em `docs/delivery/`, QA não escreve código de produção.

## Fluxo

```
/squad-init  → docs/delivery/PROJECT_CONTEXT.md + verify.conf

/discover "ideia"                                     (interativo)
  PM pergunta ↔ você responde → PRD.md → você aprova
  Designer → UX_SPEC.md → você aprova                 (se há UI)

/deliver <slug> [--gate] [--no-issues] [--only T-NNN] (automático)
  PM cria tasks → Tech Lead revisa e define risco (máx. 2 rodadas) → issues no GitHub (script)
  [--gate: você revisa as tasks]
  para cada task:
    Dev implementa → QA testa → Revisor Sênior ∥ Designer (se ui)
    → gate: verify.sh + matriz critério × evidência (+ Tech Lead se risk: high)
    reprovou? retrabalho incremental: só o dono do apontamento corrige e só quem
    reprovou (ou foi afetado) revisa de novo (máx. 2 retrabalhos; depois bloqueia e chama você)
  DELIVERY_REPORT.md com sugestão de commit e PR
```

## Instalação

```bash
claude plugin marketplace add vitor0321/mobile-squad      # pelo GitHub
claude plugin marketplace add ~/Developer/mobile-squad    # ou a cópia local
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

## Custo de tokens

O pipeline foi desenhado para não gastar contexto à toa:

- **`verify.sh`** roda build/test/lint/ios-compile a partir de `docs/delivery/verify.conf` e imprime
  só `PASS`/`FAIL` e as linhas de erro; o log completo fica em `.squad/logs/`. Nenhum agente vê a
  saída crua do Gradle.
- **Aceite sem agente** na maioria das tasks: o orquestrador roda `verify.sh` e confere a matriz do
  code review. O Tech Lead só entra em tasks `risk: high`.
- **Retrabalho incremental**: revisões da rodada 2+ olham só os arquivos do retrabalho e os
  apontamentos abertos.
- **Modelo por etapa**: `opus` onde o julgamento importa (discovery, UX_SPEC, revisão das tasks,
  code review da rodada 1); `sonnet` para quebra de tasks, QA e re-revisões.
- **Issues por script** ([`scripts/issues.sh`](scripts/issues.sh)), sem agente.
- Skills pré-carregadas só onde servem, retorno dos agentes limitado ao bloco `## Resultado` e
  pareceres que registram só o que falhou.

## Documentos gerados no app

```
docs/delivery/
  PROJECT_CONTEXT.md
  verify.conf
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
- Comandos de verificação ficam em `docs/delivery/verify.conf` (`nome=comando`); edite à mão se
  mudarem.
- Conhecimento genérico: [`kmp-standards`](skills/kmp-standards/SKILL.md) e
  [`mobile-ux-standards`](skills/mobile-ux-standards/SKILL.md).

## Desenvolvimento do plugin

```bash
bash scripts/check.sh
```

Valida a estrutura (agentes, skills, templates, scripts, hook, papéis de só leitura, vereditos,
prefixos de id, ausência de instruções de commit, de Gradle direto e de releitura de skill) e roda
`claude plugin validate`.

Design: [`docs/specs`](docs/specs/2026-09-19-mobile-squad-design.md). Plano:
[`docs/plans`](docs/plans/2026-09-19-mobile-squad.md).

