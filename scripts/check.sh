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
task_keys=(id title status issue depends_on module ui rework_count)
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
