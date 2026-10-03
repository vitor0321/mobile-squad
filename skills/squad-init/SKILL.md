---
name: squad-init
description: Prepara um app KMP/CMP para o mobile-squad gerando docs/delivery/PROJECT_CONTEXT.md (stack, módulos, comandos de verificação, design system, strings, GitHub). Use na primeira vez que o squad for usado num app ou quando o contexto estiver desatualizado.
argument-hint: "[--refresh]"
disable-model-invocation: true
---

# /squad-init

Gera o `docs/delivery/PROJECT_CONTEXT.md` que todos os agentes do squad leem primeiro. Roda na
sessão principal; não despacha agentes.

## Passos

1. Se `docs/delivery/PROJECT_CONTEXT.md` já existe e não veio `--refresh`, mostre o arquivo e
   pergunte se quer atualizar. Se não, pare.
2. Colete, lendo arquivos (não suponha):
   - `CLAUDE.md` / `AGENTS.md` da raiz: regras e convenções;
   - `settings.gradle.kts`: módulos;
   - `gradle/libs.versions.toml`: versões de Kotlin, CMP, Koin, Ktor, Room/SQLDelight,
     navegação, bibliotecas de teste;
   - `build.gradle.kts` dos módulos: alvos KMP, plugins (detekt, ktlint, kover, screenshot);
   - `.github/workflows/*`: comandos que o CI roda (fonte mais confiável para os comandos);
   - módulo de design system (procure `Theme`, `Tokens`, `Palette`, `designsystem`, `ds`);
   - mecanismo de strings (Compose Resources `composeResources/values*/strings.xml`, Lyricist,
     moko-resources);
   - `git remote -v`: repositório GitHub.
3. Monte os comandos de verificação com os nomes `build`, `test`, `lint`, `ios-compile` e
   `ui-snapshot` (este só se houver). Prefira os comandos que o CI usa. Para `ios-compile`, use
   `compileKotlinIosSimulatorArm64` dos módulos com alvo iOS.
4. Preencha o template `${CLAUDE_PLUGIN_ROOT}/skills/delivery-artifacts/templates/PROJECT_CONTEXT.md`.
   Em "Convenções", resuma as regras do `CLAUDE.md` que afetam código, UI e testes, com a nota de
   que o `CLAUDE.md` é a fonte da verdade.
5. Mostre o resultado ao usuário e pergunte se está correto. Só grave depois do ok. Ajuste o que ele
   corrigir.
6. Sugira rodar `build` uma vez para confirmar que os comandos funcionam; rode se ele aceitar.

Não faça commit.
