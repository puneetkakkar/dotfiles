# dotfiles

Personal dotfiles for macOS — zsh + tmux + Ghostty + Claude Code +
neovim, plus a small set of custom helpers (claude-agent worktrees,
tmux-thumbs hint-copy, focus-aware "Claude needs input" indicator).

Read [`tmux-cheatsheet.md`](tmux-cheatsheet.md) and
[`shell-cheatsheet.md`](shell-cheatsheet.md) for the workflow guide (deployed
to `~/Documents/Cheatsheets/` on your Mac); this file is just install instructions.

## One-line install on a fresh Mac

```bash
git clone https://github.com/puneetkakkar/dotfiles.git ~/Github/dotfiles \
  && cd ~/Github/dotfiles \
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
| 8 | Create `~/.config/dotfiles/local.env` — prompts for `REPOS_DIR` (your git repos root) |
| 9 | Symlink dotfiles into `$HOME` (safe-override — backs up existing) |
| 10 | Download `thumbs` binary (no homebrew formula) |
| 11 | Install Rosetta 2 (Apple Silicon — `thumbs` is x86_64) |
| 12 | Configure per-repo git identity for this repo |

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

- Top-level: `.zshrc`, `.tmux.conf`, `.gitconfig`, `.p10k.zsh`
- `~/Documents/Cheatsheets/`: `tmux-cheatsheet.md`, `shell-cheatsheet.md`
- `.config/`: `tmux/` (theme + start script), `btop/`, `bat/`, `ccstatusline/`,
  `direnv/`
- `.claude/`: `settings.json`, statusline scripts, hooks (`notification.sh`,
  `stop.sh`, `block-dangerous-git.sh`). Claude-only settings live here.
- `agents/`: global instructions and skills for every coding agent (see
  [Coding agents](#coding-agents-agents))
- `.local/bin/`: `claude-agent`, `claude-agent-launcher`, `claude-agent-pick`,
  `claude-agent-rename`, `claude-worktree-status`, `tmux-thumbs-pick`,
  `install-git-hooks-here`
- Git commit-message enforcement ("caveman-commit"): `.config/git/template/hooks/commit-msg`
  (auto-installs into new repos via `init.templateDir`) and `.config/husky/init.sh`
  (same validation for husky-managed repos, paired with `install-git-hooks-here`)

## Coding agents (`agents/`)

One agent-neutral source serves Claude Code, Codex, and any agent that reads
the Agent Skills `SKILL.md` format.

| Path | Linked to |
|---|---|
| `agents/AGENTS.md` | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, plus `~/.gemini/GEMINI.md` and `~/.config/opencode/AGENTS.md` when those agents are installed |
| `agents/skills/<name>/` | `~/.claude/skills/<name>`, `~/.agents/skills/<name>` (Codex), plus `~/.cursor/skills`, `~/.gemini/skills` and `~/.config/opencode/skills` when installed |

Bootstrap links each skill on its own, so other entries in those dirs (such as
`~/.claude/skills/synced` from the claude.ai account) stay put. It also removes
links to skills that no longer exist in the repo.

Each skill is either **model-invoked** (the agent may load it on its own) or
**manual** (only the user can run it, as `/name` in Claude or `$name` in
Codex). Claude reads `disable-model-invocation: true` in `SKILL.md`; Codex
reads `policy.allow_implicit_invocation: false` in `agents/openai.yaml`.
`scripts/check-agents` fails if the two disagree.

Skills are vendored from upstream at pinned commits. `agents/skills.lock.json`
records each skill's repo, path and commit, and `agents/ATTRIBUTION.md` records
every local edit and why.

| Command | Use |
|---|---|
| `scripts/link-agents` | Re-link after a pull, or after adding, removing or renaming a skill |
| `scripts/check-agents` | Validate structure, invocation parity, dependencies and links |
| `scripts/skills-upstream outdated` | List skills whose upstream changed since the pinned commit |
| `scripts/skills-upstream diff` | Confirm every difference from upstream is a recorded edit |

To add a skill: copy its folder into `agents/skills/`, add an
`agents/openai.yaml` if upstream has none, add it to `skills.lock.json`, then
run `scripts/link-agents`.

A skill that belongs to one repo goes in that repo's `.agents/skills/`, the
project dir most agents read. Claude Code reads only `.claude/skills/`, so add
a `.claude/skills` symlink to `../.agents/skills` in that repo.

### Tests

| Command | Checks |
|---|---|
| `tests/test-check-agents.sh` | `check-agents` catches each class of breakage it claims to |
| `tests/test-link-agents.sh` | linking in throwaway `$HOME`s: fresh machine, re-run, backups, pruning, optional agents |
| `tests/test-git-guardrail.sh` | `block-dangerous-git.sh` blocks and allows the right commands |
| `tests/live-claude.sh` | real `claude -p` sessions: what the model sees, `AGENTS.md` loaded, `paths` skills fire (costs a few model calls) |
| `tests/test-codex.py` | installed Codex: every skill loads from the repo, `openai.yaml` parsed, model sees only model-invoked skills, `AGENTS.md` loaded (no login, no model calls) |

## What's preserved but NOT deployed

- `.vimrc` (Vundle-based vim config)
- `.config/nvim/` (Lua-based neovim config)

These are in the repo for safekeeping but not symlinked into `$HOME`.
When you're ready to use them, uncomment their lines in `bootstrap.sh`
and re-run.

## Machine-local config (`~/.config/dotfiles/local.env`)

`bootstrap.sh` creates this file from `.config/dotfiles/local.env.template` on first run (with a prompt). It holds settings that differ per machine and is **not tracked in git**.

Current knobs:

| Variable | Default | What it controls |
|---|---|---|
| `REPOS_DIR` | `$HOME/Github` | Root directory scanned by `prefix A` (claude-agent-pick) when you're outside a git repo |
| `WORKTREES_DIR` | `$HOME/Worktrees` | Root directory where `prefix A` (claude-agent) places git worktrees (`$WORKTREES_DIR/<repo>/<label>/`) |

To add a new knob: add it to `.config/dotfiles/local.env.template` with a default, read it in whatever script needs it (source the file at startup), and re-run `bootstrap.sh` — it will skip creation since the file exists, so copy the new line in manually or delete `~/.config/dotfiles/local.env` to regenerate.

## What's not in this repo (intentionally)

- `~/.config/dotfiles/local.env` — machine-local overrides, generated by bootstrap (see above)
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
(re-running bootstrap is fine; no-op for already-correct symlinks). For a
change under `agents/` only, `git pull && scripts/link-agents` is enough.
