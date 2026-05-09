# dotfiles

Personal dotfiles for macOS — zsh + tmux + Ghostty + Claude Code +
neovim, plus a small set of custom helpers (claude-agent worktrees,
tmux-thumbs hint-copy, focus-aware "Claude needs input" indicator).

Read [`tmux-cheatsheet.md`](tmux-cheatsheet.md) and
[`shell-cheatsheet.md`](shell-cheatsheet.md) for the workflow guide; this
file is just install instructions.

## One-line install on a fresh Mac

```bash
git clone https://github.com/puneetkakkar/dotfiles.git ~/recovry/repos/dotfiles \
  && cd ~/recovry/repos/dotfiles \
  && ./bootstrap.sh
```

Then complete the [manual steps](docs/manual-steps.md) — SSH keys,
`gh auth login`, `claude /login`, `prefix I` for tmux plugins.

## What `bootstrap.sh` does

| Step | What |
|---|---|
| 1 | Sanity-check macOS + arch |
| 2 | Install Homebrew |
| 3 | `brew bundle install` — formulae and casks from `Brewfile` |
| 4 | Install Oh My Zsh |
| 5 | Install nvm |
| 6 | Install SDKMAN |
| 7 | Install TPM (tmux plugin manager) |
| 8 | Symlink dotfiles into `$HOME` (safe-override — backs up existing) |
| 9 | Download `thumbs` binary (no homebrew formula) |
| 10 | Install Rosetta 2 (Apple Silicon — `thumbs` is x86_64) |
| 11 | Configure per-repo git identity for this repo |

Everything is idempotent. Re-running `bootstrap.sh` is safe — it skips
what's already done.

## Safe-override mechanics

For every file the script symlinks, three cases:

| Existing target at `$HOME/<path>` | Action |
|---|---|
| Doesn't exist | Create symlink to repo |
| Already a symlink to the right repo path | No-op |
| Anything else (file, dir, wrong symlink) | Move to `~/.dotfiles-backup/<timestamp>/<path>`, then symlink |

Nothing is ever deleted. If something breaks, the backup directory has
a recoverable copy of every file replaced.

## What's deployed

- Top-level: `.zshrc`, `.tmux.conf`, `.gitconfig`, `.p10k.zsh`, two cheatsheets
- `.config/`: `tmux/` (theme + start script), `btop/`, `bat/`, `ccstatusline/`
- `.claude/`: `settings.json`, statusline scripts, hooks (`notification.sh`,
  `stop.sh`, `block-dangerous-git.sh`)
- `.local/bin/`: `claude-agent*` trio, `tmux-thumbs-pick`

## What's preserved but NOT deployed

- `.vimrc` (Vundle-based vim config)
- `.config/nvim/` (Lua-based neovim config)

These are in the repo for safekeeping but not symlinked into `$HOME`.
When you're ready to use them, uncomment their lines in `bootstrap.sh`
and re-run.

## What's not in this repo (intentionally)

- SSH / GPG keys — machine-specific, never in a public repo
- Shell history, claude history, sessions, tmux resurrect snapshots — runtime state
- `~/.claude/projects/*/memory/` — auto-memory stays machine-local
- Cloud auths (AWS, GCP, kubectl configs)

See [docs/manual-steps.md](docs/manual-steps.md) for what to do about
each after running bootstrap.

## Updating

The repo is the source of truth. After bootstrap, every file in `$HOME`
that's deployed is a symlink into this repo. Edit through the symlink
(or directly in the repo) and `git commit && git push` like any other
project. The other Mac picks it up via `git pull && ./bootstrap.sh`
(re-running bootstrap is fine; no-op for already-correct symlinks).
