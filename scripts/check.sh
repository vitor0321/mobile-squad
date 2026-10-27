#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

errors=()
fail() { errors+=("$1"); }

agents=(product-manager mobile-designer tech-lead kmp-developer qa-engineer senior-reviewer)
read_only_agents=(tech-lead senior-reviewer mobile-designer)
skills=(discover deliver squad-init kmp-standards mobile-ux-standards delivery-artifacts)
templates=(PROJECT_CONTEXT PRD UX_SPEC TASK TASK_REVIEW TEST_PLAN CODE_REVIEW UI_REVIEW ACCEPTANCE DELIVERY_REPORT)
verdict_templates=(TASK_REVIEW CODE_REVIEW UI_REVIEW ACCEPTANCE)
task_keys=(id title status issue depends_on module ui risk rework_count)
scripts=(scripts/verify.sh scripts/issues.sh hooks/guard.sh)
id_prefixes='TRN|CRN|CTN|UIN|QAN|VFN|ACN'
templates_dir=skills/delivery-artifacts/templates

frontmatter() { awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f' "$1"; }

for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md; do
  [[ -f $f ]] || fail "arquivo ausente: $f"
done

for a in "${agents[@]}"; do
  f=agents/$a.md
  if [[ ! -f $f ]]; then fail "agente ausente: $f"; continue; fi
  fm=$(frontmatter "$f")
  for key in name description tools model; do
    grep -q "^$key:" <<<"$fm" || fail "$f: frontmatter sem '$key'"
  done
done

for a in "${read_only_agents[@]}"; do
  f=agents/$a.md
  [[ -f $f ]] || continue
  if frontmatter "$f" | grep '^tools:' | grep -qw Edit; then
    fail "$f: agente de revisão não pode ter Edit"
  fi
done

for s in "${skills[@]}"; do
  f=skills/$s/SKILL.md
  if [[ ! -f $f ]]; then fail "skill ausente: $f"; continue; fi
  fm=$(frontmatter "$f")
  for key in name description; do
    grep -q "^$key:" <<<"$fm" || fail "$f: frontmatter sem '$key'"
  done
done

for t in "${templates[@]}"; do
  [[ -f $templates_dir/$t.md ]] || fail "template ausente: $templates_dir/$t.md"
done

for t in "${verdict_templates[@]}"; do
  f=$templates_dir/$t.md
  [[ -f $f ]] || continue
  grep -qF 'APPROVED | CHANGES_REQUESTED' "$f" || fail "$f: sem 'APPROVED | CHANGES_REQUESTED'"
done

if [[ -f $templates_dir/TASK.md ]]; then
  fm=$(frontmatter "$templates_dir/TASK.md")
  for key in "${task_keys[@]}"; do
    grep -q "^$key:" <<<"$fm" || fail "$templates_dir/TASK.md: frontmatter sem '$key'"
  done
fi

for f in "${scripts[@]}"; do
  if [[ ! -f $f ]]; then fail "script ausente: $f"; continue; fi
  bash -n "$f" 2>/dev/null || fail "$f: erro de sintaxe"
done

if [[ -f hooks/hooks.json ]]; then
  python3 -m json.tool hooks/hooks.json >/dev/null 2>&1 || fail "hooks/hooks.json: JSON inválido"
  grep -q 'guard.sh' hooks/hooks.json || fail "hooks/hooks.json: não chama guard.sh"
else
  fail "arquivo ausente: hooks/hooks.json"
fi

if [[ -f hooks/guard.sh ]]; then
  guard() { CLAUDE_PROJECT_DIR=/nonexistent bash hooks/guard.sh <<<"$1" >/dev/null 2>&1; echo $?; }
  [[ $(guard '{"tool_name":"Bash","agent_type":"mobile-squad:kmp-developer","tool_input":{"command":"git commit -m x"}}') == 2 ]] ||
    fail "hooks/guard.sh: não bloqueia commit de agente do squad"
  [[ $(guard '{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}') == 0 ]] ||
    fail "hooks/guard.sh: bloqueia commit fora do squad"
  [[ $(guard '{"tool_name":"Write","agent_type":"mobile-squad:senior-reviewer","tool_input":{"file_path":"/nonexistent/app/src/commonMain/A.kt"}}') == 2 ]] ||
    fail "hooks/guard.sh: revisor consegue escrever código"
fi

for a in "${agents[@]}"; do
  f=agents/$a.md
  [[ -f $f ]] || continue
  frontmatter "$f" | grep '^tools:' | grep -qw Skill && fail "$f: agente não deve ter a ferramenta Skill"
  grep -qiE 'leia (a|as) skills? ' "$f" && fail "$f: manda reler skill já pré-carregada em skills:"
  grep -q 'gradlew' "$f" && fail "$f: roda Gradle direto em vez de verify.sh"
done

while IFS= read -r hit; do
  fail "prefixo de id fora do contrato ($id_prefixes): $hit"
done < <(grep -rnoE '\b[A-Z]{2,3}[N0-9]-[0-9]{2}\b' "$templates_dir" agents | grep -vE "($id_prefixes)-|CA[0-9]" || true)

while IFS= read -r hit; do
  fail "instrução proibida (commit/push/fechar issue): $hit"
done < <(grep -rnE 'git commit|git push|gh issue close' --include='*.md' agents skills README.md 2>/dev/null \
  | grep -viE 'nunca|não' || true)

if ((${#errors[@]})); then
  printf 'FAIL (%d)\n' "${#errors[@]}"
  printf '  - %s\n' "${errors[@]}"
  exit 1
fi

for target in .claude-plugin/marketplace.json .claude-plugin/plugin.json agents skills; do
  claude plugin validate "$target" >/dev/null || { echo "FAIL: claude plugin validate $target"; exit 1; }
done
echo "PASS"
