#!/usr/bin/env bash
# Live checks against the installed Claude Code: runs headless `claude -p`
# sessions in a scratch git repo and asserts what the model actually sees.
# Costs a few model calls. Run after scripts/link-agents:
#   tests/live-claude.sh
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0 fail=0
ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n        %s\n' "$1" "$2"; }

W=$(mktemp -d "${TMPDIR:-/tmp}/live-claude.XXXXXX")
git -C "$W" init -q
trap 'rm -rf "$W"' EXIT

# Skill names split by invocation, read from the repo.
read -r -a MODEL_SKILLS < <(cd "$REPO/agents/skills" && for s in */; do
  grep -q '^disable-model-invocation: true' "$s/SKILL.md" || printf '%s ' "${s%/}"; done)
read -r -a MANUAL_SKILLS < <(cd "$REPO/agents/skills" && for s in */; do
  grep -q '^disable-model-invocation: true' "$s/SKILL.md" && printf '%s ' "${s%/}"; done)
# paths-scoped skills may legitimately stay hidden until a matching file is touched.
PATH_SKILLS=" typescript-best-practices principle-type-system-discipline "

ask() {  # ask <prompt> [extra claude args...] -> stream-json on stdout
  local prompt="$1"; shift
  (cd "$W" && claude -p "$prompt" --output-format stream-json --verbose "$@" 2>/dev/null)
}
final_text() { python3 -c '
import sys, json
for line in sys.stdin:
    try: d = json.loads(line)
    except ValueError: continue
    if d.get("type") == "result": print(d.get("result", ""))'; }

echo "1. every skill is registered"
init=$(ask "reply OK" --max-turns 1 | head -1)
missing=$(python3 -c '
import json, sys, os
d = json.loads(sys.argv[1]); have = set(d.get("skills", []))
want = sorted(os.listdir(sys.argv[2]))
paths_only = set(sys.argv[3].split())
print(" ".join(s for s in want if s not in have and s not in paths_only))' "$init" "$REPO/agents/skills" "$PATH_SKILLS")
[ -z "$missing" ] && ok "every skill without paths is in init" || bad "skills missing from init" "$missing"

slash_missing=$(python3 -c '
import json, sys
have = set(json.loads(sys.argv[1]).get("slash_commands", []))
print(" ".join(s for s in sys.argv[2:] if s not in have))' "$init" "${MANUAL_SKILLS[@]}")
[ -z "$slash_missing" ] && ok "every manual skill is a /command" || bad "manual skills not in / menu" "$slash_missing"

echo "2. model sees exactly the model-invoked set"
listed=$(ask "List the name of every skill you can invoke with the Skill tool, one per line, names only, no other text." --max-turns 1 | final_text)
for s in "${MODEL_SKILLS[@]}"; do
  if grep -qx -- "$s" <<<"$listed"; then ok "visible: $s"
  elif [[ "$PATH_SKILLS" == *" $s "* ]]; then ok "hidden until matching file (paths): $s"
  else bad "should be visible: $s" "model listed: $(tr '\n' ' ' <<<"$listed")"; fi
done
for s in "${MANUAL_SKILLS[@]}"; do
  grep -qx -- "$s" <<<"$listed" && bad "manual skill visible to model: $s" "" || ok "hidden: $s"
done

echo "3. global AGENTS.md is loaded as CLAUDE.md"
ans=$(ask "Per your global user instructions, which skill's rules apply to every commit? Answer with the skill name only." --max-turns 1 | final_text)
grep -q "caveman-commit" <<<"$ans" && ok "commit rule found" || bad "commit rule not found" "$ans"

echo "4. which code-review wins (built-in vs vendored)"
ans=$(ask "Quote the one-line description of the skill named code-review exactly as it appears in your skill list, nothing else." --max-turns 1 | final_text)
if grep -qi "two axes\|fixed point" <<<"$ans"; then ok "vendored code-review is the one listed"
else bad "code-review resolves to a different skill" "$ans"; fi

echo "5. TypeScript file pulls in typescript-best-practices"
mkdir -p "$W/src" && printf 'export type User = { id: string; email: string };\n' > "$W/src/user.ts"
git -C "$W" add -A && git -C "$W" -c commit.gpgsign=false commit -qm init
events=$(ask "In src/user.ts add a function that parses unknown JSON input into a User. Keep it short." \
  --max-turns 8 --permission-mode acceptEdits --allowedTools "Read,Edit,Write,Skill")
used=$(python3 -c '
import sys, json
names = set()
for line in sys.stdin:
    try: d = json.loads(line)
    except ValueError: continue
    m = d.get("message")
    if not isinstance(m, dict):  # some event types carry a string message
        continue
    for c in m.get("content") or []:
        if isinstance(c, dict) and c.get("type") == "tool_use" and c.get("name") == "Skill":
            names.add(c["input"].get("skill") or c["input"].get("command") or "")
print(" ".join(sorted(names)))' <<<"$events")
for s in typescript-best-practices principle-type-system-discipline; do
  [[ " $used " == *" $s "* ]] && ok "invoked $s" || bad "$s not invoked" "skills used: ${used:-none}"
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
