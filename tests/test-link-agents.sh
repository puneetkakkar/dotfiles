#!/usr/bin/env bash
# Exercise lib/agents.sh against throwaway $HOME dirs. Never touches the real
# $HOME. Run: tests/test-link-agents.sh
set -uo pipefail

DOTFILES_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_REPO
pass=0 fail=0

ok()  { pass=$((pass + 1)); printf '  ok    %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf '  FAIL  %s\n' "$1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# Run link_agents in a subshell with HOME and the backup dir pointed at $1.
run_link() {
  (
    export HOME="$1" DOTFILES_BACKUP_DIR="$1/.backup"
    source "$DOTFILES_REPO/lib/symlink.sh"
    source "$DOTFILES_REPO/lib/agents.sh"
    link_agents
  )
}

new_home() { mktemp -d "${TMPDIR:-/tmp}/agents-test.XXXXXX"; }

first_skill=$(basename "$(ls -d "$DOTFILES_REPO"/agents/skills/*/ | head -1)")

echo "fresh machine"
H=$(new_home)
run_link "$H" >/dev/null
check "check-agents passes" "HOME='$H' '$DOTFILES_REPO/scripts/check-agents' >/dev/null"
check "no cursor dir created" "[ ! -e '$H/.cursor' ]"
check "no gemini dir created" "[ ! -e '$H/.gemini' ]"

echo "idempotent re-run"
out=$(run_link "$H")
check "second run only reports [ok]" "! grep -qE '\[(link|bak|prune)\]' <<<\"\$out\""

echo "existing copies from a hand install"
H=$(new_home)
mkdir -p "$H/.claude/skills/$first_skill" "$H/.agents/skills/$first_skill" "$H/.claude/skills/synced"
echo claude > "$H/.claude/skills/$first_skill/SKILL.md"
echo agents > "$H/.agents/skills/$first_skill/SKILL.md"
echo keep > "$H/.claude/skills/synced/marker"
echo old > "$H/.claude/CLAUDE.md"
run_link "$H" >/dev/null
check "claude copy backed up"   "grep -qx claude '$H/.backup/.claude/skills/$first_skill/SKILL.md'"
check "agents copy backed up"   "grep -qx agents '$H/.backup/.agents/skills/$first_skill/SKILL.md'"
check "old CLAUDE.md backed up" "grep -qx old '$H/.backup/.claude/CLAUDE.md'"
check "synced dir untouched"    "[ ! -L '$H/.claude/skills/synced' ] && grep -qx keep '$H/.claude/skills/synced/marker'"
check "check-agents passes"     "HOME='$H' '$DOTFILES_REPO/scripts/check-agents' >/dev/null"

echo "renamed skill"
H=$(new_home)
mkdir -p "$H/.claude/skills"
ln -s "$DOTFILES_REPO/agents/skills/gone-skill" "$H/.claude/skills/gone-skill"
ln -s "/nonexistent/elsewhere" "$H/.claude/skills/foreign"
run_link "$H" >/dev/null
check "dangling repo link pruned"      "[ ! -L '$H/.claude/skills/gone-skill' ]"
check "dangling foreign link kept"     "[ -L '$H/.claude/skills/foreign' ]"

echo "optional agents installed"
H=$(new_home)
mkdir -p "$H/.cursor" "$H/.gemini" "$H/.config/opencode"
run_link "$H" >/dev/null
check "cursor skills linked"   "[ -L '$H/.cursor/skills/$first_skill' ]"
check "gemini GEMINI.md linked" "[ -L '$H/.gemini/GEMINI.md' ]"
check "opencode AGENTS.md linked" "[ -L '$H/.config/opencode/AGENTS.md' ]"
check "check-agents passes"    "HOME='$H' '$DOTFILES_REPO/scripts/check-agents' >/dev/null"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
