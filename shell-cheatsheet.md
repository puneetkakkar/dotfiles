# Shell Cheatsheet

A practical guide to your zsh setup. Skim it once, then come back when you hit a workflow that's annoying — there's probably already a shortcut for it.

> **How to use this doc:** each section starts with **"When to reach for it"** so you can spot the trigger in your day. Examples use real things you do (git, docker, kubectl, claude, AWS, Python).

---

## Table of contents

1. [Top 10 — start here](#top-10--start-here)
2. [Modern CLI replacements](#modern-cli-replacements)
3. [Navigation](#navigation)
4. [Per-project environments (direnv)](#per-project-environments-direnv)
5. [Search & find](#search--find)
6. [History](#history)
7. [Command-line editing keys](#command-line-editing-keys)
8. [fzf — the power tool](#fzf--the-power-tool)
9. [Git workflow](#git-workflow)
10. [Docker & Kubernetes](#docker--kubernetes)
11. [API & data tools (xh, yq)](#api--data-tools-xh-yq)
12. [Claude Code](#claude-code)
13. [Global pipeline aliases](#global-pipeline-aliases)
14. [Functions](#functions)
15. [Real-world workflows](#real-world-workflows)
16. [Troubleshooting & rollback](#troubleshooting--rollback)
17. [Recommended next installs](#recommended-next-installs)

---

## Top 10 — start here

If you only learn ten things, learn these. Each gives you a measurable speedup right away.

| Shortcut | What it does |
|---|---|
| `↑` after typing a prefix | Walks history of commands matching that prefix |
| `Ctrl+R` | Fuzzy search of all 100k history entries |
| `Ctrl+T` | Fuzzy file picker — inserts paths into current command |
| `Alt+C` | Fuzzy cd into a subdirectory |
| `z foo` | Jump to most-frecent dir matching `foo` |
| `Ctrl+X Ctrl+E` | Open current command in Cursor; save+quit runs it |
| `Alt+.` | Insert last argument of previous command |
| `cat file.py` | Now syntax-highlighted via bat |
| `ll` | Pretty `ls -la` via eza, with git status per file |
| `\| G pattern` | Anywhere on the line, expands to `\| grep -i pattern` |

---

## Modern CLI replacements

**When to reach for it:** every time you'd reach for `cat`, `ls`, or `top`.

| Old | Now | Why |
|---|---|---|
| `cat file.py` | `bat file.py` (aliased) | Syntax highlighting + line numbers |
| `ls -la` | `ll` (aliased) | Eza, with git status, icons, types |
| `ls -la` (tree) | `ll.tree` | 2-level tree, git status, icons |
| `top` / `htop` | `top` (aliased to btop) | Colorful, mouse-friendly, low overhead |

**Examples:**

```bash
ll                           # full pretty listing of cwd
ll.tree src                  # see src/ as a 2-level tree
cat ~/.zshrc                 # bat with paging off — scrolls in your terminal
\cat ~/.zshrc                # bypass alias when you want raw cat
```

The `\cat` (or `command cat`) escape works for any aliased command.

---

## Navigation

**When to reach for it:** every time you `cd ..` more than once, or you're remembering where a project lives.

### Dots — the classic upgrade

```bash
..        # cd ..
...       # cd ../..
....      # cd ../../..
.....     # cd ../../../..
-         # cd to previous directory (toggles)
```

### zoxide — the smart cd

`zoxide` learns which directories you visit. After a few days it knows where you mean.

```bash
z conv               # → /Users/puneetkakkar/scratch/conv_export
z grasp              # → wherever you spend time matching "grasp"
zi                   # opens fzf picker over all known dirs
```

You don't have to remember exact paths — partial matches work, ranked by frecency (frequency × recency).

### `mkcd` — make + enter

```bash
mkcd ~/projects/new-thing      # mkdir -p + cd into it, in one step
```

---

## Per-project environments (direnv)

**When to reach for it:** any time you find yourself running `export AWS_PROFILE=...` or `export DATABASE_URL=...` because you're switching between projects/clinics/clients. direnv automates this.

### How it works

Drop a `.envrc` file in any directory. When you `cd` in, direnv loads it; when you `cd` out, it unloads. Each new `.envrc` requires `direnv allow` once (a safety check so random repos can't run code on you).

### Setup per project

```bash
cd ~/Github/my-service
cat > .envrc <<'EOF'
export AWS_PROFILE=my-project-prod
export AWS_DEFAULT_REGION=us-east-2
export SSH_HOST=<bastion>
EOF
direnv allow
```

Now every time you `cd` into this repo, those vars are set automatically. Walk out, they vanish.

### Important: keep `.envrc` out of git

```bash
echo ".envrc" >> .gitignore
```

`.envrc` is **per-developer config** (your AWS profile name, your bastion host) — not the project's source code. Never commit it.

### When you change `.envrc`

direnv detects the edit and asks you to re-`allow`:

```bash
direnv allow                  # re-approve after editing
direnv reload                 # reload current dir's .envrc immediately
direnv status                 # see what's loaded right now
```

### Patterns I recommend

**Layered config — load a base file, then override per project:**

```bash
# ~/.envrc.aws-prod (in your home dir, not in repos)
export AWS_PROFILE=my-project-prod
export AWS_DEFAULT_REGION=us-east-2

# In a project's .envrc
source_env ~/.envrc.aws-prod
export PROJECT_SPECIFIC=foo
```

**Python virtualenv auto-activate:**

```bash
# project/.envrc
layout python3                # creates/uses .direnv/python-x.x.x and activates
```

**Node version per project (works with nvm):**

```bash
# project/.envrc  (alongside .nvmrc)
use node                      # auto-switches via nvm
```

**Secrets from 1Password (when you set it up):**

```bash
# project/.envrc
export DB_PASSWORD=$(op read "op://Personal/db/password")
```

---

## Search & find

**When to reach for it:** finding code in the repo, finding files by name, grepping logs.

### `rg` (ripgrep) — content search

```bash
rg "TODO"                    # all TODOs in cwd, fast
rg "patient_id" -t py        # only Python files
rg -i "error" --glob '!*.test.*'   # case-insensitive, exclude test files
rg "createUser" -A 5 -B 2    # show 5 lines after, 2 before each match
```

`rg` respects `.gitignore` — it ignores `node_modules`, `.venv`, etc. by default.

### `fd` — filename search

```bash
fd config                     # files matching "config" anywhere
fd '\.tsx?$' src              # all .ts/.tsx in src/
fd -e py -x rg "TODO" {}      # all .py files, run rg on each
```

Faster than `find`, sane defaults, regex by default.

---

## History

**When to reach for it:** "what was that long command I ran last week?"

Your history holds **100,000** entries, shared across all open terminals. Three ways to recall:

### 1. Prefix search with arrow keys

Type the start of the command, then `↑`/`↓` walk through matches.

```bash
git push                  # type this, then press ↑ a few times
                          # → only past `git push …` commands surface
```

### 2. Fuzzy search with `Ctrl+R`

Press `Ctrl+R`, type any fragment from anywhere in the command. fzf ranks matches by recency + match quality.

```text
Ctrl+R → "ssm get"
matches: aws ssm get-parameter --name /database/...
         aws ssm get-parameters-by-path --path /database/
```

`Ctrl+R` again cycles to next match. `Enter` runs it. `Tab` puts it on the line for editing.

### 3. Last argument with `Alt+.`

```bash
mkdir /tmp/long/path/here       # then…
cd  Alt+.                       # expands to: cd /tmp/long/path/here
```

Pressing `Alt+.` repeatedly walks through the last args of older commands.

### Privacy: leading-space mode

Commands starting with a space are NOT recorded.

```bash
 export AWS_SECRET_KEY=...      # the leading space hides it from history
```

---

## Command-line editing keys

**When to reach for it:** mid-command when you need to fix something without retyping.

| Key | Action |
|---|---|
| `Ctrl+A` / `Ctrl+E` | Jump to start / end of line |
| `Alt+B` / `Alt+F` | Move backward / forward by word |
| `Ctrl+W` | Delete word backward |
| `Alt+D` | Delete word forward |
| `Ctrl+U` | Delete from cursor to start of line |
| `Ctrl+K` | Delete from cursor to end of line |
| `Ctrl+Y` | Yank (paste) what you just deleted |
| `Ctrl+T` | Swap two characters (fix typos: `gti`→cursor between→`Ctrl+T`→`git`) |
| `Ctrl+L` | Clear screen, keep current command |
| `Ctrl+_` | Undo last edit |
| **`Ctrl+X Ctrl+E`** | **Open current command in Cursor; save + quit runs it** |

**Real example:** drafting a long find/replace one-liner. Type the rough version, then `Ctrl+X Ctrl+E` — Cursor opens with full editing power. Save, close, command runs.

### Right arrow on grayed text (autosuggest)

zsh-autosuggestions shows a grayed-out suggestion of what you typed last time. Press `→` to accept it whole, or `Alt+→` to accept just the next word.

---

## fzf — the power tool

**When to reach for it:** any time you'd alt-tab to a file manager, scroll through `ll`, or copy-paste a path.

### `Ctrl+T` — file picker

Type the start of any command, hit `Ctrl+T`, fuzzy-pick a file (or many — `Tab` to multi-select), they're inserted into your command.

```bash
cat <Ctrl+T>              # browse, pick, file path inserted, Enter to view
git add <Ctrl+T>          # multi-select files to stage
mv <Ctrl+T> <Ctrl+T>      # source then dest
cp ~/Downloads/* <Ctrl+T> # destination via picker
```

### `Alt+C` — directory cd

Same as `Ctrl+T` but only lists directories, and runs `cd` for you.

```bash
Alt+C → "exp"
matches: scratch/conv_export
         repos/grasp-backend/services/event_service
Enter → cd
```

### `**<Tab>` — fzf completion anywhere

Triggers fzf for whatever the command expects.

```bash
ssh **<Tab>               # fuzzy ssh hosts
kill **<Tab>              # fuzzy process picker
git checkout **<Tab>      # fuzzy branch picker
unset **<Tab>             # fuzzy env-var picker
```

### `zi` — fuzzy zoxide

```bash
zi                        # fzf picker over your dir history
```

---

## Git workflow

**When to reach for it:** every time you touch git.

### From OMZ git plugin (already loaded)

| Alias | Expands to |
|---|---|
| `gst` | `git status` |
| `gco branch` | `git checkout branch` |
| `gcb branch` | `git checkout -b branch` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `glo` | `git log --oneline --decorate` |
| `gcam "msg"` | `git commit -a -m "msg"` |
| `grb branch` | `git rebase branch` |
| `gpsup` | `git push --set-upstream origin <current>` |

Run `alias \| grep '^g.*git'` to see all of them.

### Added in this config

```bash
glog                          # full graph: git log --oneline --graph --decorate --all
gwip                          # quick stash-as-commit: git add -A && git commit -m "wip"
gundo                         # undo last commit, keep changes staged
gsync                         # git fetch --all --prune && git pull --rebase
clonecd <url>                 # clone + cd into the new repo
```

### Common scenarios

**Drop a quick checkpoint mid-feature:**
```bash
gwip                          # commit current state as "wip"
# … keep working …
gundo                         # later: peel off the wip commit, changes stay staged
```

**Refresh your branch on top of main:**
```bash
gco main && gsync && gco -    # update main, return to feature branch
git rebase main               # rebase onto fresh main
```

**Quick visual log:**
```bash
glog | head -30               # see the topology of recent commits
```

### `lg` — lazygit TUI

**When to reach for it:** anything more complex than `git status` / `git commit`. Especially: staging only some hunks, interactive rebase, blame, browsing log graph.

```bash
lg                            # alias for `lazygit`, runs in current repo
```

**Most-used keys inside lazygit:**

| Key | Action |
|---|---|
| `Space` | Stage/unstage file or hunk under cursor |
| `a` | Stage all |
| `c` | Commit (opens editor for message) |
| `C` | Commit with conventional-commit prefix picker |
| `A` | Amend last commit |
| `P` | Push (uppercase!) |
| `p` | Pull |
| `b` | Branches panel — checkout, rename, delete |
| `r` | On a commit: interactive rebase from there |
| `s` / `f` / `d` | While rebasing: squash / fixup / drop the commit |
| `M` | Mergetool (visual conflict resolution) |
| `←` / `→` | Switch panels (status / files / branches / commits / stash) |
| `?` | Help |
| `q` | Quit |

**Quintessential workflow — interactive rebase to clean up:**
1. `lg` → press `←`/`→` to commits panel → put cursor on the commit you want to rebase onto top of
2. Press `r` for interactive rebase
3. On each commit: `s` (squash into above), `f` (fixup), `e` (edit), `d` (drop)
4. Press `m` to start the rebase

**Stage just one hunk:**
1. `lg` → put cursor on file with changes
2. `Enter` to drill into hunks
3. `Space` on each hunk to toggle staging
4. `c` to commit just those

---

## Docker & Kubernetes

### Docker

```bash
dps                           # readable: name | image | status | ports
dprune                        # nuke stopped containers, dangling images, volumes
```

### Kubernetes (via OMZ kubectl plugin)

| Alias | Expands to |
|---|---|
| `k` | `kubectl` |
| `kgp` | `kubectl get pods` |
| `kgs` | `kubectl get services` |
| `kgd` | `kubectl get deployments` |
| `kdp pod-name` | `kubectl describe pod pod-name` |
| `kl pod-name` | `kubectl logs pod-name` |
| `klf pod-name` | `kubectl logs -f pod-name` (follow) |
| `kex pod-name -- bash` | `kubectl exec -it pod-name -- bash` |
| `kcuc context` | `kubectl config use-context` |

### `kx` / `kn` — switch context & namespace

**When to reach for it:** every time you change clusters or namespaces. Replaces `kubectl config use-context …` muscle memory.

```bash
kx                            # list contexts, interactive picker (fzf if available)
kx prod                       # switch to "prod" context
kx -                          # toggle to previous context (like `cd -`)

kn                            # list namespaces in current context
kn default                    # switch to "default" namespace
kn -                          # toggle to previous namespace
```

Pairs perfectly with direnv — put `export KUBECONFIG=...` per project so each repo lands in the right cluster.

### `k9s` — Kubernetes TUI

**When to reach for it:** anytime you'd otherwise type `kubectl get/describe/logs` more than twice. Way faster for exploration.

```bash
k9s                           # opens dashboard in current context
k9s -c pods                   # land directly on pods view
k9s --context prod            # specific context
k9s -n production             # specific namespace
```

**Most-used keys inside k9s:**

| Key | Action |
|---|---|
| `:` | Command palette — type `pods`, `deployments`, `services`, `nodes`, `events`, etc. |
| `/` | Filter the current view (live regex) |
| `Enter` | Drill into selected resource |
| `Esc` | Back |
| `l` | Stream logs of selected pod |
| `s` | Shell into selected pod (`kubectl exec`) |
| `d` | Describe |
| `e` | Edit YAML in `$EDITOR` |
| `Ctrl+D` | Delete selected resource (asks confirmation) |
| `Ctrl+K` | Kill (force delete) |
| `?` | Help |
| `q` / `Ctrl+C` | Quit |

**Quintessential workflow — debug a CrashLoopBackOff pod:**
1. `k9s` → `:pods` → `/CrashLoop` to filter
2. Cursor on the pod → `l` to stream its logs
3. `Esc` → `d` to see describe (events, restarts, last state)
4. `Esc` → `s` to shell in (if it's at least up briefly)

---

## API & data tools (xh, yq)

**When to reach for it:** poking an API, parsing yaml configs, processing JSON.

### `xh` — friendly curl

```bash
xh GET httpbin.org/get
xh POST api.example.com/users name=puneet role=admin     # auto JSON body
xh GET api.example.com/data Authorization:"Bearer $TOKEN"
xh PUT api.example.com/users/1 name="new name"
xh --download GET https://example.com/big.zip            # save to file
xh -p Bb GET api.example.com                              # show request+response headers and body
```

Auto-colorizes JSON. Pipe into `jq` (`J`) for further filtering:
```bash
xh GET api.example.com/users J '.[] | select(.active)'
```

### `yq` — jq for YAML/JSON/XML

```bash
yq '.spec.replicas' deployment.yaml
yq '.services.api.image' docker-compose.yml

# in-place edit (saves back to the file)
yq -i '.metadata.labels.team = "growth"' deployment.yaml
yq -i '.spec.replicas = 5' deployment.yaml

# convert formats
yq -o=json '.' file.yaml > file.json
yq -p=json -o=yaml '.' file.json > file.yaml

# pipe into jq for advanced queries
yq -o=json '.' values.yaml | jq '.image.tag'
```

Realistic uses for your stack:
- Bumping image tags in Helm `values.yaml`
- Toggling feature flags in GitHub Actions workflows
- Extracting secrets keys from `kustomization.yaml`

---

## Claude Code

```bash
c                             # alias for `claude`
cr                            # `claude --resume` — pick a past session interactively
cc                            # `claude --continue` — continue most-recent session
```

**Workflow:**
```bash
cd ~/projects/myrepo
c                             # start fresh in this repo
# … exit later …
cc                            # next day: resume right where you left off
cr                            # or pick a different past session
```

---

## Global pipeline aliases

**When to reach for it:** anywhere you'd pipe to grep/less/jq/head/tail. These work mid-pipeline (zsh's "global aliases").

| Token | Expands to | Example |
|---|---|---|
| `G pattern` | `\| grep -i pattern` | `ps aux G claude` |
| `L` | `\| less` | `dmesg L` |
| `J '.foo'` | `\| jq '.foo'` | `gh api repos/concentra/apophis J '.stargazers_count'` |
| `H` | `\| head` | `glog H` |
| `T` | `\| tail` | `cat /var/log/syslog T` |

Combine them:
```bash
docker ps -a G exited H 5     # last 5 exited containers
kgp G CrashLoop               # crash-looping pods only
```

---

## Functions

```bash
mkcd <dir>                    # mkdir -p && cd
clonecd <git-url>             # git clone && cd into the repo
bbk <file>                    # backup file as file.bak.YYYYMMDD
port <number>                 # show what's listening on TCP port <number>
```

**Examples:**

```bash
mkcd ~/projects/new-feature
clonecd git@github.com:concentra-ai/apophis.git
bbk ~/.config/bat/themes/VesperExtended.tmTheme   # before risky edit
port 3000                                          # who's holding port 3000?
```

---

## Real-world workflows

### Starting a new repo from scratch

```bash
mkcd ~/projects/awesome
git init -b main
c                             # claude: "scaffold a TS project with vitest"
gst                           # see what claude generated
git add -A && git commit -m "scaffold"
gh repo create --source=. --public --push
```

### Reviewing someone's PR locally

```bash
gh pr checkout 123            # detach & checkout PR branch
glog H 20                     # see recent activity
gd main..HEAD                 # full diff vs main
c                             # ask claude to summarize the diff
```

### Debugging a stuck process on a port

```bash
port 8080                     # see what's listening
kill -9 <pid>                 # or `kill **<Tab>` to fuzzy-pick
```

### Cleaning up after a long week

```bash
dprune                        # docker volumes + dangling images gone
gst                           # any uncommitted work?
gwip                          # stash it as "wip" commit
brew cleanup -s               # old downloads
du -sh ~/Library/Caches/*     # what's eating disk
```

### Comparing local to remote

```bash
gsync                         # fetch + rebase
git rev-list --left-right --count main...origin/main
```

### Inspecting a JSON API response

```bash
gh api repos/concentra-ai/apophis/pulls J '.[] | {n: .number, t: .title}'
xh GET https://api.example.com/data J '.results[0]'
```

### Onboarding to a new repo (direnv + first run)

```bash
clonecd git@github.com:concentra-ai/some-service.git
cat > .envrc <<'EOF'
export AWS_PROFILE=my-project-prod
export DATABASE_URL="postgresql://localhost/dev"
EOF
echo ".envrc" >> .gitignore
direnv allow
c "explain the architecture of this repo"     # claude with env vars set
```

### Bumping a Helm chart image tag with yq

```bash
yq -i '.image.tag = "v1.4.2"' charts/api/values.yaml
gd                            # eyeball the change
gcam "deploy api v1.4.2"
```

### Cleaning up a messy commit history before pushing

```bash
lg                            # lazygit
# → commits panel → cursor on first commit to keep
# → r (interactive rebase)
# → on each fixup commit: f
# → m to start, fix any conflicts, P to push
```

### Running a long shell loop you want to edit before running

```bash
for c in mercymd kjs orthoaz; do echo $c; done
# pre-commit: Ctrl+X Ctrl+E to open in Cursor, refine, save+quit, runs
```

### Recovering yesterday's command

```bash
Ctrl+R → "aws ssm"            # fuzzy through all 100k history entries
```

---

## Troubleshooting & rollback

### Roll back zsh config

```bash
cp ~/.zshrc.bak.20260507 ~/.zshrc && source ~/.zshrc
```

### Rebuild bat theme cache (after editing themes)

```bash
bat cache --build
```

### Roll back bat default theme

Edit `~/.config/bat/config`, change `--theme="VesperExtended"` to whatever you want. `bat --list-themes` shows all options.

### A new alias broke something

Bypass any alias: prefix with backslash.

```bash
\cat file.py                  # real cat, not bat
\ls                           # real ls, not eza
```

Or use `command`:

```bash
command cat file.py
```

### Shell startup feels slow

Profile it:

```bash
zsh -i -l -c exit             # measure baseline
time (zsh -i -c exit)
```

If > 0.5s, the usual culprits are: many OMZ plugins, nvm (load is heavy), pyenv. Lazy-load patterns exist for nvm if needed.

---

## Recommended next installs

### Already installed and used in this config

**Foundation:** `bat`, `eza`, `btop`, `ripgrep` (rg), `fd`, `tldr`, `fzf`, `zoxide`, `gh`, `claude`, `cursor`, `docker`, `kubectl`, `jq`, `pyenv`, `nvm`, `pnpm`, `sdkman`

**Workflow tier 1:** `direnv` (per-project envs), `lazygit` (`lg`), `k9s` (k8s TUI), `kubectx`/`kubens` (`kx`/`kn`), `yq`, `xh`

**Already-set git diff:** `diff-so-fancy` (configured as `core.pager` in `~/.gitconfig`)

### Worth adding when convenient

| Tool | Install | Why |
|---|---|---|
| `jless` | `brew install jless` | Like `less` but for JSON — collapsible, navigable |
| `glow` | `brew install glow` | Pretty-render markdown in terminal: `glow README.md` |
| `dust` | `brew install dust` | Visual `du`. Instantly see what's eating disk |
| `procs` | `brew install procs` | Modern `ps` with tree view + colors |
| `shellcheck` | `brew install shellcheck` | Lint shell scripts before they bite |
| `entr` | `brew install entr` | Re-run a command when files change: `ls *.py \| entr pytest` |
| `mkcert` | `brew install mkcert` | Trusted local HTTPS certs for dev |
| `watch` | `brew install watch` | `watch kgp` — refresh a command repeatedly |

---

## Quick learning path

If you want to phase the integration over a week:

- **Day 1:** practice `Ctrl+R` (history fuzzy) and `↑` (history prefix). These alone replace 80% of typing.
- **Day 2:** `Ctrl+T` (file picker) and `Alt+C` (cd picker). Stop typing paths.
- **Day 3:** `z foo` instead of `cd path/to/foo`. Let it learn your habits.
- **Day 4:** `Ctrl+X Ctrl+E` for any command longer than ~80 chars.
- **Day 5:** OMZ git aliases (`gst`, `gco`, `gd`, `glo`). Pick three, use them all day.
- **Day 6:** Pipeline aliases (`G`, `J`, `H`, `T`). Notice when you type `| grep -i` and replace.
- **Day 8:** Run `lg` in any repo and force yourself to commit one feature with it instead of `git` CLI.
- **Day 9:** Set up `direnv` in one repo where you keep re-typing `export AWS_PROFILE=…`.
- **Day 10:** Open `k9s` next time you'd `kubectl get pods`. Stay in for 5 minutes — explore views (`:pods`, `:deployments`, `:events`).
- **Day 7:** Functions (`mkcd`, `port`, `bbk`). Use them next time the situation comes up.

After two weeks of this you'll be measurably faster, and the shortcuts that don't fit your work will fade naturally.
