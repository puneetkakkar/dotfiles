#!/bin/bash
# Claude Code Stop hook — fires when Claude finishes a turn.
# Plays a quiet Tink, clears the @claude-needs-input flag, and forces an
# immediate status redraw so the dot disappears without waiting for the
# next status-interval tick.

afplay /System/Library/Sounds/Tink.aiff >/dev/null 2>&1 &

if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  tmux set-option -wqu -t "$TMUX_PANE" @claude-needs-input
  tmux refresh-client -S 2>/dev/null
fi

exit 0
