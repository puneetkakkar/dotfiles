# =============================================================================
# ~/.zshrc — Puneet Kakkar
#
# Sections (in order):
#   1.  Powerlevel10k instant prompt  (must stay at top)
#   2.  Editor & locale
#   3.  History
#   4.  Oh My Zsh
#   5.  Theme & shell plugins
#   6.  Language version managers (pyenv, nvm, pnpm)
#   7.  Tool integrations (zoxide, terraform, dart)
#   8.  PATH (Android SDK, local bin)
#   9.  Aliases
#  10.  Functions
#  11.  Key bindings
#  12.  Optional integrations (fzf if installed)
#  13.  SDKMAN  (MUST be last per its docs)
# =============================================================================


# ─── 1. Powerlevel10k instant prompt ────────────────────────────────────────
# Initialization that needs console input (passwords, prompts) must go above.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ─── 2. Editor & locale ─────────────────────────────────────────────────────
export EDITOR="cursor --wait"
export VISUAL="$EDITOR"
export LANG=en_US.UTF-8


# ─── 3. History ─────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY        # timestamp + duration in history
setopt SHARE_HISTORY           # share across all sessions
setopt INC_APPEND_HISTORY      # write immediately, not on shell exit
setopt HIST_IGNORE_ALL_DUPS    # remove older duplicates
setopt HIST_IGNORE_SPACE       # ` cmd` (leading space) → not recorded
setopt HIST_REDUCE_BLANKS      # strip extra whitespace before saving
setopt HIST_VERIFY             # !! shows command before running
setopt HIST_FIND_NO_DUPS       # skip dups when searching


# ─── 4. Oh My Zsh ───────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"   # overridden below by powerlevel10k

# Plugins — each adds aliases/completions. Keep the list lean: too many
# plugins slow shell startup. See $ZSH/plugins/<name>/<name>.plugin.zsh
plugins=(
  git                  # gst, gco, gcb, gp, gd, gl, glo, ...
  gh                   # GitHub CLI completion
  docker               # docker completion
  docker-compose       # dco completion
  kubectl              # k=kubectl, kgp=get pods, kgs=get services, ...
  npm                  # npm completion
  brew                 # brew completion
  command-not-found    # suggests Homebrew install when command not found
  colored-man-pages    # readable man pages
  extract              # `extract file.tar.gz` works for any archive type
)

source "$ZSH/oh-my-zsh.sh"


# ─── 5. Theme & shell plugins ───────────────────────────────────────────────
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# ─── 6. Language version managers ───────────────────────────────────────────
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac


# ─── 7. Tool integrations ───────────────────────────────────────────────────
# zoxide — smart cd: `z foo` jumps to the most-frecent dir matching foo.
#   `zi` opens fzf-style picker (only when fzf is installed).
eval "$(zoxide init zsh)"

# direnv — auto-load .envrc per directory (run `direnv allow` to approve a new one)
eval "$(direnv hook zsh)"

# terraform completion
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

# dart CLI completion
[[ -f $HOME/.dart-cli-completion/zsh-config.zsh ]] && . $HOME/.dart-cli-completion/zsh-config.zsh


# ─── 8. PATH ────────────────────────────────────────────────────────────────
# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"
# Local bin
export PATH="$HOME/.local/bin:$PATH"


# ─── 9. Aliases ─────────────────────────────────────────────────────────────
# --- modern CLI replacements ---
alias cat='bat --paging=never'
alias ls='eza --header --group --git --long'
alias ls.tree='eza --header --group --tree --level=2 --git --long --icons'
alias ll='eza --header --group --long --all'
alias ll.tree='eza --header --group --tree --level=2 --git --long --icons --all'
alias top='btop'

# --- navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'                   # cd to previous directory

# --- git (omz git plugin gives most; these are extra favorites) ---
alias glog='git log --oneline --graph --decorate --all'
alias gwip='git add -A && git commit -m "wip"'
alias gundo='git reset --soft HEAD~1'           # undo last commit, keep changes staged
alias gsync='git fetch --all --prune && git pull --rebase'
alias lg='lazygit'                              # TUI git: stage hunks, rebase, etc.

# --- docker / k8s ---
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dprune='docker system prune -af --volumes'
alias kx='kubectx'                              # switch k8s context (cluster)
alias kn='kubens'                               # switch k8s namespace

# --- claude code ---
# Function wrapper so every `claude` invocation — direct, alias, or the
# `tmux send-keys "claude"` line in claude-agent — loads project + local
# setting sources alongside user. The CLI defaults to user-only, which
# silently drops project skills like /build, /open-pr, /plan from
# apophis-style repos. Belt-and-suspenders with claude-agent pre-trust;
# this catches paths the script can't pre-write to.
claude() {
  command claude --setting-sources user,project,local "$@"
}

alias c='claude'
alias cr='claude --resume'                        # resume last session
alias cc='claude --continue'                      # continue most recent

# --- general / global ---
alias -g G='| grep -i'                            # `cmd G pattern` → cmd | grep -i pattern
alias -g L='| less'
alias -g J='| jq'
alias -g H='| head'
alias -g T='| tail'
alias cl='clear'
alias reload='source ~/.zshrc'
alias zshconfig='cursor ~/.zshrc'
alias myip='curl -s https://ipinfo.io/ip; echo'


# ─── 10. Functions ──────────────────────────────────────────────────────────
# mkcd — create directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# clonecd — git clone and cd into the new directory
# (named to avoid colliding with omz git's `gcl` = `git clone --recurse-submodules`)
clonecd() { git clone "$1" && cd "$(basename "$1" .git)"; }

# bbk — back up a file as file.bak.YYYYMMDD
bbk() { cp "$1" "$1.bak.$(date +%Y%m%d)"; }

# port — show what's listening on a port: `port 3000`
port() { lsof -nP -iTCP:"$1" -sTCP:LISTEN; }


# ─── 11. Key bindings ───────────────────────────────────────────────────────
bindkey -e   # emacs mode (also default; explicit for clarity)

# ↑ / ↓  — history search using whatever you've already typed as a prefix.
#         Type `git ` then ↑ to walk through past `git ...` commands only.
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Ctrl+X Ctrl+E — open the current command line in $EDITOR; save+quit runs it.
#                Useful for editing long multi-line commands.
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Alt+. — paste the last argument of the previous command (default, kept explicit)
bindkey '\e.' insert-last-word


# ─── 12. Optional integrations (auto-load when installed) ───────────────────
# fzf — fuzzy finder. Install with:
#   brew install fzf && $(brew --prefix)/opt/fzf/install
# When installed, gives Ctrl+R fuzzy history, Ctrl+T fuzzy file picker,
# Alt+C fuzzy directory cd. zoxide's `zi` also activates with fzf.
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh


# ─── 13. SDKMAN (MUST be last) ──────────────────────────────────────────────
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# JAVA_HOME tracks SDKMAN's current Java (for Flutter Doctor and Android builds)
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export PATH="$JAVA_HOME/bin:$PATH"
alias cheat='bat ~/shell-cheatsheet.md'
