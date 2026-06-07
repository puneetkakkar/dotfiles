#!/usr/bin/env bash
# Safe-override symlink helper.
#
# Used by bootstrap.sh. Sourced, not executed.
#
# For each path:
#   target = $HOME/<rel>
#   source = $DOTFILES_REPO/<rel>
# Behavior:
#   - target missing                    → create symlink
#   - target == correct symlink         → no-op (idempotent)
#   - target is anything else (file,    → move to $DOTFILES_BACKUP_DIR/<rel>,
#     dir, or wrong symlink)              then create symlink
#
# Nothing is ever deleted. Backups are recoverable.

: "${DOTFILES_REPO:?DOTFILES_REPO must be set before sourcing symlink.sh}"
: "${DOTFILES_BACKUP_DIR:=$HOME/.dotfiles-backup/$(date +%Y%m%dT%H%M%S)}"
export DOTFILES_BACKUP_DIR

# link_file <src> <tgt> — symlink an arbitrary source path to an arbitrary target.
# Same safe-override semantics as link_dotfile.
link_file() {
  local src="$1"
  local tgt="$2"

  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    printf '  [skip] %s (source not found)\n' "$src"
    return 0
  fi

  if [ -L "$tgt" ] && [ "$(readlink "$tgt")" = "$src" ]; then
    printf '  [ok]   %s\n' "$tgt"
    return 0
  fi

  if [ -e "$tgt" ] || [ -L "$tgt" ]; then
    local bak="$DOTFILES_BACKUP_DIR/$(basename "$tgt")"
    mkdir -p "$(dirname "$bak")"
    mv "$tgt" "$bak"
    printf '  [bak]  %s  →  %s\n' "$tgt" "$bak"
  fi

  mkdir -p "$(dirname "$tgt")"
  ln -s "$src" "$tgt"
  printf '  [link] %s\n' "$tgt"
}

link_dotfile() {
  local rel="$1"
  local src="$DOTFILES_REPO/$rel"
  local tgt="$HOME/$rel"

  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    printf '  [skip] %s (not in repo)\n' "$rel"
    return 0
  fi

  if [ -L "$tgt" ] && [ "$(readlink "$tgt")" = "$src" ]; then
    printf '  [ok]   %s\n' "$rel"
    return 0
  fi

  if [ -e "$tgt" ] || [ -L "$tgt" ]; then
    local bak="$DOTFILES_BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$bak")"
    mv "$tgt" "$bak"
    printf '  [bak]  %s  →  %s\n' "$rel" "$bak"
  fi

  mkdir -p "$(dirname "$tgt")"
  ln -s "$src" "$tgt"
  printf '  [link] %s\n' "$rel"
}
