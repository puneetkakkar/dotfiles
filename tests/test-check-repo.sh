#!/usr/bin/env bash
# Prove setup-repo-agents' check-repo.py passes a correct repo and catches
# each breakage it claims to. Builds throwaway repos; never touches real ones.
# Run: tests/test-check-repo.sh
set -uo pipefail

CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/agents/skills/setup-repo-agents/scripts/check-repo.py"
pass=0 fail=0

# A minimal correct repo: AGENTS.md, one model-invoked and one manual skill,
# and the Claude symlink.
fixture() {
  local r
  r=$(mktemp -d "${TMPDIR:-/tmp}/check-repo.XXXXXX")
  printf '# Demo\n\nRun npm test.\n' > "$r/AGENTS.md"
  mkdir -p "$r/.agents/skills/demo-review/agents" "$r/.agents/skills/demo-deploy/agents" "$r/.claude"
  printf -- '---\nname: demo-review\ndescription: Review demo diffs. Use when reviewing.\n---\n\nReview.\n' \
    > "$r/.agents/skills/demo-review/SKILL.md"
  printf 'interface:\n  display_name: "Demo Review"\n' > "$r/.agents/skills/demo-review/agents/openai.yaml"
  printf -- '---\nname: demo-deploy\ndescription: Deploy the demo app.\ndisable-model-invocation: true\n---\n\nDeploy.\n' \
    > "$r/.agents/skills/demo-deploy/SKILL.md"
  printf 'interface:\n  display_name: "Demo Deploy"\npolicy:\n  allow_implicit_invocation: false\n' \
    > "$r/.agents/skills/demo-deploy/agents/openai.yaml"
  ln -s ../.agents/skills "$r/.claude/skills"
  echo "$r"
}

# expect <pass|fail> <label> <expected substring or ""> <mutation run in the repo> [extra args]
expect() {
  local want="$1" label="$2" needle="$3" mutate="$4" r out rc
  r=$(fixture)
  (cd "$r" && eval "$mutate")
  out=$(HOME="${FAKE_HOME:-$r/.nohome}" python3 "$CHECK" "$r" ${5:-} 2>&1); rc=$?
  if { [ "$want" = pass ] && [ $rc -eq 0 ]; } ||
     { [ "$want" = fail ] && [ $rc -ne 0 ] && grep -qF -- "$needle" <<<"$out"; }; then
    pass=$((pass + 1)); printf '  ok    %s\n' "$label"
  else
    fail=$((fail + 1)); printf '  FAIL  %s\n%s\n' "$label" "$out"
  fi
  rm -rf "$r"
}

echo "correct setups pass"
expect pass "fixture repo" "" ":"
expect pass "CLAUDE.md importing AGENTS.md" "" "printf '@AGENTS.md\n\nClaude-only note.\n' > CLAUDE.md"
expect pass "no skills at all" "" "rm -rf .agents .claude"

echo "instructions"
expect fail "AGENTS.md missing" "AGENTS.md missing" "rm AGENTS.md"
expect fail "AGENTS.md over 32 KiB" "Codex stops reading" "head -c 40000 /dev/zero | tr '\\\\0' x >> AGENTS.md"
expect fail "CLAUDE.md without import" "without an @AGENTS.md import" "echo '# Claude' > CLAUDE.md"

echo "layout"
expect fail "legacy .claude/commands" ".claude/commands/ holds" "mkdir -p .claude/commands && echo x > .claude/commands/plan.md"
expect fail "legacy .claude/agents" ".claude/agents/ holds" "mkdir -p .claude/agents && echo x > .claude/agents/rev.md"
expect fail "legacy .cursor/skills" ".cursor/skills/ holds" "mkdir -p .cursor/skills/x && echo x > .cursor/skills/x/SKILL.md"
expect fail ".claude/skills real dir" "is a real dir" "rm .claude/skills && mkdir .claude/skills"
expect fail "missing Claude symlink" "must be a symlink" "rm .claude/skills"

echo "skills"
expect fail "name not matching folder" "must match the folder" "sed -i '' 's/^name: demo-review/name: demo-reviewer/' .agents/skills/demo-review/SKILL.md"
expect fail "uppercase name" "lowercase letters" "mv .agents/skills/demo-review .agents/skills/Demo-Review && sed -i '' 's/^name: demo-review/name: Demo-Review/' .agents/skills/Demo-Review/SKILL.md"
expect fail "description too long" "description must be 1-1024" "python3 -c \"p='.agents/skills/demo-review/SKILL.md';s=open(p).read();open(p,'w').write(s.replace('Review demo diffs.', 'x'*1100))\""
expect fail "Claude manual, Codex implicit" "Codex manual=False" "sed -i '' '/policy/d;/allow_implicit/d' .agents/skills/demo-deploy/agents/openai.yaml"
expect fail "dependency on manual skill" "depends on manual skill 'demo-deploy'" "echo 'Call the Skill tool with \"demo-deploy\".' >> .agents/skills/demo-review/SKILL.md"
expect fail "lock entry without folder" "lists 'ghost'" "echo '{\"skills\":{\"ghost\":{}}}' > skills-lock.json"

echo "global clash"
FAKE_HOME=$(mktemp -d)
mkdir -p "$FAKE_HOME/.claude/skills/demo-review"
printf -- '---\nname: demo-review\ndescription: global one\n---\n' > "$FAKE_HOME/.claude/skills/demo-review/SKILL.md"
export FAKE_HOME
expect fail "repo skill shadowed by global" "same name as a global skill" ":"
expect pass "--no-global skips the clash check" "" ":" "--no-global"
expect fail "dependency on missing skill" "depends on missing skill 'nope'" "echo 'Call the Skill tool with \"nope\".' >> .agents/skills/demo-review/SKILL.md; sed -i '' 's/^name: demo-review/name: demo-reviews/' .agents/skills/demo-review/SKILL.md; mv .agents/skills/demo-review .agents/skills/demo-reviews"
expect pass "unknown dependency tolerated without globals (may be global elsewhere)" "" "echo 'Call the Skill tool with \"nope\".' >> .agents/skills/demo-review/SKILL.md" "--no-global"
unset FAKE_HOME

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
