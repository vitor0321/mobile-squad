---
name: deliver
description: Pipeline automático do mobile-squad para uma feature com PRD aprovado — PM cria tasks, Tech Lead revisa, issues no GitHub, e para cada task Dev implementa, QA testa, Revisor Sênior (e Designer se há UI) revisam, Tech Lead aceita; retrabalho com limite e relatório final. Nunca faz commit.
argument-hint: "<feature-slug> [--gate] [--no-issues] [--only T-NNN]"
disable-model-invocation: true
---

# /deliver

Você é o orquestrador, na sessão principal. Despacha agentes com a ferramenta Agent
(`subagent_type: "mobile-squad:<agente>"`), lê o `## Resultado` de cada um, move os status e
decide o próximo passo. Os agentes não veem esta conversa: cada despacho leva o modo, os caminhos
dos documentos e o que mudou desde a última vez.

> **Regra inegociável:** nunca rode `git commit`, `git push`, `git stash` nem feche issue. O
> pipeline termina com mudanças no working tree e um relatório. Commit só quando o usuário pedir.

Argumentos: `$ARGUMENTS`. Leia a skill `delivery-artifacts` antes de começar.

## 0. Pré-checagens

1. `docs/delivery/<slug>/PRD.md` existe com `Status: aprovado`. Se a feature tem UI,
   `UX_SPEC.md` também aprovado. Se não: pare e sugira `/discover`.
2. `docs/delivery/PROJECT_CONTEXT.md` existe (senão, rode o fluxo `squad-init`).
3. Branch: se estiver na branch padrão (`main`/`master`/`develop`), crie `squad/<slug>` com
   `git switch -c`. Working tree sujo com mudanças que não são do squad: avise e pergunte se segue.
4. Rode `build` do `PROJECT_CONTEXT`. Vermelho antes de começar: pare e reporte; não conserte.
5. Issues: sem `--no-issues`, confira `gh auth status` e `git remote -v` com GitHub. Se falhar,
   siga sem issues e anote para o relatório.

## 1. Retomada

Se `docs/delivery/<slug>/tasks/` já tem tasks, não recrie: leia os status e continue de onde
parou (tasks `accepted` são puladas; `blocked` só com confirmação do usuário). Pule para o passo
que corresponde ao estado.

## 2. Tasks

1. Despache `product-manager` modo `tasks` com PRD e UX_SPEC.
2. Despache `tech-lead` modo `task-review`, rodada 1.
3. `CHANGES_REQUESTED`: despache `product-manager` modo `ajuste-tasks` com o TASK_REVIEW, depois
   `tech-lead` rodada 2. Máximo 2 rodadas; na terceira reprovação, pare e mostre os apontamentos
   ao usuário.
4. `APPROVED`: mude todas as tasks para `ready` (frontmatter + histórico).

## 3. Issues

Sem `--no-issues` e com `gh` ok: despache `product-manager` modo `issues` para as tasks sem
`issue`. Depois, a cada mudança de status:

```bash
gh issue edit <n> --remove-label "squad:<anterior>" --add-label "squad:<novo>"
gh issue comment <n> --body "<etapa>: <veredito/resumo em 1-3 linhas> — <caminho do documento>"
```

Crie labels que faltarem com `gh label create "squad:<status>" --force`.

## 4. Gate

Com `--gate`: mostre ao usuário a lista de tasks (id, título, ui, depends_on, resumo da
orientação técnica) e pare até ele dizer para seguir. Ajustes pedidos voltam ao PM/TL.

## 5. Loop por task

Ordem: topológica por `depends_on`, depois por id. Com `--only T-NNN`, só essa (e avise se as
dependências não estão `accepted`). Uma task por vez; não paralelize tasks.

Para cada task:

**a. Base do diff.** Antes do Dev, guarde a lista de arquivos já modificados
(`git status --porcelain`). Os arquivos da task são os que aparecem ou mudam depois. Passe essa
lista a QA, Revisor, Designer e TL.

**b. Dev.** Status `in_progress`. Despache `kmp-developer` com a task. Espere `implemented`.
`blocked`: registre e pare o pipeline, mostrando o motivo ao usuário.

**c. QA.** Despache `qa-engineer` com a task e os arquivos. Se voltar com bugs `QAN-NN` de
produção, vá para (f) com esses bugs como apontamentos.

**d. Revisões** (status `tested`). Despache **na mesma mensagem, em paralelo**:
- `senior-reviewer`, rodada N, com task, TEST_PLAN, arquivos;
- se `ui: true`: `mobile-designer` modo `ui-review`, rodada N, com task, UX_SPEC, arquivos.

Ambos `APPROVED` → status `reviewed`. Qualquer `CHANGES_REQUESTED` → (f).

**e. Aceite.** Despache `tech-lead` modo `acceptance`, rodada N. `APPROVED` → `accepted`, próxima
task. `CHANGES_REQUESTED` → (f).

**f. Retrabalho.** Status `changes_requested`, `rework_count + 1`.
- Se `rework_count` passaria de 2: status `blocked`, pare o pipeline e mostre ao usuário os
  apontamentos que continuam abertos.
- Senão: despache `kmp-developer` com os pareceres/bugs da rodada (caminhos e ids). Apontamentos
  que são só de teste (`CRN-NN` da seção Testes) vão para o `qa-engineer`. Depois volte a (c) e
  siga com rodada N+1.

Após cada etapa, atualize a issue (passo 3) se houver.

**Documento fora do template** ou `## Resultado` ausente: redespache o mesmo agente uma vez
pedindo a correção. Falhou de novo: task `blocked`.

## 6. Relatório

Ao terminar (todas `accepted`, ou pipeline parado):

1. Rode a verificação final do `PROJECT_CONTEXT` (`build`, `test`, `lint`, `ios-compile` se
   algo tocou `commonMain`).
2. Escreva `docs/delivery/<slug>/DELIVERY_REPORT.md` a partir do template: tasks, arquivos por
   task, verificação, minors pendentes, tasks bloqueadas, achados fora de escopo, sugestão de
   commit e de PR com `Closes #N`.
3. Mostre ao usuário um resumo curto e o link do relatório. Diga explicitamente que nada foi
   commitado e que o commit fica a critério dele.
