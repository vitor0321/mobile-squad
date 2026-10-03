# mobile-squad: design

Plugin do Claude Code com um time de agentes para entregar features em apps Kotlin Multiplatform /
Compose Multiplatform: discovery, tasks, implementação, testes, revisão e aceite.

## Objetivo

Um desenvolvedor solo mantendo vários apps KMP/CMP precisa dos papéis de um time: Produto, Designer
mobile, Tech Lead, Dev, QA e Revisor Sênior. Cada papel é um subagente com responsabilidade estreita. Os papéis
conversam por **documentos padronizados em Markdown**, versionados no repo do app. O pipeline roda
sozinho da task até o aceite, para no limite de retrabalho e **nunca faz commit**.

Fora de escopo: deploy/release, publicação em loja, métricas de produção, Linear/Jira/Notion.

## Decisões

| Tema | Decisão |
|---|---|
| Artifacts | Documentos Markdown a partir de templates, em `docs/delivery/` do app |
| Distribuição | Plugin próprio, `~/Developer/mobile-squad`, instalado via marketplace local |
| Orquestração | `/discover` interativo + `/deliver` automático (`--gate` opcional) |
| Tasks | Markdown no repo, espelhadas em GitHub Issues via `gh` |
| Commit | Nunca. O pipeline termina com um relatório; o commit é pedido explícito do usuário |

Restrição que molda o desenho: subagente não chama subagente. O orquestrador é uma skill executada
na sessão principal, que despacha cada agente e passa os caminhos dos documentos.

## Estrutura do plugin

```
mobile-squad/
  .claude-plugin/
    plugin.json
    marketplace.json
  agents/
    product-manager.md
    mobile-designer.md
    tech-lead.md
    kmp-developer.md
    qa-engineer.md
    senior-reviewer.md
  skills/
    discover/SKILL.md          /discover
    deliver/SKILL.md           /deliver
    squad-init/SKILL.md        /squad-init: gera PROJECT_CONTEXT.md do app
    kmp-standards/SKILL.md     conhecimento técnico compartilhado (Dev, QA, TL, Revisor)
    mobile-ux-standards/SKILL.md  heurísticas de UX mobile (Designer, Dev, Revisor)
    delivery-artifacts/
      SKILL.md                 regras de status, nomes de arquivo e handoff
      templates/
        PROJECT_CONTEXT.md
        PRD.md
        UX_SPEC.md
        TASK.md
        TASK_REVIEW.md
        TEST_PLAN.md
        CODE_REVIEW.md
        UI_REVIEW.md
        ACCEPTANCE.md
        DELIVERY_REPORT.md
  docs/specs/
  README.md
```

## Agentes

Idioma de saída: português. Todos leem primeiro `docs/delivery/PROJECT_CONTEXT.md` e o `CLAUDE.md`
do app; o `CLAUDE.md` do app prevalece sobre o conhecimento genérico do plugin.

| Agente | Faz | Não faz | Ferramentas | Modelo |
|---|---|---|---|---|
| `product-manager` | Discovery (problema, usuário, métrica, escopo, fora de escopo), PRD, quebra em tasks verticais pequenas com critérios de aceite Given/When/Then, cria/atualiza issues | Decide arquitetura, escreve código | Read, Grep, Glob, Write, Edit, Bash (`gh`) | opus |
| `mobile-designer` | **Antes:** a partir do PRD, escreve `UX_SPEC.md`: fluxos, telas, estados (loading, vazio, erro, sucesso, offline), componentes do design system do app, textos pt/en, interações e gestos, a11y, comportamento em telas pequenas/grandes, dark mode, teclado e safe areas, diferenças Android/iOS. **Depois:** em tasks com `ui: true`, revisa a UI entregue contra o UX_SPEC e o design system (tokens, estados, a11y, i18n) e escreve `UI_REVIEW-rN.md` | Edita código; inventa componente fora do design system sem marcar como proposta | Read, Grep, Glob, Bash (leitura, testes de screenshot/preview quando o app tiver), Write (só specs e pareceres) | opus |
| `tech-lead` | **Antes:** revisa as tasks (viabilidade, módulo certo, dependências, riscos, tamanho, critérios testáveis) e anota orientação técnica. **Depois:** aceite: confere a entrega contra critérios de aceite e o parecer do Revisor | Edita código | Read, Grep, Glob, Bash (build/test, leitura), Write (só pareceres) | opus |
| `kmp-developer` | Implementa uma task por vez, respeitando `commonMain`, DI, CMP, strings, design system, a11y; roda build e testes existentes; corrige apontamentos | Escreve os testes da feature (isso é do QA); muda escopo | Read, Write, Edit, Grep, Glob, Bash | inherit |
| `qa-engineer` | Plano de testes derivado dos critérios de aceite; testes unitários em `commonTest` (ViewModel/UseCase/Repository com fakes, Turbine), testes de UI Compose quando a task tem tela; roda e reporta; bugs viram apontamentos para o Dev | Altera código de produção | Read, Write, Edit, Grep, Glob, Bash | inherit |
| `senior-reviewer` | Revisa código **e** testes: correção, coroutines/Flow, estado, `commonMain` portável, arquitetura, a11y, i18n, segurança; testes que testam comportamento e não implementação, casos de borda cobertos, flakiness | Edita qualquer arquivo além do parecer | Read, Grep, Glob, Bash (leitura, git diff), Write (só parecer) | opus |

Pareceres usam veredito fixo: `APPROVED` ou `CHANGES_REQUESTED`, com apontamentos classificados
como `blocker`, `major` ou `minor`. Só `blocker` e `major` reprovam.

## Artifacts por app

```
docs/delivery/
  PROJECT_CONTEXT.md                 stack, módulos, comandos de verificação, convenções
  <feature-slug>/
    PRD.md
    UX_SPEC.md
    tasks/
      T-001-<slug>.md                task + orientação do TL + histórico de status
    reviews/
      TASK_REVIEW.md                 parecer do TL sobre o conjunto de tasks
      T-001/
        TEST_PLAN.md
        CODE_REVIEW-r1.md            r1, r2... uma por rodada
        UI_REVIEW-r1.md              só em tasks com ui: true
        ACCEPTANCE.md
    DELIVERY_REPORT.md
```

`PROJECT_CONTEXT.md` define os comandos que o pipeline usa para verificar, por exemplo:
`build`, `test`, `lint` (detekt), `ios-compile`. `/squad-init` monta o arquivo lendo `CLAUDE.md`,
`settings.gradle.kts` e `libs.versions.toml`, e pede confirmação antes de salvar.

### Status da task (frontmatter)

```
draft → ready → in_progress → implemented → tested → reviewed → accepted
                     ↑______________ changes_requested ______________|
blocked (a partir de qualquer estado, com motivo)
```

Frontmatter mínimo: `id`, `title`, `status`, `issue` (número ou vazio), `depends_on`, `module`,
`ui` (true/false), `rework_count`.

## Fluxo

### `/discover [ideia]` (interativo)

1. Garante `PROJECT_CONTEXT.md` (senão roda `/squad-init`).
2. Despacha o `product-manager` em modo discovery. Ele devolve perguntas; a sessão principal faz as
   perguntas ao usuário, uma por vez, e repassa as respostas. Máximo de ~8 perguntas.
3. PM escreve `PRD.md`. Usuário aprova ou pede ajuste.
4. Se a feature tem UI, o `mobile-designer` escreve `UX_SPEC.md` a partir do PRD aprovado (pode
   devolver perguntas, repassadas ao usuário do mesmo jeito). Usuário aprova. Fim.

### `/deliver <feature-slug> [--gate] [--no-issues] [--only T-00X]`

1. **Tasks.** PM lê o PRD e o UX_SPEC aprovados e cria `tasks/T-*.md` (`draft`), marcando `ui`
   e referenciando as telas/estados do UX_SPEC que cada task cobre.
2. **Revisão de tasks.** TL escreve `TASK_REVIEW.md` e anota orientação técnica em cada task.
   `CHANGES_REQUESTED` → PM ajusta → TL revisa de novo (máx. 2 rodadas). Aprovadas → `ready`.
3. **Issues.** Se o repo tem remote GitHub e não há `--no-issues`: uma issue por task via `gh`,
   labels `squad:<status>`; o número volta para o frontmatter. Issues nunca são fechadas pelo
   pipeline (fecham no merge, via `Closes #N` sugerido no relatório).
4. **`--gate`:** pausa e mostra as tasks ao usuário antes de qualquer código.
5. **Por task, em ordem de dependência:**
   1. Dev implementa → `implemented`.
   2. QA escreve `TEST_PLAN.md` e os testes, roda a suíte → `tested`. Falha causada por bug de
      produção vira apontamento para o Dev.
   3. Revisor escreve `CODE_REVIEW-rN.md`; se `ui: true`, o Designer escreve `UI_REVIEW-rN.md`
      (os dois podem rodar em paralelo). Ambos aprovados → `reviewed`; qualquer reprovação →
      `changes_requested`.
   4. TL escreve `ACCEPTANCE.md`, roda os comandos de verificação → `accepted` ou
      `changes_requested`.
   5. `changes_requested` volta para o Dev (e QA, se o apontamento é de teste) com os pareceres.
      `rework_count` máximo 2; na terceira reprovação a task vai para `blocked` e o pipeline para
      e chama o usuário.
   6. Comentário na issue com o resumo da etapa.
6. **Relatório.** `DELIVERY_REPORT.md`: tasks e status, arquivos alterados por task, comandos de
   verificação e resultado, pendências `minor` não resolvidas, sugestão de mensagem de commit e de
   corpo de PR. A sessão mostra o resumo e espera. **Sem commit.**

Retomada: `/deliver` num feature já iniciado continua das tasks que não estão `accepted`, a partir
do status gravado.

## Tratamento de erro

- Build quebrado antes de começar: o pipeline para e reporta; não tenta arrumar o que não é da task.
- `gh` ausente, sem autenticação ou sem remote: segue sem issues e avisa no relatório.
- Agente devolve documento fora do template: o orquestrador pede a correção uma vez; se falhar de
  novo, marca a task `blocked`.
- Bug fora do escopo encontrado por qualquer agente: registrado em "Achados fora de escopo" no
  relatório, não corrigido.

## Conhecimento técnico (`kmp-standards`)

Referência compartilhada e enxuta, só com o que um agente genérico erra em KMP/CMP:
`commonMain` sem APIs de JVM (`java.*`, `Math`, `System.currentTimeMillis`), `expect/actual` só
quando não há lib multiplataforma, coroutines e `StateFlow` com estado imutável, ViewModel de
lifecycle multiplataforma, Koin, Compose (state hoisting, estabilidade, `remember`, efeitos),
navegação, testes com `kotlin.test` + `kotlinx-coroutines-test` + Turbine + fakes em vez de mocks,
acessibilidade (48dp, escala de fonte, `contentDescription`, contraste) e i18n. Regras específicas de
um app ficam no `CLAUDE.md` dele, não no plugin.

## Conhecimento de UX (`mobile-ux-standards`)

Heurísticas de UX mobile usadas pelo Designer (e consultadas por Dev e Revisor): Material 3 e iOS
HIG e quando divergir por plataforma em CMP, hierarquia e navegação (back, bottom bar, modais,
sheets), os cinco estados de toda tela, feedback de ação (loading, otimista, erro recuperável),
formulários e teclado (IME actions, foco, validação inline), gestos com alternativa acessível,
safe areas e edge-to-edge, tamanhos de tela e orientação, dark mode, escala de fonte até 200%,
alvo de toque 48dp/44pt, contraste, leitor de tela (ordem, agrupamento, rótulos), microcopy
clara e traduzível, movimento com respeito a "reduzir movimento". O design system do app
(tokens, componentes) é a fonte da verdade quando existe.

## Validação do plugin

- `claude plugin validate` (se disponível) e carregamento via `/plugin marketplace add`.
- Ensaio no `mobile-match`: `/squad-init`, `/discover` com uma feature pequena real, `/deliver
  --gate --no-issues` até o aceite de uma task. Critério de sucesso: os documentos seguem os
  templates, os status batem com o que aconteceu, a verificação roda e nada é commitado.
