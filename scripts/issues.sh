#!/usr/bin/env bash
# Issues do GitHub para as tasks do squad, sem gastar um agente nisso.
#
# Uso (na raiz do app):
#   issues.sh create <feature-slug>                 cria issue para cada task sem `issue:` e grava o número
#   issues.sh status <task.md> <novo-status> [nota]  troca a label squad:<status>; comenta se houver nota
#
# Nunca fecha, atribui ou altera issue que não seja do squad.
set -euo pipefail

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$root"

field() { awk -v k="$2" 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f&&index($0,k":")==1{sub(/^[^:]*:[ ]*/,"");print;exit}' "$1"; }

section() {
  awk -v h="## $2" '$0==h{f=1;next} f&&/^## /{exit} f' "$1"
}

set_issue() {
  local tmp
  tmp=$(mktemp)
  awk -v n="$2" 'NR==1&&$0=="---"{f=1;print;next} f&&$0=="---"{f=0} f&&/^issue:/{print "issue: " n;next} {print}' "$1" >"$tmp"
  mv "$tmp" "$1"
}

ensure_label() { gh label create "squad:$1" --force >/dev/null 2>&1 || true; }

create() {
  local slug=$1 dir=docs/delivery/$1/tasks
  [[ -d $dir ]] || { echo "ERRO: $dir não existe"; exit 2; }
  for task in "$dir"/T-*.md; do
    [[ -n $(field "$task" issue) ]] && continue
    local id title status body url
    id=$(field "$task" id)
    title=$(field "$task" title)
    status=$(field "$task" status)
    body=$(mktemp)
    {
      echo "Task do mobile-squad: \`$task\`"
      echo
      echo "## Contexto"
      section "$task" Contexto
      echo "## Critérios de aceite"
      section "$task" "Critérios de aceite"
    } >"$body"
    ensure_label "$status"
    url=$(gh issue create --title "$id: $title" --body-file "$body" --label "squad:$status")
    rm -f "$body"
    set_issue "$task" "${url##*/}"
    echo "$id → #${url##*/}"
  done
}

status() {
  local task=$1 new=$2 note=${3:-} n
  n=$(field "$task" issue)
  [[ -n $n ]] || { echo "SKIP $(field "$task" id) sem issue"; return; }
  ensure_label "$new"
  local current
  current=$(gh issue view "$n" --json labels -q '.labels[].name | select(startswith("squad:"))' || true)
  local args=(--add-label "squad:$new")
  for label in $current; do
    [[ $label == "squad:$new" ]] || args+=(--remove-label "$label")
  done
  gh issue edit "$n" "${args[@]}" >/dev/null
  [[ -z $note ]] || gh issue comment "$n" --body "$note" >/dev/null
  echo "#$n → squad:$new"
}

case ${1:-} in
  create) create "${2:?slug}" ;;
  status) status "${2:?task}" "${3:?status}" "${4:-}" ;;
  *) echo "uso: issues.sh create <slug> | status <task.md> <status> [nota]"; exit 2 ;;
esac
