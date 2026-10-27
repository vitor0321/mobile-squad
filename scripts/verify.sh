#!/usr/bin/env bash
# Roda os comandos de verificação do app e imprime só o resumo.
#
# Uso (na raiz do app):
#   verify.sh --auto              build, test, lint e ios-compile se o working tree toca commonMain
#   verify.sh test                só os nomes pedidos
#   verify.sh --auto ui-snapshot  combinações valem
#
# Comandos vêm de docs/delivery/verify.conf, uma linha por comando: nome=comando.
# Log completo de cada comando em .squad/logs/<nome>.log; na saída só vai PASS/FAIL e, em falha,
# as linhas de erro relevantes.
set -uo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$root"

conf=docs/delivery/verify.conf
logs=.squad/logs
max_lines=${SQUAD_VERIFY_LINES:-40}

if [[ ! -f $conf ]]; then
  echo "ERRO: $conf não existe. Rode /squad-init."
  exit 2
fi

mkdir -p "$logs"
[[ -f .squad/.gitignore ]] || echo '*' >.squad/.gitignore

command_for() {
  awk -v n="$1" 'index($0, n "=") == 1 { print substr($0, length(n) + 2); exit }' "$conf"
}

touches_common_main() {
  { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard; } |
    grep -q '/commonMain/'
}

names=()
for arg in "$@"; do
  if [[ $arg == --auto ]]; then
    names+=(build test lint)
    touches_common_main && names+=(ios-compile)
  else
    names+=("$arg")
  fi
done
((${#names[@]})) || names=(build test lint)

seen=" "
failed=0
for name in "${names[@]}"; do
  [[ $seen == *" $name "* ]] && continue
  seen+="$name "

  cmd=$(command_for "$name")
  if [[ -z $cmd ]]; then
    echo "SKIP $name (não configurado em $conf)"
    continue
  fi

  log=$logs/$name.log
  start=$SECONDS
  if bash -c "$cmd" >"$log" 2>&1; then
    echo "PASS $name ($((SECONDS - start))s)"
    continue
  fi

  failed=1
  echo "FAIL $name ($((SECONDS - start))s) — log completo: $log"
  excerpt=$(grep -E '^e: |^w: .*error|error:|FAILED|What went wrong|Exception|AssertionError|expected:|Expected|Unresolved reference|\.kt:[0-9]+' "$log" |
    grep -vE '^\s*at (java|kotlin|org\.junit|org\.gradle|jdk)\.' |
    awk '!seen[$0]++' | head -n "$max_lines")
  [[ -n $excerpt ]] || excerpt=$(tail -n "$max_lines" "$log")
  sed 's/^/  | /' <<<"$excerpt"
done

if ((failed)); then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: PASS"
