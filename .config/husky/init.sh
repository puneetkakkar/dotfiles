# Husky init hook — sourced by `.husky/_/h` before every husky-dispatched hook.
# Used here to inject caveman-commit validation into any repo that has husky
# wired up, without touching the repo's own .husky/ files.
#
# This file is sourced (not exec'd). `exit N` inside it propagates to the
# husky dispatcher and aborts the commit if N is non-zero.
#
# Caveman-commit rules: see ~/.claude/skills/caveman-commit/SKILL.md.

# Husky sets `n` to the hook name (basename "$0") before sourcing init.sh.
# Only gate on commit-msg; other hooks (pre-commit, pre-push, etc.) pass through.
if [ "${n:-}" = "commit-msg" ]; then
  msg_file="$1"
  msg=$(cat "$msg_file")
  subject=$(printf '%s\n' "$msg" | head -n1)

  case "$subject" in
    "Merge "*|"Revert "*|"Reapply "*|"fixup! "*|"squash! "*|"amend! "*) ;;
    *)
      errors=0

      if printf '%s' "$msg" | grep -qiE "co-authored-by:[[:space:]]*claude\b"; then
        echo "✖ commit-msg: 'Co-Authored-By: Claude ...' trailer is forbidden." >&2
        errors=$((errors + 1))
      fi

      if printf '%s' "$msg" | grep -qiE "generated[[:space:]]+with[[:space:]]+\[?claude\b"; then
        echo "✖ commit-msg: 'Generated with Claude ...' footer is forbidden." >&2
        errors=$((errors + 1))
      fi

      subject_len=$(printf '%s' "$subject" | wc -c | tr -d ' ')
      if [ "$subject_len" -gt 72 ]; then
        echo "✖ commit-msg: subject line is $subject_len chars (hard cap 72)." >&2
        echo "  → $subject" >&2
        errors=$((errors + 1))
      fi

      if [ "$errors" -gt 0 ]; then
        echo "" >&2
        echo "  Rewrite the message and try again. Style: ~/.claude/skills/caveman-commit/SKILL.md" >&2
        exit 1
      fi
      ;;
  esac
fi
