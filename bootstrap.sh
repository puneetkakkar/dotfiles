#!/usr/bin/env bash
# Bootstrap a fresh macOS into the same terminal setup as the source machine.
#
# Idempotent: safe to re-run. Existing files are backed up to
# ~/.dotfiles-backup/<timestamp>/<original-path> before being replaced
# with symlinks into this repo.
#
# Usage:
#   git clone https://github.com/puneetkakkar/dotfiles.git ~/recovry/repos/dotfiles
#   cd ~/recovry/repos/dotfiles
#   ./bootstrap.sh

set -euo pipefail

DOTFILES_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_REPO

# shellcheck source=lib/symlink.sh
source "$DOTFILES_REPO/lib/symlink.sh"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# ----------------------------------------------------------------------------
# 1. Sanity checks
# ----------------------------------------------------------------------------
[ "$(uname)" = "Darwin" ] || { echo "ERROR: macOS only" >&2; exit 1; }
ARCH="$(uname -m)"
step "Bootstrapping dotfiles on macOS ($ARCH)"

# ----------------------------------------------------------------------------
# 2. Homebrew
# ----------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  step "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make sure brew is on PATH for the rest of this script
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ----------------------------------------------------------------------------
# 3. Brewfile (formulae + casks)
# ----------------------------------------------------------------------------
step "Installing brew formulae and casks"
brew bundle install --file="$DOTFILES_REPO/Brewfile"

# ----------------------------------------------------------------------------
# 4. Oh My Zsh
# ----------------------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  step "Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ----------------------------------------------------------------------------
# 5. nvm (managed separately from brew — official installer)
# ----------------------------------------------------------------------------
if [ ! -d "$HOME/.nvm" ]; then
  step "Installing nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# ----------------------------------------------------------------------------
# 6. SDKMAN (Java/JVM toolchain)
# ----------------------------------------------------------------------------
if [ ! -d "$HOME/.sdkman" ]; then
  step "Installing SDKMAN"
  curl -s "https://get.sdkman.io" | bash
fi

# ----------------------------------------------------------------------------
# 7. TPM (tmux plugin manager)
# ----------------------------------------------------------------------------
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  step "Installing TPM"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ----------------------------------------------------------------------------
# 8. Symlink dotfiles
# ----------------------------------------------------------------------------
step "Symlinking dotfiles"

# Top-level dotfiles
link_dotfile ".zshrc"
link_dotfile ".tmux.conf"
link_dotfile ".gitconfig"
link_dotfile ".p10k.zsh"
link_dotfile "tmux-cheatsheet.md"
link_dotfile "shell-cheatsheet.md"

# .config/
link_dotfile ".config/tmux/tmux.theme"
link_dotfile ".config/tmux/tmux.start.sh"
link_dotfile ".config/btop/btop.conf"
link_dotfile ".config/bat/config"
link_dotfile ".config/ccstatusline/settings.json"

# .claude/ (settings, hooks, statusline scripts — runtime state stays local)
link_dotfile ".claude/settings.json"
link_dotfile ".claude/statusline-command.sh"
link_dotfile ".claude/statusline-wrapper.sh"
link_dotfile ".claude/hooks/notification.sh"
link_dotfile ".claude/hooks/stop.sh"
link_dotfile ".claude/hooks/block-dangerous-git.sh"

# .local/bin/
link_dotfile ".local/bin/claude-agent"
link_dotfile ".local/bin/claude-agent-launcher"
link_dotfile ".local/bin/claude-agent-pick"
link_dotfile ".local/bin/tmux-thumbs-pick"
link_dotfile ".local/bin/install-git-hooks-here"

# Git: caveman-commit enforcement
# - template/hooks/commit-msg auto-installs into newly-cloned non-husky repos
#   via init.templateDir (set in .gitconfig).
# - husky/init.sh is sourced by husky's `h` dispatcher for repos using husky;
#   together with `install-git-hooks-here` it gives husky repos the same
#   validation without committing anything to them.
link_dotfile ".config/git/template/hooks/commit-msg"
link_dotfile ".config/husky/init.sh"

# Optional / preserved-but-not-deployed:
#   .vimrc            (Vundle-based vim, polish later)
#   .config/nvim/     (full neovim config, polish later)
# Add `link_dotfile ".vimrc"` here when you decide to deploy them.

# ----------------------------------------------------------------------------
# 9. thumbs binary (no homebrew formula; release zip from upstream)
# ----------------------------------------------------------------------------
if [ ! -x "$HOME/.local/bin/thumbs" ]; then
  step "Downloading thumbs binary"
  TMP="$(mktemp -d)"
  curl -fsSL -o "$TMP/thumbs.zip" \
    "https://github.com/fcsonline/tmux-thumbs/releases/download/0.8.0/tmux-thumbs_0.8.0_x86_64-apple-darwin.zip"
  unzip -q "$TMP/thumbs.zip" -d "$TMP"
  mkdir -p "$HOME/.local/bin"
  mv "$TMP/thumbs" "$HOME/.local/bin/thumbs"
  chmod +x "$HOME/.local/bin/thumbs"
  rm -rf "$TMP"
fi

# ----------------------------------------------------------------------------
# 10. Rosetta 2 (Apple Silicon only — needed for the x86_64 thumbs binary)
# ----------------------------------------------------------------------------
if [ "$ARCH" = "arm64" ]; then
  if ! arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
    step "Installing Rosetta 2"
    softwareupdate --install-rosetta --agree-to-license
  fi
fi

# ----------------------------------------------------------------------------
# 11. Set per-repo personal email for this dotfiles repo
# ----------------------------------------------------------------------------
step "Configuring per-repo git identity for dotfiles"
git -C "$DOTFILES_REPO" config user.email "pkakkar996@gmail.com"
git -C "$DOTFILES_REPO" config user.name  "Puneet Kakkar"

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------
step "Bootstrap complete"

if [ -d "${DOTFILES_BACKUP_DIR:-}" ]; then
  echo "Backups of overridden files: $DOTFILES_BACKUP_DIR"
fi

cat <<'EOF'

Manual steps remaining (see docs/manual-steps.md for details):

  1. SSH key:        ssh-keygen -t ed25519 -C "your_email"
                     gh ssh-key add ~/.ssh/id_ed25519.pub
                     # And add the .pub to ~/.ssh/allowed_signers for commit signing

  2. GitHub CLI:     gh auth login

  3. Claude Code:    claude /login

  4. Tmux plugins:   open tmux, press prefix + I (capital I) to install
                     resurrect + continuum via TPM

  5. Optional:       deploy .vimrc / .config/nvim by uncommenting their
                     link_dotfile lines in bootstrap.sh and re-running

EOF
