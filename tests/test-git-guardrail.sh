#!/usr/bin/env bash
# Feed commands to .claude/hooks/block-dangerous-git.sh the way Claude Code
# does (PreToolUse JSON on stdin) and check each is blocked or allowed.
# Run: tests/test-git-guardrail.sh
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.claude/hooks/block-dangerous-git.sh"
pass=0 fail=0

expect() {  # expect <block|allow> <command>
  local want="$1" cmd="$2" got
  if jq -n --arg c "$cmd" '{tool_input:{command:$c}}' | bash "$HOOK" >/dev/null 2>&1; then
    got=allow
  else
    got=block
  fi
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf '  ok    %-5s %s\n' "$want" "$cmd"
  else
    fail=$((fail + 1)); printf '  FAIL  want %s, got %s: %s\n' "$want" "$got" "$cmd"
  fi
}

echo "destroys uncommitted work"
expect block 'git reset --hard HEAD~1'
expect block 'git reset --merge'
expect block 'cd x && git reset --hard'
expect block 'git clean -fd'
expect block 'git checkout .'
expect block 'git checkout -- .'
expect block 'git restore .'
expect block 'git restore --worktree .'
expect block 'git restore -W .'
expect block 'git restore --staged --worktree .'
expect block 'git restore -SW .'
expect block 'git restore --source=HEAD .'
expect block 'git stash drop'
expect block 'git stash clear'

echo "rewrites published history or drops branches"
expect block 'git push --force origin main'
expect block 'git push -f'
expect block 'git branch -D foo'
expect block 'git filter-branch --tree-filter x'
expect block 'git update-ref -d refs/heads/x'
expect block 'git reflog expire --expire=now --all'
expect block 'git gc --prune=now'

echo "safe: only adds commits, unstages, or reads"
expect allow 'git push'
expect allow 'git push origin feat/x'
expect allow 'git push --force-with-lease origin feat/x'
expect allow 'git reset --keep origin/main'
expect allow 'git reset --soft HEAD~1'
expect allow 'git reset -q'
expect allow 'git restore --staged .'
expect allow 'git restore -S .'
expect allow 'git restore --staged src/a.ts && git status'
expect allow 'git branch -d foo'
expect allow 'git stash'
expect allow 'git commit -m "x"'
expect allow 'git log --grep="git push"'
expect allow "rg 'git clean -f' docs/"

echo "known false positive: separators inside quotes still count"
expect block 'echo "run: cd x && git reset --hard"'

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
