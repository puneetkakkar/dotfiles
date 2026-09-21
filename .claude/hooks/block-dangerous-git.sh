#!/bin/bash
# PreToolUse(Bash) guard. Blocks git commands that destroy uncommitted work or
# rewrite already-published history. Plain `git push` is deliberately allowed:
# it adds commits, it is reversible, and it is a routine request.
#
# Exit 2 tells Claude Code to reject the tool call and show stderr to the model.

set -u

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

# Each pattern is prefixed with ANCHOR so the git invocation must BEGIN a
# command: start of string, or after ; & | or an opening paren. Without this the
# guard trips on its own name inside an argument, e.g.
#   git log --grep="git reset --hard"
#   rg 'git clean -fd' docs/
# which are both read-only.
ANCHOR='(^|[;&|(])[[:space:]]*'

DANGEROUS_PATTERNS=(
  # Destroys uncommitted work
  'git[[:space:]]+reset[[:space:]]+(--hard|--merge)'
  'git[[:space:]]+clean[[:space:]]+-[a-z]*f'
  'git[[:space:]]+checkout[[:space:]]+(--[[:space:]]+)?\.'
  'git[[:space:]]+restore[[:space:]]+(--[a-z]+[[:space:]]+)*\.'
  'git[[:space:]]+stash[[:space:]]+(clear|drop)'
  # Destroys unmerged branches
  'git[[:space:]]+branch[[:space:]]+-[a-zA-Z]*D'
  # Rewrites published history
  'git[[:space:]]+push[[:space:]]+.*(--force([^-]|$)|-f([[:space:]]|$))'
  'git[[:space:]]+filter-branch'
  'git[[:space:]]+update-ref[[:space:]]+-d'
  'git[[:space:]]+reflog[[:space:]]+expire'
  'git[[:space:]]+gc[[:space:]]+.*--prune=now'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if printf '%s' "$COMMAND" | grep -qE "${ANCHOR}${pattern}"; then
    printf 'BLOCKED: %s\n' "$COMMAND" >&2
    printf 'Matched guard pattern: %s\n' "$pattern" >&2
    printf 'The user has blocked this command. Ask them to run it themselves if it is genuinely needed.\n' >&2
    exit 2
  fi
done

exit 0
