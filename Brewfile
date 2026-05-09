# Brewfile — `brew bundle install --file=Brewfile` reproduces this list.
#
# Curated (not raw `brew bundle dump`): only the things actively used
# by the shell + tmux + Claude Code setup. Auth/account state (gh, gcloud,
# kubectl) lives outside brew and is restored manually — see docs/manual-steps.md.

# ---- Modern CLI replacements ----
brew "bat"          # syntax-highlighted cat
brew "btop"         # better top
brew "eza"          # ls replacement (used by `ll` etc.)
brew "ripgrep"      # rg — faster grep, respects .gitignore

# ---- Search & navigation ----
brew "fzf"          # fuzzy finder (Ctrl+R, Ctrl+T, claude-agent picker)
brew "zoxide"       # smart cd (`z foo`)
brew "direnv"       # per-project envs

# ---- Multiplexer ----
brew "tmux"

# ---- Git tooling ----
brew "gh"               # GitHub CLI (used by prefix F / prefix P bindings)
brew "lazygit"          # TUI git
brew "diff-so-fancy"    # gitconfig pager

# ---- Data tools ----
brew "jq"
brew "yq"
brew "xh"           # nicer curl

# ---- Kubernetes ----
brew "kubectx"      # kubectx + kubens

# ---- Languages / package managers ----
brew "pnpm"
brew "pyenv"
# nvm and sdkman use their own installers; bootstrap.sh handles them.

# ---- Zsh ecosystem ----
brew "powerlevel10k"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# ---- Coreutils (predictable cross-platform behavior) ----
brew "coreutils"

# ---- Casks (GUI apps) ----
cask "ghostty"      # terminal
cask "cursor"       # editor (EDITOR=cursor --wait in zshrc)
