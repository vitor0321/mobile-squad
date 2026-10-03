# mobile-squad Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Plugin do Claude Code com 6 agentes (PM, Designer mobile, Tech Lead, Dev KMP, QA, Revisor
Sênior), skills de orquestração (`/squad-init`, `/discover`, `/deliver`), skills de conhecimento e
templates de documentos para entregar features em apps KMP/CMP.

**Architecture:** Agentes em `agents/*.md` com ferramentas restritas por papel. A orquestração é uma
skill executada na sessão principal (subagente não chama subagente). Os agentes trocam documentos
Markdown em `docs/delivery/` do app, a partir de templates em `skills/delivery-artifacts/templates/`.

**Tech Stack:** Formato de plugin do Claude Code (`.claude-plugin/plugin.json`, `marketplace.json`,
`agents/`, `skills/<nome>/SKILL.md`), Bash, `gh` CLI.

**Spec:** `docs/specs/2026-09-19-mobile-squad-design.md`

## Global Constraints

- Todo texto voltado ao usuário e todo documento gerado em português.
- Nenhum agente, skill ou template instrui `git commit`, `git push` ou fechamento de issue. O fluxo
  termina em relatório; commit só por pedido explícito do usuário.
- `tech-lead`, `senior-reviewer` e `mobile-designer` não têm a ferramenta `Edit`; escrevem apenas
  seus documentos.
- `qa-engineer` não altera código de produção; `kmp-developer` não escreve os testes da feature.
- Veredito dos pareceres: exatamente `APPROVED` ou `CHANGES_REQUESTED`. Severidades: `blocker`,
  `major`, `minor`. Só `blocker`/`major` reprovam.
- Status da task: `draft`, `ready`, `in_progress`, `implemented`, `tested`, `reviewed`, `accepted`,
  `changes_requested`, `blocked`.
- Frontmatter da task: `id`, `title`, `status`, `issue`, `depends_on`, `module`, `ui`,
  `rework_count`.
- Limite de retrabalho: `rework_count` máximo 2 por task; máximo 2 rodadas na revisão de tasks.
- O `CLAUDE.md` do app prevalece sobre o conhecimento genérico do plugin; o design system do app
  prevalece sobre heurísticas genéricas de UX.
- Commits deste repo: o executor **não** commita. Ao fim de cada task, para e informa o que mudou.

**Nota sobre o conteúdo:** os arquivos deste plugin são prompts e templates, não código. Cada task
lista os requisitos obrigatórios de conteúdo; o teste é o validador estrutural (Task 1) mais
`claude plugin validate`.

---

### Task 1: Manifesto, marketplace e validador

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `scripts/check.sh`
- Create: `.gitignore`

**Interfaces:**
- Produces: `scripts/check.sh` (exit 0 = estrutura válida), usado ao fim de todas as tasks.

- [ ] **Step 1: Escrever o validador** `scripts/check.sh` (bash, `set -euo pipefail`) que falha com
  mensagem clara se:
  - faltar algum arquivo da estrutura da spec (6 agentes, 6 SKILL.md, 10 templates, README);
  - algum `agents/*.md` não tiver frontmatter com `name`, `description`, `tools`, `model`;
  - `tech-lead.md`, `senior-reviewer.md` ou `mobile-designer.md` listarem `Edit` em `tools`;
  - algum `skills/*/SKILL.md` não tiver `name` e `description`;
  - qualquer arquivo fora de `docs/` e `scripts/` contiver `git commit`, `git push` ou
    `gh issue close` numa linha sem `nunca`/`Nunca`/`não`/`Não`;
  - algum template de parecer (`TASK_REVIEW`, `CODE_REVIEW`, `UI_REVIEW`, `ACCEPTANCE`) não
    contiver `APPROVED | CHANGES_REQUESTED`;
  - `TASK.md` não contiver as 8 chaves do frontmatter.
  Ao final roda `claude plugin validate .`.
- [ ] **Step 2: Rodar e ver falhar** — `bash scripts/check.sh` → FAIL listando arquivos ausentes.
- [ ] **Step 3: Criar** `plugin.json` (`name: mobile-squad`, `version: 0.1.0`, descrição, autor
  Vitor Walcker) e `marketplace.json` (`name: mobile-squad`, `owner`, um plugin com
  `source: "./"`). `.gitignore` com `.DS_Store`.
- [ ] **Step 4: Rodar** — FAIL só pelos arquivos das próximas tasks. Parar e informar.

### Task 2: Skill `delivery-artifacts` e templates

**Files:**
- Create: `skills/delivery-artifacts/SKILL.md`
- Create: `skills/delivery-artifacts/templates/{PROJECT_CONTEXT,PRD,UX_SPEC,TASK,TASK_REVIEW,TEST_PLAN,CODE_REVIEW,UI_REVIEW,ACCEPTANCE,DELIVERY_REPORT}.md`

**Interfaces:**
- Produces: caminhos e formato dos documentos que todos os agentes e `/deliver` usam:
  `docs/delivery/PROJECT_CONTEXT.md`, `docs/delivery/<slug>/{PRD.md,UX_SPEC.md}`,
  `docs/delivery/<slug>/tasks/T-NNN-<slug>.md`, `docs/delivery/<slug>/reviews/TASK_REVIEW.md`,
  `docs/delivery/<slug>/reviews/T-NNN/{TEST_PLAN.md,CODE_REVIEW-rN.md,UI_REVIEW-rN.md,ACCEPTANCE.md}`,
  `docs/delivery/<slug>/DELIVERY_REPORT.md`.

- [ ] **Step 1: SKILL.md** — árvore de pastas, máquina de estados (quem move cada transição),
  regra de veredito/severidade, "um documento por etapa, nunca sobrescrever parecer de rodada
  anterior", onde estão os templates (`${CLAUDE_PLUGIN_ROOT}/skills/delivery-artifacts/templates/`),
  contrato `## Resultado` que todo agente devolve (ver Task 5).
- [ ] **Step 2: Templates**, cada um com seções fixas:
  - `PROJECT_CONTEXT`: app, stack e versões, módulos, alvos, comandos (`build`, `test`, `lint`,
    `ios-compile`), design system (onde ficam tokens/componentes), strings/i18n, DI, repo GitHub.
  - `PRD`: problema, usuário, evidência, objetivo e métrica, escopo, fora de escopo, fluxos,
    requisitos não funcionais (a11y, i18n, offline, performance), riscos, perguntas em aberto,
    status de aprovação.
  - `UX_SPEC`: fluxos (passo a passo), inventário de telas; por tela: objetivo, layout em blocos,
    componentes do DS usados, estados (loading, vazio, erro, sucesso, offline), interações e
    gestos, textos pt/en, a11y (ordem de leitura, rótulos, alvos, live regions), variações
    (tela pequena/grande, dark mode, fonte 200%, teclado aberto), diferenças Android/iOS;
    componentes novos propostos; status de aprovação.
  - `TASK`: frontmatter com as 8 chaves; contexto, telas/estados do UX_SPEC cobertos, entrega
    esperada, critérios Given/When/Then, fora de escopo, orientação técnica (TL), histórico de status.
  - `TASK_REVIEW`, `CODE_REVIEW`, `UI_REVIEW`, `ACCEPTANCE`: veredito `APPROVED | CHANGES_REQUESTED`,
    tabela de apontamentos (id, severidade, arquivo:linha, problema, sugestão), resumo.
    `CODE_REVIEW` com seções separadas para código e testes. `UI_REVIEW` com checklist por tela
    (fidelidade ao UX_SPEC, tokens do DS, estados, a11y, i18n, variações). `ACCEPTANCE` com
    checklist de critérios e saída dos comandos de verificação.
  - `TEST_PLAN`: matriz critério → casos → tipo (unit/UI) → arquivo de teste; casos de borda;
    resultado da execução; bugs encontrados para o Dev.
  - `DELIVERY_REPORT`: tabela de tasks, arquivos por task, verificação, minors pendentes, achados
    fora de escopo, sugestão de mensagem de commit e corpo de PR com `Closes #N`, aviso de que nada
    foi commitado.
- [ ] **Step 3:** `bash scripts/check.sh` → falhas restantes só de agentes/outras skills. Parar.

### Task 3: Skills de conhecimento

**Files:** Create: `skills/kmp-standards/SKILL.md`, `skills/mobile-ux-standards/SKILL.md`

- [ ] **Step 1: `kmp-standards`** (≤ ~200 linhas): `commonMain` portável (sem `java.*`, `Math`,
  `System.currentTimeMillis`; `kotlin.math`, `kotlinx.datetime`; `expect/actual` só sem lib
  multiplataforma), arquitetura (UDF, estado imutável em `StateFlow`, ViewModel multiplataforma,
  UseCase/Repository), coroutines (escopos, dispatchers injetáveis, cancelamento, não engolir
  `CancellationException`), Compose (state hoisting, `remember`/`derivedStateOf`, efeitos, listas
  com `key`, estabilidade), DI Koin, testes (`kotlin.test`, `runTest`, `StandardTestDispatcher`,
  Turbine, fakes em vez de mocks, nomes de teste por comportamento), a11y técnica, i18n,
  verificação iOS. Primeira linha do corpo: o `CLAUDE.md` do app prevalece.
- [ ] **Step 2: `mobile-ux-standards`** (≤ ~200 linhas): Material 3 e iOS HIG e quando divergir em
  CMP; navegação (back, bottom bar, modais, sheets); os cinco estados de toda tela; feedback de
  ação; formulários e teclado (IME actions, foco, validação inline); gestos com alternativa
  acessível; safe areas e edge-to-edge; tamanhos de tela e orientação; dark mode; fonte até 200%;
  alvo 48dp/44pt; contraste 4,5:1 texto e 3:1 contornos; leitor de tela (ordem, agrupamento,
  rótulos); microcopy clara e traduzível; reduzir movimento. Primeira linha: o design system do
  app é a fonte da verdade.
- [ ] **Step 3:** `bash scripts/check.sh`. Parar.

### Task 4: Agentes

**Files:** Create: `agents/{product-manager,mobile-designer,tech-lead,kmp-developer,qa-engineer,senior-reviewer}.md`

**Interfaces:**
- Consumes: templates e caminhos da Task 2; skills da Task 3 pelo campo `skills` do frontmatter
  (`kmp-standards` para Dev, QA, TL, Revisor; `mobile-ux-standards` para Designer, Dev, Revisor).
- Produces: contrato de retorno de cada agente para o orquestrador — última seção da resposta:

  ```
  ## Resultado
  status: <novo status da task ou do documento>
  documento: <caminho do documento escrito>
  veredito: APPROVED | CHANGES_REQUESTED   (só revisores)
  perguntas:                                (só PM/Designer quando precisam do usuário)
    - <pergunta>
  ```

- [ ] **Step 1:** Cada agente com frontmatter (`name`, `description` dizendo quando usar, `tools`,
  `model`, `skills` quando aplicável) e corpo: missão, entradas (arquivos lidos primeiro), processo
  em passos, o que não faz, formato de saída (template + bloco `## Resultado`). Ferramentas e
  modelos exatamente como na tabela da spec. Requisitos específicos:
  - PM: modo `discovery` (até 3 perguntas por rodada, nunca inventa resposta do usuário) e modo
    `tasks` (fatias verticais, cada task entregável e testável sozinha, ≤ ~1 dia, marca `ui`,
    referencia UX_SPEC); cria issue com `gh issue create` só quando o orquestrador pedir.
  - Designer: modo `ux-spec` (lê PRD e o design system real do app antes de propor; componente
    fora do DS vai em "componentes novos propostos") e modo `ui-review` (lê diff da task e as
    telas; roda testes de screenshot/preview se o `PROJECT_CONTEXT` tiver comando para isso).
  - TL: modo `task-review` e modo `acceptance`; no aceite roda os comandos de `PROJECT_CONTEXT.md`
    e considera `CODE_REVIEW` e `UI_REVIEW`.
  - Dev: implementa só a task recebida seguindo UX_SPEC e orientação do TL; roda `build` e testes
    existentes antes de devolver; em retrabalho, responde a cada apontamento por id.
  - QA: deriva casos dos critérios; roda os testes; falha por bug de produção vira apontamento.
  - Revisor: lê `git diff` da task; revisa código e testes em seções separadas; não aprova com
    `blocker`/`major` aberto.
- [ ] **Step 2:** `bash scripts/check.sh`. Parar.

### Task 5: Skills de orquestração

**Files:** Create: `skills/squad-init/SKILL.md`, `skills/discover/SKILL.md`, `skills/deliver/SKILL.md`

**Interfaces:**
- Consumes: agentes (Task 4) como `mobile-squad:<agente>`; bloco `## Resultado`.

- [ ] **Step 1: `squad-init`** — lê `CLAUDE.md`, `settings.gradle.kts`, `gradle/libs.versions.toml`,
  workflows de CI, módulo de design system; preenche `PROJECT_CONTEXT.md`; mostra ao usuário e só
  salva após ok.
- [ ] **Step 2: `discover`** — argumento: ideia. Garante contexto; loop PM ↔ usuário (perguntas uma
  por vez, máx. ~8); PM escreve PRD; usuário aprova. Se há UI: Designer escreve UX_SPEC (mesmo loop
  de perguntas); usuário aprova. Nunca começa código.
- [ ] **Step 3: `deliver`** — argumentos `<slug> [--gate] [--no-issues] [--only T-NNN]`.
  Pré-checagens (PRD e, se houver UI, UX_SPEC aprovados; `build` verde; `gh auth status` + remote).
  Passos 1–6 da spec, incluindo Revisor + Designer em paralelo para `ui: true`; contagem de
  rodadas; atualização do frontmatter e labels `squad:<status>`; comentário por etapa na issue;
  parada em `blocked`; retomada pelo status gravado; relatório final. Regra em destaque: nunca
  commitar, nunca dar push, nunca fechar issue.
- [ ] **Step 4:** `bash scripts/check.sh`. Parar.

### Task 6: README e validação final

**Files:** Create: `README.md`

- [ ] **Step 1:** README: o que é, fluxo em texto, instalação
  (`claude plugin marketplace add ~/Developer/mobile-squad`,
  `claude plugin install mobile-squad@mobile-squad`), uso dos 3 comandos, estrutura de
  `docs/delivery/`, como customizar por app.
- [ ] **Step 2:** `bash scripts/check.sh` → PASS, incluindo `claude plugin validate .`.
- [ ] **Step 3:** Parar. Informar arquivos criados, sugerir ensaio no `mobile-match` e mensagem de
  commit. Não commitar.
