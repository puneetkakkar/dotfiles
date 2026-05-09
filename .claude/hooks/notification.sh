#!/bin/bash
# Claude Code Notification hook — fires when Claude needs user input.
#
# Set @claude-needs-input on the pane's window IF the user isn't currently
# viewing it. "Viewing" = the window is the active window in its session AND
# the session has a client attached. If you're already staring at the prompt,
# we don't pollute the status bar with a redundant alert.
#
# Sound plays unconditionally — that's still a useful cross-app signal.

afplay /System/Library/Sounds/Pop.aiff >/dev/null 2>&1 &

if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  viewed=$(tmux display-message -p -t "$TMUX_PANE" '#{?#{&&:#{window_active},#{session_attached}},1,0}' 2>/dev/null)
  if [ "$viewed" != "1" ]; then
    tmux set-option -wq -t "$TMUX_PANE" @claude-needs-input 1
    tmux refresh-client -S 2>/dev/null
  fi
fi

exit 0
