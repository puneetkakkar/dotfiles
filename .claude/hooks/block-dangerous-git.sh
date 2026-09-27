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

block() {
  printf 'BLOCKED: %s\n' "$COMMAND" >&2
  printf 'Matched guard pattern: %s\n' "$1" >&2
  printf 'The user has blocked this command. Ask them to run it themselves if it is genuinely needed.\n' >&2
  exit 2
}

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if printf '%s' "$COMMAND" | grep -qE "${ANCHOR}${pattern}"; then
    block "$pattern"
  fi
done

# `git restore .` overwrites the whole working tree, but `git restore --staged .`
# only unstages. A regex cannot express "has -S and not -W", so check each
# whole-tree restore by its flags: it is safe only when it targets the index
# alone (--staged/-S, no --worktree/-W).
while IFS= read -r restore; do
  flags=" ${restore#*restore} "
  case "$flags" in *" . "*) ;; *) continue ;; esac
  staged=0 worktree=0
  for f in $flags; do
    case "$f" in
      --staged) staged=1 ;;
      --worktree) worktree=1 ;;
      --*) ;;
      -*) [[ "$f" == *S* ]] && staged=1; [[ "$f" == *W* ]] && worktree=1 ;;
    esac
  done
  if [ "$staged" -eq 0 ] || [ "$worktree" -eq 1 ]; then
    block 'git restore . (touches the working tree)'
  fi
done < <(printf '%s' "$COMMAND" | grep -oE "${ANCHOR}git[[:space:]]+restore[^;&|]*")

exit 0
