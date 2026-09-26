#!/usr/bin/env bash
# Prove scripts/check-agents catches each class of breakage: copy scripts/ and
# agents/ into a scratch repo, break one thing, expect the named failure.
# Run: tests/test-check-agents.sh
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0 fail=0

# expect_fail <label> <expected output substring> <mutation, run inside the copy>
expect_fail() {
  local label="$1" want="$2" mutate="$3" d out
  d=$(mktemp -d "${TMPDIR:-/tmp}/check-agents.XXXXXX")
  cp -R "$REPO/scripts" "$REPO/agents" "$d/"
  (cd "$d" && eval "$mutate")
  out=$("$d/scripts/check-agents" --repo 2>&1)
  if [ $? -ne 0 ] && grep -qF -- "$want" <<<"$out"; then
    pass=$((pass + 1)); printf '  ok    %s\n' "$label"
  else
    fail=$((fail + 1)); printf '  FAIL  %s\n%s\n' "$label" "$out"
  fi
  rm -rf "$d"
}

echo "baseline"
if "$REPO/scripts/check-agents" --repo >/dev/null; then
  pass=$((pass + 1)); echo "  ok    unmodified repo passes"
else
  fail=$((fail + 1)); echo "  FAIL  unmodified repo fails"
fi

echo "mutations"
expect_fail "claude manual, codex implicit" "invocation mismatch" \
  "sed -i '' '/allow_implicit_invocation/d; /^policy:/d' agents/skills/handoff/agents/openai.yaml"
expect_fail "codex manual, claude implicit" "invocation mismatch" \
  "printf 'policy:\n  allow_implicit_invocation: false\n' >> agents/skills/tdd/agents/openai.yaml"
expect_fail "frontmatter name drift" "frontmatter name" \
  "sed -i '' 's/^name: grilling$/name: grill/' agents/skills/grilling/SKILL.md"
expect_fail "empty description" "description empty" \
  "sed -i '' 's/^description:.*/description:/' agents/skills/research/SKILL.md"
expect_fail "cursor path left in" "Cursor-only path" \
  "echo 'see .cursor/skills/x' >> agents/skills/blast-radius/SKILL.md"
expect_fail "dependency made manual" "depends on manual skill 'codebase-design'" \
  "sed -i '' 's/^description:/disable-model-invocation: true\ndescription:/' agents/skills/codebase-design/SKILL.md && printf 'policy:\n  allow_implicit_invocation: false\n' >> agents/skills/codebase-design/agents/openai.yaml"
expect_fail "dependency removed" "depends on missing skill 'domain-modeling'" \
  "rm -rf agents/skills/domain-modeling && python3 -c \"import json;p='agents/skills.lock.json';d=json.load(open(p));d['skills'].pop('domain-modeling');open(p,'w').write(json.dumps(d))\""
expect_fail "principle dependency removed" "depends on missing skill 'principle-type-system-discipline'" \
  "rm -rf agents/skills/principle-type-system-discipline && python3 -c \"import json;p='agents/skills.lock.json';d=json.load(open(p));d['skills'].pop('principle-type-system-discipline');open(p,'w').write(json.dumps(d))\""
expect_fail "skill missing from lock" "not in skills.lock.json" \
  "cp -R agents/skills/wait-what agents/skills/wait-huh && sed -i '' 's/^name: wait-what$/name: wait-huh/' agents/skills/wait-huh/SKILL.md"
expect_fail "lock entry without folder" "in skills.lock.json but no folder" \
  "python3 -c \"import json;p='agents/skills.lock.json';d=json.load(open(p));d['skills']['ghost']={'source':'pstack','path':'x'};open(p,'w').write(json.dumps(d))\""
expect_fail "AGENTS.md missing" "agents/AGENTS.md missing" "rm agents/AGENTS.md"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
