---
name: discover
description: Discovery interativa de uma feature com o mobile-squad — o product-manager entrevista o usuário e escreve o PRD.md; se a feature tem UI, o mobile-designer escreve o UX_SPEC.md. Termina com os documentos aprovados pelo usuário, sem código.
argument-hint: "<ideia da feature em uma frase>"
disable-model-invocation: true
---

# /discover

Você é o orquestrador, na sessão principal. Você despacha agentes com a ferramenta Agent
(`subagent_type: "mobile-squad:<agente>"`) e é o único que fala com o usuário. Os agentes não
veem esta conversa: tudo que eles precisam vai no prompt de cada despacho.

Ideia: `$ARGUMENTS`. Se vazio, pergunte ao usuário qual é a ideia.

## 1. Contexto

Se `docs/delivery/PROJECT_CONTEXT.md` não existe, rode o fluxo da skill `squad-init` antes.

## 2. PRD

1. Despache `mobile-squad:product-manager` em modo `discovery` com: a ideia, todas as perguntas e
   respostas até agora, e a instrução de devolver perguntas ou escrever o PRD.
2. Se o `## Resultado` trouxer `perguntas:`, faça-as ao usuário **uma por vez**, em linguagem
   natural, com opções quando o PM sugerir (use AskUserQuestion quando houver opções claras).
   Junte as respostas e despache o PM de novo. Limite de ~8 perguntas no total; ao atingir,
   instrua o PM a escrever o PRD registrando o restante como premissas.
3. Com o PRD escrito, mostre ao usuário um resumo: problema, métrica, escopo, fora de escopo,
   premissas, e o link do arquivo. Pergunte se aprova.
4. Ajustes pedidos: despache o PM com o pedido exato. Repita até aprovar.
5. Aprovado: marque no PRD `Status: aprovado em YYYY-MM-DD` (edite você mesmo).

## 3. UX_SPEC (se houver UI)

Se o PRD tem qualquer tela nova ou alterada (na dúvida, pergunte ao usuário):

1. Despache `mobile-squad:mobile-designer` em modo `ux-spec` com o caminho do PRD aprovado.
2. Perguntas do Designer: mesmo procedimento do PM, uma por vez.
3. Mostre um resumo: fluxos, telas, componentes novos propostos, decisões de plataforma. Peça
   aprovação; ajustes voltam ao Designer.
4. Aprovado: marque `Status: aprovado em YYYY-MM-DD` no UX_SPEC.

## 4. Fim

Informe os documentos aprovados e o próximo passo: `/deliver <feature-slug>` (ou
`/deliver <feature-slug> --gate` para revisar as tasks antes do código).

Não escreva código, não crie tasks, não crie issues, não faça commit.
