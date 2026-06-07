# Tmux Cheatsheet

A practical guide to your tmux setup — the custom bindings, the Claude-agent flow, the focus-aware indicator, and how resurrect/continuum keeps your sessions alive across reboots. Skim once, then come back when you hit something annoying — there's probably already a shortcut.

> **How to use this doc:** each section starts with **"When to reach for it"** so you can spot the trigger in your day. Examples use real things you do (claude-agent on a Linear ticket, jumping between worktrees, recovering after a Ghostty quit).

> **Prefix is `Ctrl+a`** (rebound from default `Ctrl+b` — same logic as zsh: home-row beats reaching for `b`). Throughout this doc, `prefix X` means "press `Ctrl+a`, release, then press `X`".

---

## Table of contents

1. [Top picks — start here](#top-picks--start-here)
2. [Mental model](#mental-model)
3. [Sessions, windows, panes — navigation](#sessions-windows-panes--navigation)
4. [Splits & pane layout](#splits--pane-layout)
5. [Claude-agent — `prefix A`](#claude-agent--prefix-a)
6. [The "Claude needs input" indicator](#the-claude-needs-input-indicator)
7. [Popups — `prefix G`, `prefix F`, `prefix P`](#popups--prefix-g-prefix-f-prefix-p)
8. [Thumbs — `prefix y` hint-based copy](#thumbs--prefix-y-hint-based-copy)
9. [Copy mode (vi-style)](#copy-mode-vi-style)
10. [Resurrect & continuum — session persistence](#resurrect--continuum--session-persistence)
11. [Ghostty boot flow](#ghostty-boot-flow)
12. [Status bar — what each glyph means](#status-bar--what-each-glyph-means)
13. [Real-world workflows](#real-world-workflows)
14. [Troubleshooting & rollback](#troubleshooting--rollback)
15. [Quick learning path](#quick-learning-path)

---

## Top picks — start here

If you only learn these, you'll feel it. Each gives you measurable speedup right away.

| Shortcut | What it does |
|---|---|
| `prefix A` | Spawn or resume a Claude agent on a branch (fzf picker → worktree + tmux window + `claude` running) |
| `prefix s` | Zoomed session/window tree picker — jump anywhere |
| `prefix space` / `prefix bspace` | Next / previous window in the current session |
| `prefix h j k l` | Move between panes (vim-style) |
| `prefix \` / `prefix -` | Split horizontally / vertically (inherits cwd) |
| `prefix G` | Pop a temporary shell at the pane's cwd — `gh pr list`, `git status`, then close |
| `prefix F` | Focus on THIS branch — its PR title/state, CI checks, local git status |
| `prefix P` | List all open PRs in this repo (morning orientation, coordinating reviews) |
| `prefix y` | Hint-based copy — overlay letter hints on every URL/path/SHA in the pane, type one, it's in your clipboard |
| `prefix [` | Enter copy mode — `v` selects, `y` copies to macOS clipboard |
| `prefix C-s` / `prefix C-r` | Manually save / restore the resurrect snapshot |
| `prefix R` | Reload `~/.tmux.conf` after edits |

---

## Mental model

Tmux nests in three layers. Knowing which layer you're at tells you which command applies.

```
session  ── one per project / context (e.g. "apophis", "main")
  └── window  ── one per task within a session (a Linear ticket, a worktree)
        └── pane  ── one shell within a window (claude top, two zsh splits below)
```

- **Session** is the durable thing — that's what continuum saves and what you reattach to.
- **Window** is your task switcher inside a session — `prefix space` cycles them.
- **Pane** is just a split — claude-agent gives you one window with three panes (claude on top, two zsh splits below).

`tmux.start.sh` (called by Ghostty) attaches you to the most-recently-used **unattached** session, so opening a second Ghostty window gives you a different session by default — no nesting, no clobbering.

---

## Sessions, windows, panes — navigation

**When to reach for it:** every time you switch context or want to find something already running.

### Sessions

| Binding | Action |
|---|---|
| `prefix s` | Zoomed tree picker — sessions, windows, expandable. The big one. |
| `prefix (` / `prefix )` | Previous / next session (default tmux bindings, kept) |
| `prefix d` | Detach — leaves session running, drops you back to a plain shell |
| `tmux ls` (in a shell) | List sessions and which client is on which |
| `tmux a -t <name>` | Attach to a named session from outside |

`prefix d` is your "I'm done for now, but don't kill anything" exit. The session keeps running; reopen Ghostty (or `tmux a`) and you're back.

### Windows

| Binding | Action |
|---|---|
| `prefix c` | Create a new window (named after cwd basename via `automatic-rename`) |
| `prefix space` | Next window |
| `prefix bspace` | Previous window |
| `prefix t` | Next window (alias) |
| `prefix T` | Previous window (alias) |
| `prefix 0..9` | Jump to window by index |
| `prefix ,` | Rename current window |
| `prefix &` | Kill current window (asks confirmation) |
| `prefix a` | Last pane (toggles between two panes — like `cd -` for panes) |

Windows auto-renumber when you kill one in the middle (so `[1, 2, 3]` minus 2 becomes `[1, 2]`, not `[1, 3]`).

### Panes

| Binding | Action |
|---|---|
| `prefix h j k l` | Move left / down / up / right between panes |
| `prefix q` | Flash pane numbers (then press the number to jump) |
| `prefix z` | Zoom current pane to fullscreen — same key toggles back |
| `prefix x` | Kill current pane |
| `prefix C-o` | Rotate panes within current layout |
| `prefix +` / `prefix =` | Apply main-horizontal / main-vertical preset layout |
| `prefix Enter` | Cycle through preset layouts |

`prefix z` (zoom) is the one you'll use the most — when you want a single pane fullscreen for a moment without rearranging anything. The pane title gets a `Z` marker while zoomed.

---

## Splits & pane layout

**When to reach for it:** any time you'd open a new terminal window for a related task. Split instead — same cwd, same session.

| Binding | Action |
|---|---|
| `prefix \` | Vertical split (new pane to the right) — inherits cwd |
| `prefix -` | Horizontal split (new pane below) — inherits cwd |

Both bindings are configured with `-c "#{pane_current_path}"`, so the new pane starts in the same directory the source pane was in. No `cd` needed.

**Resize a pane:** hold `prefix`, then arrow keys (each press resizes by 1 cell — repeat-time is 0 so you have to re-prefix each time, by design, to avoid accidental resize spam).

For preset layouts, `prefix +` (main pane on top) and `prefix =` (main pane on left) are quick reshuffles. `other-pane-height 25` and `other-pane-width 80` define the secondary panes' sizes.

---

## Claude-agent — `prefix A`

**When to reach for it:** any time you'd start a new Claude session on a Linear ticket, or resume one. This is the workflow for parallel agents per the stacked-slice rules.

### What it does

`prefix A` opens an fzf picker over your branches (sorted by commit recency). You can:
- Fuzzy-match an existing branch and press Enter → resume on it
- Type a brand-new label and press Enter → create a new branch from `origin/master`

Behind the scenes:
1. **Auto-cleans** stale worktrees first (background fetch+prune; removes worktrees whose upstream is `[gone]` AND that have no uncommitted changes — never touches the main checkout)
2. **Resolves** the label to a branch (local match → remote-only match → new branch)
3. **Creates** a worktree at `~/Worktrees/<repo>/<label>` (path is `$WORKTREES_DIR` from `~/.config/dotfiles/local.env`, default `$HOME/Worktrees`; idempotent — reuses if it exists)
4. **Spawns** a tmux window in the repo's session with three panes: `claude` running on top, two zsh splits below
5. **Switches** the current client to it

### Usage

```
prefix A
  └── fzf picker pops up
       ├── ↵ on existing branch → resume there
       └── type "rec-330-foo" + ↵ → new worktree + branch from origin/master
```

The fzf picker is `claude-agent-pick`. The launcher (`claude-agent-launcher`) bridges it to `claude-agent` outside the popup so `tmux switch-client` propagates correctly.

### Window naming

Window names are the label, with `rec-` / `REC-` collapsed to `r` and capped at 24 chars. So `rec-283-slice-6-worker-audit` becomes `r283-slice-6-worker-audi`. Keeps the status bar readable when you have several agents running.

### Edge cases handled

- **Branch already checked out somewhere** (e.g. main checkout): redirects to that location instead of trying to make a duplicate worktree
- **Case-insensitive APFS**: normalizes label casing so you don't shadow an existing dir
- **No git repo at cwd**: picker falls back to a repo picker over `$REPOS_DIR` (configured in `~/.config/dotfiles/local.env`, default `$HOME/Github`)
- **Window already exists for this label**: just switches to it — full idempotent re-spawn

### Direct CLI use

You can also invoke from a shell:

```bash
claude-agent rec-300-some-ticket                    # uses cwd's repo
claude-agent rec-300-some-ticket ~/Github/apophis   # explicit repo path
```

---

## The "Claude needs input" indicator

**When to reach for it:** when you have multiple windows open and Claude finishes thinking in one that isn't the one you're looking at — you want to know which one without alt-tabbing through everything.

### How it shows up

Two layers, both honoring focus:

1. **Per-window dot in the window list** — only on windows you're not currently viewing. Fires from Claude's `Notification` hook (the "I need input" event).
2. **Cross-session badge in `status-right`** — shows `● <session_name>` when any window in a different session is waiting. So if you're in the `main` session and Claude pings you in `apophis`, you see `● apophis` on the right.

When you actually navigate to the window — via `prefix space`, `prefix s`, switch-client, or any pane select — the flag clears automatically. Three tmux hooks cover this:

```
after-select-window     → clear @claude-needs-input
after-select-pane       → clear @claude-needs-input
client-session-changed  → clear @claude-needs-input
```

This is the "focus-aware" part: tmux has no "pane-focus-in" hook, so this trio is the equivalent.

### Critical edge case

The `Notification` hook itself **also** checks viewing state at fire-time. If you're already staring at the prompt when Claude calls for input, the flag never gets set. Without that check, the dot would briefly appear and the auto-clear hooks wouldn't fire (you didn't navigate — you were already there), so the dot would stick.

### Sound cues

- `Notification` fires `Pop.aiff` (the "I need input" sound)
- `Stop` fires `Tink.aiff` (the "I'm done with this turn" sound)

Both play unconditionally — that's still a useful cross-app signal even when you're already viewing the pane.

### Files

- `~/.claude/hooks/notification.sh` — sets the flag
- `~/.claude/hooks/stop.sh` — clears the flag and refreshes status
- `~/.tmux.conf` lines 123–130 (auto-clear hooks)
- `~/.tmux.conf` line 177 (`status-right` with the cross-session badge)

### Don't trust `Stop` alone

The `Stop` hook fires per turn, but real-world failure modes (Claude crashes, hook race, tmux refresh timing) mean the flag can persist incorrectly. The auto-clear hooks on navigation are the safety net — they fire on every `select-window`/`select-pane`/`switch-client`, so the flag never outlives your attention.

---

## Popups — `prefix G`, `prefix F`, `prefix P`

**When to reach for it:** when you want to run a quick command without giving up your pane layout. Popups are floating windows that close when you exit them.

### `prefix G` — generic shell popup

```
prefix G  →  85% × 75% popup, $SHELL at the active pane's cwd
```

Use it for ad-hoc commands you'd otherwise need a new pane for:

```bash
git log --oneline -20
gst
ll
```

Type `exit` (or `Ctrl+D`) to close. Nothing gets persisted — popups are ephemeral.

### `prefix F` — current branch focus ("is my thing ready to merge?")

```
prefix F  →  90% × 80% popup, runs:
              gh pr view              # title, state, mergeability, URL — for THIS branch's PR
              gh pr checks            # CI checks rolled up with ✓/✗ per check
              git status -sb          # local uncommitted state
              | less -R               # ← scrollable pager; q to quit
```

Single keystroke answer to "what's the state of *my* PR?" — checks status, review decision, local diff. If there's no PR yet for the current branch, you get `No PR for the current branch yet.` instead of an error.

### `prefix P` — repo-wide PR overview

```
prefix P  →  90% × 80% popup, runs:
              gh pr list              # every open PR in this repo
              | less -R               # ← scrollable pager; q to quit
```

Different intent than `prefix F`. Reach for `P` when you want:

- **Morning orientation** — "what is the team shipping right now? what landed overnight?"
- **Pre-rebase check** — "did anyone's PR land that I should pull before I rebase?"
- **Coordinating reviews** — "whose PR is sitting unreviewed?"
- **Pre-branch check** — "before I start a new branch, has someone already opened a PR for this?"

`F` is "my thing", `P` is "the team's things".

### Scrolling inside the F / P popup

Both popups pipe their output through `less -R`, which gives you full vim-like navigation. Output longer than the popup height is scrollable instead of cut off:

| Key | Action |
|---|---|
| `j` / `k` | Down / up one line |
| `d` / `u` | Down / up half a screen |
| `f` / `b` (or `space` / `b`) | Forward / back a full screen |
| `g` / `G` | Top / bottom |
| `/pattern` then `n` / `N` | Search forward, repeat / repeat-back |
| Trackpad / mouse wheel | Scroll (requires `less --mouse`, set in the binding) |
| `q` | Quit less → popup closes |

Three flags in the `less` invocation, each load-bearing:

- `-R` preserves `gh`'s ANSI color codes through the pipe.
- `--mouse` enables wheel/trackpad scrolling. Without this, `less` ignores mouse events even though tmux's global `mouse on` forwards them. Requires less ≥ 530; macOS Sequoia ships less 668. If you ever see no scroll, run `less --version` first.

Two env vars complete the setup:

- `GH_FORCE_TTY=1` keeps `gh`'s color output through the pipe (otherwise `gh` strips color when stdout is a pipe).
- `GH_PAGER=cat` disables `gh`'s own pager so we don't get less-inside-less.

If wheel scrolls feel too slow, append `--wheel-lines=3` to taste.

### Selecting and copying text inside the F / P popup

Because `less --mouse` is capturing wheel + click events, plain click-drag doesn't select text — `less` consumes the events. Two ways out:

1. **`Shift` + click-drag** — Ghostty's bypass modifier. The terminal emulator sees the Shift-modified drag and treats it as native text selection, ignoring the app's mouse capture. Then `Cmd+C` copies. This is the right answer 95% of the time. (Note: `Option` is **not** the modifier in Ghostty — it's typically used for window/text-input behaviors, so Option+drag will move the popup or do something unexpected. Other terminals like iTerm2 use Option; Ghostty uses Shift.)
2. **Toggle less's mouse mode at runtime** — inside less, press `-` then type `--mouse` then `Enter`. Mouse mode flips off; click-drag now selects natively. Repeat to re-enable wheel scroll. Worth knowing for long sessions where you want to drag-select multiple times.

> **Gotcha:** `prefix y` (thumbs) does **not** reach popup content — it captures the underlying pane, not the overlay. If a SHA / URL / path is visible only inside the F or P popup and you want it on your clipboard, use Option+drag → Cmd+C right there, or close the popup and re-run the underlying command in a regular pane (where thumbs can hint it).

---

## Thumbs — `prefix y` hint-based copy

**When to reach for it:** any time you want to copy a single token from terminal output — a SHA, a file path, a URL, an IP, a UUID, a number, an error line — without reaching for the trackpad or scrolling through copy mode. This is the 80% case for "I want that thing on my clipboard."

### How it flows

1. `prefix y` on a pane that has output you care about.
2. The pane content reflows into a fullscreen popup. Every grabbable token gets a `[hint]` letter overlay (square brackets for visibility against any background).
3. Type the hint letter (or letters, for two-key hints).
4. Popup closes. The token is in your **macOS clipboard** (via `pbcopy`).
5. `Cmd+V` anywhere — Cursor, Slack, browser, Linear, the next shell command. The status bar flashes `thumbs → clipboard: <preview>` for 1.5s as confirmation.

`Esc` or `Ctrl+C` cancels — no clipboard change, no flash.

### What gets hinted

thumbs has built-in regex for the common stuff:

| Pattern | Example |
|---|---|
| URLs | `https://linear.app/recovry/issue/REC-283` |
| File paths (with line numbers too) | `apps/bff/src/routers/chat.ts:42` |
| Git SHAs (short and full 40-char) | `a3f9c81` |
| UUIDs | `01961e1a-a167-0000-60dd-05aa87aa41d6` |
| IPv4 / IPv6 | `192.168.1.5`, `::1` |
| Hex colors | `#ffd866` |
| Numbers | `100000`, `0.05` |
| Markdown links | `[label](url)` — picks the URL |
| Email addresses | `pkakkar@recovry.ai` |
| Quoted strings, docker container IDs, k8s resource names | … |

If two patterns overlap (e.g. a path nested inside a URL), thumbs picks the longer match.

### Hint key system

- Single letter for the first ~26 matches — home-row first, so the closest tokens are easiest to type.
- After ~26, hints become two-letter (`aa`, `as`, `ad`, …). Type both keys; thumbs filters as you type.
- The `-c` flag in the wrapper renders hints in `[brackets]` for legibility against arbitrary background colors.

### Files

- `~/.local/bin/thumbs` — the binary (v0.8.0, x86_64-apple-darwin running via Rosetta 2 on Apple Silicon)
- `~/.local/bin/tmux-thumbs-pick` — the wrapper that captures the calling pane, opens the popup, copies the result
- `~/.tmux.conf` (in the popup-bindings block) — `bind-key y run-shell "$HOME/.local/bin/tmux-thumbs-pick #{pane_id}"`

### Two gotchas worth remembering

If you ever rebuild this from scratch — or it breaks after an OS / tmux upgrade — these are the load-bearing quirks. Both are documented in comments inside the wrapper, but worth knowing here too:

1. **PATH inside `display-popup -E`** — tmux runs popup commands via a non-interactive shell that does **not** source `~/.zshrc`. So `~/.local/bin` is absent from `$PATH` inside popups, and a bare `thumbs` resolves to nothing (exit 127). The wrapper hardcodes `$HOME/.local/bin/thumbs` for this reason.
2. **Don't redirect thumbs' stdout** — v0.8.0 queries terminal size via `ioctl` on **stdout**. If stdout is a redirected file (`> $RESULT`), the ioctl returns `Inappropriate ioctl for device` and thumbs panics instantly (the popup blinks and closes). Use thumbs' `-t <path>` flag to write the picked hint to a file instead — that keeps stdout pointing at the popup TTY where the ioctl succeeds.

### Reinstalling from scratch

No homebrew formula exists. The 0.8.0 release ships only an x86_64 binary, which runs fine on Apple Silicon via Rosetta (sub-second tool, you won't notice).

```bash
curl -sL -o /tmp/thumbs.zip \
  "https://github.com/fcsonline/tmux-thumbs/releases/download/0.8.0/tmux-thumbs_0.8.0_x86_64-apple-darwin.zip"
unzip -q /tmp/thumbs.zip -d /tmp/
mkdir -p ~/.local/bin
mv /tmp/thumbs ~/.local/bin/thumbs
chmod +x ~/.local/bin/thumbs
~/.local/bin/thumbs --version    # → thumbs 0.8.0
```

If Rosetta isn't installed (rare on a daily-driver Mac), you'll get an error on first run. Fix:

```bash
softwareupdate --install-rosetta --agree-to-license
```

### Adding custom patterns

thumbs only hints what its built-in regexes match. To add a custom pattern (e.g. Linear ticket IDs, which are useful enough to warrant their own hint), edit the wrapper and append `-x '<regex>'`:

```bash
"'$THUMBS_BIN' -c -x 'REC-\d+' -t '$RESULT' < '$CAPTURE'"
```

`-x` can be repeated for multiple patterns.

### Thumbs vs copy mode

- **Thumbs**: one specific token, on screen now, regex-matchable. One keystroke. The 80% case.
- **Copy mode**: an arbitrary range, possibly a multi-line block, possibly something not regex-matchable, possibly in scrollback rather than visible. Reach for it when thumbs doesn't have a hint over what you want.

---

## Copy mode (vi-style)

**When to reach for it:** copying output from a pane (compile errors, log lines, command output) into the system clipboard.

### Enter

```
prefix [
```

You're now in copy mode. Cursor moves with vim keys.

### Move and select

| Key | Action |
|---|---|
| `h j k l` | Move cursor |
| `w` / `b` | Word forward / back |
| `0` / `$` | Start / end of line |
| `g` / `G` | Top / bottom of scrollback |
| `/` / `?` | Search forward / backward |
| `n` / `N` | Repeat search |
| `v` | Begin selection |
| `V` | Begin line-selection |
| `y` or `Enter` | Copy selection to **macOS clipboard** and exit |
| `q` | Exit without copying |

### Mouse mode is on

You can also drag-select with the trackpad — release copies (via the pipe to `pbcopy`).

### Paste

```
prefix ]   → paste tmux's most recent buffer
Cmd+V      → paste system clipboard (the y-piped one)
```

For most cases, just use `Cmd+V` — your `y` already shipped it to macOS.

---

## Resurrect & continuum — session persistence

**When to reach for it:** every time Ghostty quits, your Mac reboots, or you kill the tmux server. Without these, every restart is a fresh start.

### What's running

- **tmux-resurrect**: saves a snapshot of all sessions/windows/panes (cwds, layouts, command lines, scrollback) to a text file. Manual save with `prefix C-s`, manual restore with `prefix C-r`.
- **tmux-continuum**: calls resurrect's save script every **15 minutes**, and on tmux server boot it auto-restores from `last`.

Both are loaded via TPM (`~/.tmux/plugins/tpm`).

### Where saves actually live

```
~/.local/share/tmux/resurrect/
├── last → tmux_resurrect_<latest>.txt   (symlink to most recent)
├── pane_contents.tar.gz                  (scrollback for each pane)
├── tmux_resurrect_20260508T112128.txt
├── tmux_resurrect_20260508T124623.txt
├── ...                                    (one per save — every 15 min)
└── restore/, save/                       (scratch dirs for in-flight ops)
```

> **Path gotcha:** older docs and plenty of internet posts say `~/.tmux/resurrect/`. Ignore them. Modern resurrect honors XDG, so the real path is `~/.local/share/tmux/resurrect/`. Always use the XDG path.

### Daily commands

| Binding / command | Action |
|---|---|
| `prefix C-s` | Manual save right now |
| `prefix C-r` | Manual restore from `last` |
| `cat ~/.local/share/tmux/resurrect/last \| head -40` | Inspect what would come back |
| `ls -lt ~/.local/share/tmux/resurrect/` | See save cadence — should be ~every 15 min |
| `tmux show-options -g @continuum-save-last-timestamp` | Epoch seconds of last auto-save |

### What survives a restore

| Survives | Doesn't survive |
|---|---|
| Sessions, windows, pane layouts | Long-running processes (vim, dev servers, **claude itself**) |
| Pane working directories | TTY state of those processes |
| Window names (including claude-agent labels) | Unsaved changes in editors |
| Pane scrollback (because `@resurrect-capture-pane-contents 'on'`) | In-flight network connections, ssh sessions |

After a restore you'll see your old prompts and scrollback in each pane — but you're at a fresh shell. You'll need to rerun `claude`, `npm run dev`, etc.

### What forces auto-restore on boot

`@continuum-restore 'on'` registers a hook that fires when the tmux server starts. `tmux.start.sh` (the Ghostty entrypoint) deliberately starts a `_bootstrap` placeholder session first so the server boots — that's what triggers continuum's restore. Once it sees more than one session (i.e. continuum restored something), it kills the placeholder.

### Manual save before risky operations

```bash
prefix C-s                            # save now
# or from a shell:
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
```

Useful before: rebooting, killing the tmux server intentionally, or any "I want a known-good restore point" moment.

---

## Ghostty boot flow

**When to reach for it:** understanding why opening Ghostty already drops you into your old layout. Or debugging when it doesn't.

`~/.config/tmux/tmux.start.sh` is wired into Ghostty's `command` config. On every Ghostty window open:

1. **If we're already in tmux** (`$TMUX` set), do nothing — never nest.
2. **If no tmux server is running**, start a `_bootstrap` placeholder session, sleep 1 sec to let continuum's auto-restore hook fire, then kill the placeholder if continuum restored real sessions (or rename it to `main` if there was nothing to restore).
3. **Pick a target**: most-recently-used **unattached** session first, falling back to most-recent overall, falling back to a fresh `main`.
4. **Attach** to that target.

The "unattached first" logic means a second Ghostty window gives you a different session — useful when you want side-by-side views of two contexts.

---

## Status bar — what each glyph means

Reading the status bar from left to right:

```
 main │  rec-283-slice-6   r320-route-staging-bui     ● apophis  17:43:22  08-May-26
└─┬──┘ └─────────┬──────┘ └────────────┬─────────┘ └────┬─────┘ └──┬───┘ └────┬────┘
  1              2                     3                4          5          6
```

1. **Session name** — green/bold — which session you're attached to
2. **Active window** — themed differently from the others
3. **Other windows** — name only (no index unless `@claude-needs-input` is set on it)
4. **Cross-session pending flag** — `● <session_name>` when a different session has a window waiting on Claude. Only renders when something's pending; absent otherwise.
5. **Clock** — HH:MM:SS, ticks every 5 seconds (status-interval)
6. **Date** — DD-Mon-YY

Activity indicators on inactive windows: yellow if there's been activity, bold red if a bell fired. (`monitor-activity` is on, but `visual-activity` is off so you don't get a flash on every keystroke.)

---

## Real-world workflows

### Starting a new Linear ticket

```
prefix A                          # fzf picker
type "rec-330-fix-auth-bug" + ↵   # creates worktree, branch, window, claude
# claude pane runs claude immediately; bottom panes are zsh in the worktree
```

If the branch already exists on `origin` (e.g. you're picking up someone else's work), the picker shows it — Enter creates a tracking local branch.

### Resuming yesterday's agent

```
prefix s                          # session/window tree picker
                                  # find the window labeled with your ticket
↵                                 # jump to it
```

Or if you remember the branch name:

```
prefix A
type "rec-283"
                                  # picker fuzzy-matches existing branches
↵                                 # claude-agent reuses the existing worktree + window
```

The auto-cleanup runs on every `prefix A`, so resuming also tidies up merged branches in the background.

### Quick PR check without leaving claude

```
prefix F                          # YOUR branch's PR + CI checks + git status
any key                           # close, back to claude pane
```

Want the team-wide view instead?

```
prefix P                          # every open PR in the repo
```

### Grabbing a SHA / path / URL out of any pane

You ran `git log --oneline -10` and want to revert one of the commits. Or claude printed a path you want to open in Cursor (`Cmd+P` → paste). Or `gh pr list --json url -q '.[].url'` printed URLs you want to drop in Slack.

```
prefix y                          # popup overlays [hint]s on every grabbable token
type the hint letter              # token → clipboard, popup closes
Cmd+V                             # anywhere — Cursor, Slack, browser, next shell
```

Faster than copy mode for the common case where you want one specific token, not a multi-line range.

### Multiple worktrees in parallel within ONE slice

The stacked-slice rule says: max 2 worktrees, parallel agents only for **independent subtasks within one slice**. So:

```
prefix A → "rec-283-slice-6-worker-audit"     # main work
prefix A → "rec-283-slice-6-test-fixtures"    # parallel independent subtask
```

Each gets its own window in the `apophis` session. `prefix space` cycles between them. The `● apophis` indicator surfaces if either pings you while you're elsewhere.

### Recovering from "Ghostty just quit"

Just open Ghostty again. `tmux.start.sh` boots the server, continuum restores, you're back in your layout. Re-run `claude` in the panes that had it (and any dev servers you had going).

If the auto-restore didn't fire for some reason:

```
prefix C-r                        # manual restore from `last`
```

### Inspecting what would restore before a risky reboot

```bash
cat ~/.local/share/tmux/resurrect/last | head -40
```

You'll see one line per session/window/pane with the cwd and the command that was running. If it looks complete, reboot freely.

### Bumping a config and reloading without losing anything

```
# edit ~/.tmux.conf
prefix R                          # source-file ~/.tmux.conf — flashes confirmation
```

No detach, no kill. The config replays on top of the running server.

---

## Troubleshooting & rollback

### Indicator (yellow dot / `● session`) won't go away

Manually clear and refresh:

```
prefix space                      # any window switch will clear it via the hook
```

If that doesn't work, the flag is stuck on a window you can't reach without re-triggering. Nuke it from a shell:

```bash
tmux set-option -wqu -t apophis:1 @claude-needs-input
tmux refresh-client -S
```

Replace `apophis:1` with the right `session:window`.

### Resurrect saves directory looks empty

You're probably looking at the wrong path. Real path is XDG:

```bash
ls -lt ~/.local/share/tmux/resurrect/
```

If THAT's empty, force a save:

```
prefix C-s                        # should flash "Tmux environment saved!"
```

If even manual save fails, check that TPM loaded the plugin:

```bash
ls ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
```

Missing? Run TPM install: `prefix I` (capital i).

### Continuum stopped auto-saving

Check the timestamp:

```bash
tmux show-options -g @continuum-save-last-timestamp
```

If that hasn't moved in >20 minutes, the hook is broken. Reload config:

```
prefix R
```

### Restore on Ghostty boot didn't fire

Confirm Ghostty actually runs `tmux.start.sh` — check Ghostty config:

```bash
grep -i command ~/.config/ghostty/config 2>/dev/null
```

Should reference `~/.config/tmux/tmux.start.sh`.

Also confirm `@continuum-restore` is on:

```bash
tmux show-options -g @continuum-restore
```

Should print `@continuum-restore on`. If not, the line in `~/.tmux.conf` got commented out — re-enable, `prefix R`.

### Claude-agent picker errors

The launcher writes errors to a temp file and surfaces them via `tmux display-message`. If you see "claude-agent-pick error: ..." for ~4 seconds, that's the picker's stderr.

Common causes:
- Not in a git repo and `$REPOS_DIR` has no `.git` dirs at depth 2 — check `~/.config/dotfiles/local.env` has the right `REPOS_DIR` value
- `fzf` not on PATH inside the popup (rare — the popup inherits Ghostty's env)

Run the picker manually to debug:

```bash
~/.local/bin/claude-agent-pick "$PWD"
```

### Claude-agent created a worktree where one already existed

It shouldn't (idempotent re-spawn handles this). If it did, you probably hit case-insensitive APFS shadowing — labels differing only in case map to the same dir. Check:

```bash
ls ~/Worktrees/<repo>/
git -C ~/Github/<repo> worktree list
```

Cleanup:

```bash
git -C ~/Github/<repo> worktree remove <path> --force
git -C ~/Github/<repo> branch -D <branch>
```

### Thumbs popup blinks and disappears (or `prefix y` errors)

Three known failure modes, in order of likelihood:

**1. Tmux flashes `… returned 127`** → the wrapper or `thumbs` itself isn't found. Verify:

```bash
ls -l ~/.local/bin/tmux-thumbs-pick ~/.local/bin/thumbs
```

If `thumbs` is missing, reinstall (see the Thumbs section's "Reinstalling from scratch"). If the wrapper is missing, restore from git/dotfiles or rewrite it from the cheatsheet.

If both exist but you still see 127: the wrapper is calling bare `thumbs` somewhere instead of `$THUMBS_BIN`. The `display-popup` popup shell doesn't have `~/.local/bin` on PATH. Use the absolute path.

**2. Popup opens for a fraction of a second then closes silently** → the ioctl panic. Reproduce out-of-band to see the error:

```bash
echo 'visit https://example.com sha 3a8f1c2' > /tmp/cap
tmux display-popup -E -w 100% -h 100% \
  "$HOME/.local/bin/thumbs -c -t /tmp/res < /tmp/cap 2>/tmp/err"
cat /tmp/err
```

If you see `Inappropriate ioctl for device`, the wrapper is redirecting stdout instead of using thumbs' `-t` flag. Don't change that — see the Thumbs section's gotchas.

**3. Popup opens fine but no hints appear** → captured pane has nothing matching thumbs' default patterns. Either there's genuinely nothing to grab, or you want a custom pattern: add `-x '<regex>'` to the thumbs invocation in the wrapper.

### Roll back the tmux config

The plan didn't write a `.bak` of the original `.tmux.conf` (it was a near-total rewrite). If you need to disable a specific binding to see if it's the culprit, comment it out and `prefix R`.

To bypass tmux entirely for a session: launch Ghostty, then in the new shell:

```bash
tmux kill-server                  # nukes everything
                                  # next Ghostty open will reboot tmux fresh
                                  # (continuum will restore — kill-server doesn't wipe saves)
```

To start without auto-restore (clean slate):

```bash
tmux kill-server
sed -i '' "s/@continuum-restore 'on'/@continuum-restore 'off'/" ~/.tmux.conf
# open Ghostty — fresh main session
# revert when ready: same sed swapping 'off' back to 'on'
```

---

## Quick learning path

If you want to phase the integration over a couple of weeks:

- **Day 1:** `prefix space` / `prefix bspace` for window cycling. `prefix s` for the tree picker. These two replace 80% of "where was that thing".
- **Day 2:** `prefix h j k l` for pane nav, `prefix \` and `prefix -` for splits. Stop opening new Ghostty windows for related work.
- **Day 3:** `prefix A` for the next Linear ticket. Use the picker, let it create the worktree. Resume with the picker tomorrow.
- **Day 4:** `prefix y` for thumbs. Pick one terminal session a day and force yourself to grab SHAs / paths / URLs via hints instead of the trackpad. Two days in, copy mode usage drops by 80%.
- **Day 5:** `prefix [` for copy mode — practice `v` / `y`. Use it for the cases thumbs doesn't cover (multi-line ranges, scrollback search).
- **Day 6:** `prefix G` and `prefix F` popups. Notice when you're about to split a pane just to run `gh pr list` — popup it instead.
- **Day 7:** `prefix z` (zoom). When you want one pane fullscreen for a moment, zoom instead of restructuring.
- **Day 8:** Trust resurrect. Reboot deliberately, watch your layout come back. The first time it works, you'll feel it.
- **Day 9:** Multi-window discipline. Run two claude-agents in one session for independent subtasks; let `● <session>` tell you when the other one needs you.
- **Day 10:** `prefix d` for clean exits. Stop closing Ghostty when you're done — detach, attach later.
- **Day 11:** `prefix C-s` before anything you suspect is risky. Manual save is your "git stash" for tmux state.

After two weeks of this you'll stop thinking about tmux at all — which is the goal. The bindings that don't fit your work will fade naturally.
