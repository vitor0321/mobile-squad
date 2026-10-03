---
name: kmp-standards
description: Padrões técnicos de Kotlin Multiplatform e Compose Multiplatform usados pelo squad — commonMain portável, arquitetura UDF, coroutines/Flow, Compose, Koin, testes em commonTest, acessibilidade técnica e verificação iOS. Use ao implementar, testar ou revisar código KMP/CMP.
---

# Padrões KMP / CMP

**O `CLAUDE.md` do app e o `docs/delivery/PROJECT_CONTEXT.md` prevalecem sobre este arquivo.** Aqui
está só o que costuma dar errado em KMP/CMP quando ninguém avisa.

## commonMain portável

- Proibido em `commonMain`: `java.*`, `javax.*`, `android.*`, `Math.*`, `System.currentTimeMillis()`,
  `String.format`, `synchronized`, `@Volatile` de JVM, `Thread`.
- Use: `kotlin.math`, `kotlinx.datetime` (`Clock.System.now()` injetado como `Clock`),
  `kotlinx.coroutines` + `Mutex`, `kotlinx.serialization`, `kotlinx.collections.immutable`.
- `expect/actual` só quando não existe lib multiplataforma. Prefira `interface` em `commonMain` +
  implementação por plataforma injetada via DI: é testável com fake.
- Recursos (strings, imagens, fontes) pelo mecanismo do app (Compose Resources, Lyricist, moko).
- Toda task que toca `commonMain` roda o comando `ios-compile` do `PROJECT_CONTEXT`.

## Arquitetura

- Fluxo unidirecional: UI → evento → ViewModel → UseCase/Repository → estado → UI.
- Estado de tela: uma `data class` imutável exposta como `StateFlow<UiState>`; listas como
  `ImmutableList`. Efeitos únicos (navegar, snackbar) em `Channel`/`SharedFlow` separado, nunca
  flag booleana no estado que alguém esquece de resetar.
- ViewModel: `androidx.lifecycle.ViewModel` multiplataforma, `viewModelScope`. Sem referência a
  `Context`, `Composable` ou tipos de plataforma.
- UseCase só quando há regra de negócio ou composição de repositórios; não crie UseCase que só
  repassa chamada.
- Repository devolve tipo de domínio, nunca DTO. Erro mapeado para tipo de domínio
  (`Result`/sealed), nunca `Exception` crua chegando à UI.
- Nunca mostre ao usuário `exception.message`, id de documento ou nome de enum.

## Coroutines e Flow

- Dispatchers injetados (`CoroutineDispatcher` no construtor), nunca `Dispatchers.IO` fixo em
  código testável. `Dispatchers.IO` não existe em `commonMain` antigo; use o que o app definir.
- Nunca engula `CancellationException`: `catch (e: Exception)` em `suspend` precisa relançá-la
  (ou use `runCatching` com cuidado e `ensureActive()`).
- `stateIn(scope, SharingStarted.WhileSubscribed(5_000), initial)` para estado derivado de Flow.
- Sem `GlobalScope`, sem `runBlocking` fora de teste.
- Operações repetidas pelo usuário (busca, clique duplo): `debounce`, `distinctUntilChanged`,
  `flatMapLatest`, ou guarda de "já carregando".

## Compose

- State hoisting: tela `XRoute` (pega ViewModel, coleta estado) + `XScreen(state, onEvent)` pura,
  sem ViewModel, com preview.
- `collectAsStateWithLifecycle()` para coletar estado.
- `remember` com chaves corretas; `derivedStateOf` para cálculo sobre estado que muda muito.
- Efeitos: `LaunchedEffect(key)` com chave que representa quando reexecutar; nunca
  `LaunchedEffect(Unit)` para algo que depende de parâmetro.
- `LazyColumn`/`LazyRow` sempre com `key` estável e `contentType` quando há tipos mistos.
- Lambdas e classes passadas a composables devem ser estáveis; evite `List` mutável e objetos
  recriados a cada recomposição.
- `Modifier` como primeiro parâmetro opcional de todo composable público.
- Cores, espaçamentos, raios e tipografia vêm do design system do app, nunca literais.

## DI (Koin)

- Um módulo Koin por feature; `viewModelOf(::XViewModel)`, `singleOf`, `factoryOf`.
- Dependência de plataforma declarada em módulo `expect`/por plataforma e injetada por interface.
- Novo binding registrado no agregador de módulos do app; verifique que o app sobe.

## Testes

- `commonTest` com `kotlin.test` (`@Test`, `assertEquals`), `kotlinx-coroutines-test` (`runTest`,
  `StandardTestDispatcher`/`UnconfinedTestDispatcher`), Turbine (`flow.test { awaitItem() }`).
- `Dispatchers.setMain(testDispatcher)` em `@BeforeTest` e `resetMain()` em `@AfterTest` quando o
  ViewModel usa `viewModelScope`.
- Fakes escritos à mão (`FakeXRepository` implementando a interface) em vez de mocks: funcionam em
  todos os alvos e deixam o teste legível.
- Nome do teste descreve comportamento: `` `mostra erro quando o repositório falha` ``.
- Um comportamento por teste; arrange/act/assert visíveis.
- Teste o que o usuário ou o chamador observa (estado emitido, valor retornado, chamada ao
  repositório), não detalhes internos.
- Tempo: injete `Clock` e use `advanceTimeBy`/`advanceUntilIdle`, nunca `delay` real.
- UI: `runComposeUiTest { setContent { XScreen(state, onEvent) } }` testando a tela pura com
  estados fixos; busque por texto/`contentDescription`/`testTag`, não por posição.
- Screenshot tests quando o app tiver (o `PROJECT_CONTEXT` diz o comando).

## Acessibilidade técnica

- Alvo de toque ≥ 48dp (`Modifier.minimumInteractiveComponentSize()` ou tamanho explícito).
- Container com texto usa `defaultMinSize`/`heightIn(min = ...)`, nunca `height()` fixo.
- `contentDescription` em ícone informativo; `null` só quando há texto equivalente ao lado.
- `Modifier.semantics { liveRegion = LiveRegionMode.Polite }` em mensagem que aparece após ação.
- `mergeDescendants = true` para agrupar item de lista lido como uma unidade.
- `Role` correto em elementos clicáveis customizados.

## i18n

- Nenhum literal visível no código de UI; tudo pelo mecanismo de strings do app.
- Texto novo entra em todos os idiomas do app na mesma mudança.
- Plural e formatação de número/data pela API de i18n, nunca concatenação.

## Antes de devolver

1. `build` e `test` do `PROJECT_CONTEXT` verdes.
2. `lint` sem problema novo.
3. `ios-compile` se tocou `commonMain`.
4. Diff só com o que a task pede.
