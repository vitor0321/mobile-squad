---
name: deliver
description: Pipeline automático do mobile-squad para uma feature com PRD aprovado — PM cria tasks, Tech Lead revisa, issues no GitHub, e para cada task Dev implementa, QA testa, Revisor Sênior (e Designer se há UI) revisam, gate de verificação aceita (Tech Lead só em tasks de risco alto); retrabalho incremental com limite e relatório final. Nunca faz commit.
argument-hint: "<feature-slug> [--gate] [--no-issues] [--only T-NNN]"
disable-model-invocation: true
---

# /deliver

Você é o orquestrador, na sessão principal. Despacha agentes com a ferramenta Agent
(`subagent_type: "mobile-squad:<agente>"`), lê o `## Resultado` de cada um, move os status e
decide o próximo passo. Os agentes não veem esta conversa: cada despacho leva modo, rodada,
caminhos e o que mudou desde a última vez, em poucas linhas. Não cole conteúdo de documento no
prompt; passe o caminho.

> **Regra inegociável:** nunca rode `git commit`, `git push`, `git stash` nem feche issue. O
> pipeline termina com mudanças no working tree e um relatório. Commit só quando o usuário pedir.

Argumentos: `$ARGUMENTS`. A skill `delivery-artifacts` é o contrato (status, ids, `## Resultado`).

Atalhos usados abaixo:
- `VERIFY` = `bash ${CLAUDE_PLUGIN_ROOT}/scripts/verify.sh`
- `ISSUES` = `bash ${CLAUDE_PLUGIN_ROOT}/scripts/issues.sh`

## Economia de contexto

- Não leia documentos inteiros para decidir: o `## Resultado` traz status, veredito, ids e
  arquivos. Para conferir algo, leia só o trecho (`grep`, frontmatter, uma seção).
- Não rode Gradle direto; só `VERIFY`.
- Modelo por despacho (parâmetro `model` da ferramenta Agent), quando a tabela pede; nos demais,
  vale o do agente:

| Despacho | `model` |
|---|---|
| product-manager `tasks` / `ajuste-tasks` | `sonnet` |
| senior-reviewer rodada 1 com `risk: low`, ou rodada 2+ sem `risk: high` | `sonnet` |
| mobile-designer `ui-review` rodada 2+ | `sonnet` |

## 0. Pré-checagens

1. `docs/delivery/<slug>/PRD.md` existe com `Status: aprovado`. Se a feature tem UI,
   `UX_SPEC.md` também aprovado. Se não: pare e sugira `/discover`.
2. `docs/delivery/PROJECT_CONTEXT.md` e `docs/delivery/verify.conf` existem (senão, rode o fluxo
   `squad-init`).
3. Branch: se estiver na branch padrão (`main`/`master`/`develop`), crie `squad/<slug>` com
   `git switch -c`. Working tree sujo com mudanças que não são do squad: avise e pergunte se segue.
4. `VERIFY build`. Vermelho antes de começar: pare e reporte; não conserte.
5. Issues: sem `--no-issues`, confira `gh auth status` e `git remote -v` com GitHub. Se falhar,
   siga sem issues e anote para o relatório.
6. Crie o marcador `.squad/active` (`mkdir -p .squad && touch .squad/active`). Com ele, o hook do
   plugin bloqueia commit/push/stash/fechar issue. Remova-o no passo 6, também quando o pipeline
   parar.

## 1. Retomada

Se `docs/delivery/<slug>/tasks/` já tem tasks, não recrie: leia os status no frontmatter
(`grep '^status:'`) e continue de onde parou (`accepted` são puladas; `blocked` só com
confirmação do usuário).

## 2. Tasks

1. Despache `product-manager` modo `tasks` com PRD e UX_SPEC.
2. Despache `tech-lead` modo `task-review`, rodada 1.
3. `CHANGES_REQUESTED`: `product-manager` modo `ajuste-tasks` com o TASK_REVIEW, depois
   `tech-lead` rodada 2. Máximo 2 rodadas; na terceira reprovação, pare e mostre os apontamentos.
4. `APPROVED`: mude todas as tasks para `ready` (frontmatter + histórico).

## 3. Issues

Sem `--no-issues` e com `gh` ok: `ISSUES create <slug>`. A cada mudança de status:
`ISSUES status <task.md> <novo-status>`. Em `changes_requested`, `accepted` e `blocked`, passe
também uma nota de 1 a 3 linhas com o veredito e o caminho do documento.

## 4. Gate

Com `--gate`: mostre ao usuário a lista de tasks (id, título, ui, risk, depends_on, resumo da
orientação técnica) e pare até ele dizer para seguir. Ajustes pedidos voltam ao PM/TL.

## 5. Loop por task

Ordem: topológica por `depends_on`, depois por id. Com `--only T-NNN`, só essa (e avise se as
dependências não estão `accepted`). Uma task por vez; não paralelize tasks.

**a. Base do diff.** Antes do Dev, guarde `git status --porcelain` em `.squad/T-NNN.base`. Os
arquivos da task são os que aparecem ou mudam depois disso.

**b. Dev.** Status `in_progress`. Despache `kmp-developer` com o caminho da task. `blocked`:
registre e pare o pipeline, mostrando o motivo ao usuário.

**c. QA.** Despache `qa-engineer` com a task e os `arquivos:` do Dev. Bugs `QA` de produção → (f).

**d. Revisões** (status `tested`). Na rodada 1, despache **na mesma mensagem, em paralelo**:
- `senior-reviewer`, rodada N, com task, TEST_PLAN e arquivos da task;
- se `ui: true`: `mobile-designer` modo `ui-review`, rodada N, com task, UX_SPEC e arquivos de UI.

Ambos `APPROVED` → status `reviewed`. Qualquer `CHANGES_REQUESTED` → (f).

**e. Gate de aceite.**
1. `VERIFY --auto`. Algum `FAIL` → registre na rodada do `ACCEPTANCE.md` um apontamento
   `VFN-01` (`blocker`) com o comando e o trecho do erro, e vá para (f).
2. Confira na seção "Critérios de aceite × evidência" do último CODE_REVIEW que todo critério
   tem implementação e teste. Lacuna → volte ao `senior-reviewer` (é falha do parecer).
3. `risk: high`: despache `tech-lead` modo `acceptance`, rodada N, com a saída do `VERIFY`.
   `CHANGES_REQUESTED` → (f).
4. Caso contrário, acrescente a rodada no `ACCEPTANCE.md` (template, `Por: orquestrador`): saída
   do `VERIFY`, vereditos dos pareceres, minors aceitos. Status `accepted`, linha no histórico.

**f. Retrabalho.** Status `changes_requested`, `rework_count + 1`.
- Se `rework_count` passaria de 2: status `blocked`, pare o pipeline e mostre ao usuário os
  apontamentos que continuam abertos.
- Roteie por prefixo (`delivery-artifacts`): `CR`, `UI`, `QA`, `VF`, `AC` → `kmp-developer`;
  `CT` → `qa-engineer`. Só `CT` abertos: pule o Dev. Passe ids e caminhos, não o conteúdo.
- Depois do Dev, `qa-engineer` só se havia `QA` ou `CT`, ou se o Dev disse que um teste está
  errado.
- Revisão da rodada N+1, **incremental**, com os `arquivos:` do retrabalho e os ids abertos:
  - `senior-reviewer` se ele pediu mudanças ou se o retrabalho tocou código de produção;
  - `mobile-designer` se ele pediu mudanças ou se o retrabalho tocou arquivos de UI que ele revisou.
  Quem aprovou e não foi afetado mantém o `APPROVED` anterior.
- Siga para (e).

**Documento fora do template** ou `## Resultado` ausente: redespache o mesmo agente uma vez
pedindo a correção. Falhou de novo: task `blocked`.

## 6. Relatório

Ao terminar (todas `accepted`, ou pipeline parado):

1. `VERIFY --auto` (verificação final da feature inteira).
2. Escreva `docs/delivery/<slug>/DELIVERY_REPORT.md` a partir do template: tasks, arquivos por
   task, verificação, minors pendentes, tasks bloqueadas, achados fora de escopo, sugestão de
   commit e de PR com `Closes #N`.
3. Remova `.squad/active`.
4. Mostre ao usuário um resumo curto e o link do relatório. Diga explicitamente que nada foi
   commitado e que o commit fica a critério dele.
