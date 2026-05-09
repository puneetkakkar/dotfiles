#!/bin/bash
# Ghostty entrypoint: attach to the most useful tmux session, or start one.
#
# Behaviour:
#   1. If we're already inside tmux ($TMUX set), do nothing — never nest.
#   2. If no tmux server is running, start one. tmux-continuum's
#      `@continuum-restore 'on'` hook auto-restores the last saved sessions
#      when the server boots, so prior layouts come back across reboots.
#   3. Attach to the most-recently-used **unattached** session, so opening a
#      second Ghostty window gives you a different session by default.
#      Fall back to the most-recently-used session of any kind, then to a
#      fresh `main` session as a last resort.

set -e
export PATH="/opt/homebrew/bin:$PATH"

# 1) never nest
[ -n "$TMUX" ] && exit 0

# 2) ensure a server exists
if ! tmux info >/dev/null 2>&1; then
  # Start a placeholder session — this also boots the server, which triggers
  # tmux-continuum's auto-restore hook. Give it a beat to replay saved state.
  tmux new-session -d -s "_bootstrap"
  sleep 1

  # If continuum restored anything, drop the placeholder; otherwise rename it.
  session_count=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')
  if [ "$session_count" -gt 1 ]; then
    tmux kill-session -t "_bootstrap" 2>/dev/null || true
  else
    tmux rename-session -t "_bootstrap" "main"
  fi
fi

# 3) pick the best target: most-recently-used unattached, else most-recent overall
target=$(tmux list-sessions \
    -F '#{session_last_attached} #{session_attached} #{session_name}' \
    2>/dev/null \
  | sort -nr \
  | awk '$2 == 0 { print $3; exit }')

if [ -z "$target" ]; then
  target=$(tmux list-sessions \
      -F '#{session_last_attached} #{session_name}' \
      2>/dev/null \
    | sort -nr \
    | awk 'NR==1 { print $2 }')
fi

[ -z "$target" ] && target="main"

exec tmux attach-session -t "$target"
