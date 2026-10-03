---
name: mobile-ux-standards
description: Heurísticas de UX para apps mobile Android/iOS em Compose Multiplatform — Material 3 e iOS HIG, navegação, os cinco estados de tela, feedback, formulários e teclado, gestos, safe areas, tamanhos de tela, dark mode, escala de fonte, acessibilidade e microcopy. Use ao especificar, implementar ou revisar UI.
---

# UX mobile

**O design system do app é a fonte da verdade.** Quando ele define um componente, token ou padrão,
use-o. Estas heurísticas servem para o que ele não cobre e para revisar se a tela funciona.

## Plataforma

- Base visual: Material 3 (o CMP usa Material). Onde o usuário de iOS espera outro comportamento,
  especifique a diferença em vez de ignorar:
  - voltar: gesto de borda no iOS, botão/gesto do sistema no Android;
  - sheets e diálogos: iOS prefere sheet, Android aceita diálogo;
  - seletores de data/hora, compartilhamento, permissões: use o nativo da plataforma;
  - haptics e rolagem com bounce seguem o sistema.
- Uma mesma tela pode ter o mesmo layout nas duas plataformas; diferencie só onde a expectativa do
  usuário muda.

## Navegação

- Até 5 destinos de topo: bottom bar. Mais que isso: repense a hierarquia.
- Voltar nunca perde dado digitado sem confirmação.
- Modal/sheet para tarefa curta e focada; tela cheia para fluxo com vários passos.
- Deep link abre a tela certa com o voltar fazendo sentido.

## Os cinco estados

Toda tela que carrega dado especifica **carregando, vazio, erro, sucesso e offline**:

- Carregando: skeleton quando o layout é previsível, indicador quando não; nunca tela branca.
- Vazio: explica por que está vazio e oferece a próxima ação.
- Erro: diz o que aconteceu em linguagem do usuário e como resolver; ação "Tentar de novo" quando
  faz sentido. Nunca código de erro ou mensagem técnica.
- Offline: mostra o que tem em cache e deixa claro que não está atualizado.
- Sucesso parcial (lista carregou, imagem não) também é estado.

## Feedback de ação

- Toda ação tem resposta em até 100ms (visual, haptic ou estado de loading no próprio botão).
- Ação longa: loading no componente que disparou, não bloqueio da tela inteira.
- Atualização otimista quando a falha é rara e reversível, com desfazer.
- Ação destrutiva: confirmação ou desfazer, não os dois.
- Mensagem pós-ação (snackbar, erro de formulário) é live region.

## Formulários e teclado

- Tipo de teclado certo (e-mail, número, telefone) e `ImeAction` (Próximo, Concluir, Buscar).
- Ordem de foco segue a ordem visual; "Próximo" leva ao campo seguinte.
- Validação inline ao sair do campo, não a cada tecla; erro abaixo do campo, com texto.
- Botão principal visível com teclado aberto (rolagem ou `imePadding`).
- Nunca apague o que o usuário digitou por causa de um erro.

## Gestos

- Todo gesto (swipe para apagar, long press, arrastar) tem alternativa visível e acessível.
- Não conflite com gestos do sistema (bordas, barra inferior).

## Layout

- Edge-to-edge com safe areas e insets respeitados (status bar, notch, barra de gestos, teclado).
- Funciona de 320dp de largura até tablet; em telas largas, limite a largura do conteúdo ou use
  layout adaptativo.
- Rotação não perde estado.
- Conteúdo principal ao alcance do polegar; ação primária embaixo quando a tela é de ação.

## Dark mode

- Cores só por token do tema; verifique contraste nos dois temas.
- Imagem/ilustração com fundo transparente ou versão para cada tema.

## Texto e escala de fonte

- Tudo legível com fonte a 200%: nada de altura fixa em container de texto, rótulos de botão
  aceitam duas linhas, sem truncar informação essencial.
- Tamanho mínimo 12sp.
- Hierarquia por tipografia do tema, não por tamanhos soltos.

## Acessibilidade

- Alvo de toque ≥ 48dp (Android) / 44pt (iOS).
- Contraste: 4,5:1 para texto, 3:1 para texto grande e para contornos que identificam um
  componente (borda de campo, indicador de seleção, ícone sem texto).
- Cor nunca é o único sinal (erro também tem ícone/texto).
- Leitor de tela: ordem de leitura lógica, item de lista lido como uma unidade, rótulo diz a
  função ("Apagar partida", não "ícone lixeira"), estado anunciado (selecionado, expandido).
- Respeite "reduzir movimento": animação decorativa desliga, transição vira fade.

## Microcopy

- Verbo no botão ("Salvar partida", não "OK").
- Frases curtas, sem jargão técnico, tom do app.
- Texto traduzível: sem concatenar pedaços, com espaço para o idioma mais longo (+30%).
- Mesmo nome para a mesma coisa em todo o app.
