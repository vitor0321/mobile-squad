#!/usr/bin/env bash
# PreToolUse do mobile-squad. Garante por hook, não por prompt, as regras do squad:
# - agentes do squad (e a sessão principal com .squad/active) não fazem commit, push, stash,
#   descarte de mudanças nem fecham issue;
# - revisores só escrevem em docs/delivery/;
# - o qa-engineer não escreve código de produção.
# Fora do squad (sem agente do squad e sem .squad/active), não faz nada.
set -uo pipefail

input=$(cat)

get() {
  if command -v jq >/dev/null 2>&1; then
    jq -r "$1 // empty" <<<"$input"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys
v=json.load(sys.stdin)
for k in sys.argv[1].lstrip(".").split("."):
    v=v.get(k) if isinstance(v,dict) else None
print("" if v is None else v)' "$1" <<<"$input"
  fi
}

deny() {
  echo "mobile-squad: $1" >&2
  if ((!squad_agent)); then
    echo "(/deliver ativo: .squad/active existe. Se o pipeline não está rodando, apague esse arquivo.)" >&2
  fi
  exit 2
}

tool=$(get .tool_name)
agent=$(get .agent_type)
project=${CLAUDE_PROJECT_DIR:-$(get .cwd)}

squad_agent=0
[[ $agent == mobile-squad:* ]] && squad_agent=1
active=0
[[ -f $project/.squad/active ]] && active=1
((squad_agent || active)) || exit 0

case $tool in
  Bash)
    cmd=$(get .tool_input.command)
    if grep -qE '(^|[^[:alnum:]_-])git[[:space:]]+(commit|push)([[:space:]]|$)' <<<"$cmd"; then
      deny "commit/push são proibidos no squad; o commit fica a critério do usuário."
    fi
    if grep -qE '(^|[^[:alnum:]_-])git[[:space:]]+stash([[:space:]]|$)' <<<"$cmd" &&
      ! grep -qE 'git[[:space:]]+stash[[:space:]]+(list|show)' <<<"$cmd"; then
      deny "git stash esconde mudanças do working tree; proibido no squad."
    fi
    if grep -qE 'git[[:space:]]+(reset[[:space:]]+--hard|clean[[:space:]]+-[[:alpha:]]*f|checkout[[:space:]]+--[[:space:]]|restore([[:space:]]|$))' <<<"$cmd"; then
      deny "comando descarta mudanças do working tree; proibido no squad. Desfaça editando os arquivos."
    fi
    if grep -qE 'gh[[:space:]]+issue[[:space:]]+close' <<<"$cmd"; then
      deny "o squad nunca fecha issue."
    fi
    ;;
  Write | Edit)
    ((squad_agent)) || exit 0
    path=$(get .tool_input.file_path)
    rel=${path#"$project"/}
    case $agent in
      mobile-squad:tech-lead | mobile-squad:senior-reviewer | mobile-squad:mobile-designer)
        [[ $rel == docs/delivery/* ]] ||
          deny "${agent#mobile-squad:} não edita código; escreva só em docs/delivery/ ($rel)."
        ;;
      mobile-squad:qa-engineer)
        if grep -qE '/src/([[:alpha:]]*Main|main)/' <<<"/$rel"; then
          deny "qa-engineer não altera código de produção ($rel). Registre um bug QA para o Dev."
        fi
        ;;
    esac
    ;;
esac
exit 0
