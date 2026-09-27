---
name: setup-repo-agents
description: Set up or migrate a repo's agent instructions and skills so Claude Code, Codex and other agents share one AGENTS.md and one .agents/skills.
disable-model-invocation: true
---

# Set up repo agents

Give a repo one agent-neutral setup that every coding agent reads, layered on top of the user's global setup:

```
AGENTS.md                              # repo instructions; Claude reads it natively when no CLAUDE.md exists
<package>/AGENTS.md                    # only where a package needs different commands or rules
.agents/skills/<repo-prefixed-name>/   # skills this repo owns
.claude/skills -> ../.agents/skills    # Claude Code reads only .claude/skills
docs/agents/                           # longer reference that AGENTS.md points to
```

This is a prompt-driven skill: explore, present, confirm, then write. Never write before the user confirms.

## 1. Explore

Read, don't assume:

- Instruction files: `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.cursor/rules/`, `.github/copilot-instructions.md`, and any nested ones.
- Agent-specific skills and commands: `.claude/commands/`, `.claude/agents/`, `.claude/skills/`, `.cursor/skills/`, `.codex/skills/`, `.agents/skills/`.
- `.claude/settings.json` hooks and permissions.
- What the repo already says about itself: package scripts, Makefile, CI workflows, README, `CONTRIBUTING.md`, `docs/`.
- Run `scripts/check-repo.py <repo>` from this skill's folder for the current state.

## 2. Present and confirm

Show the user, in one message:

- The files you will create, move or delete.
- For every existing command, subagent or skill: where its content goes. Legacy content is migrated, never dropped silently. Use the table below.
- The `AGENTS.md` outline.

Wait for confirmation. Apply their edits.

| Existing content | Goes to |
|---|---|
| Always-on facts: stack, commands, layout, MUST/NEVER rules | `AGENTS.md`, under 200 lines |
| Long reference: full policies, checklists, schemas | `docs/agents/<topic>.md`, one line in `AGENTS.md` pointing to it |
| A repeatable procedure only this repo needs | a repo skill in `.agents/skills/` |
| A procedure a global skill already covers (grilling, review, TDD, debugging, PRs) | nothing new; put the repo-specific inputs in `AGENTS.md` or `docs/agents/`, where that global skill reads them |
| A template the workflow or CI needs | a file in the repo, e.g. `docs/plans/TEMPLATE.md` |
| A secret, key fingerprint or machine path | removed |

## 3. Write

1. **`AGENTS.md`.** Follow [references/AGENTS-TEMPLATE.md](references/AGENTS-TEMPLATE.md). Keep it under 200 lines and 32 KiB. Write only what the repo adds on top of the user's global instructions; never restate or contradict them.
2. **`CLAUDE.md`.** Delete it once its content has moved into `AGENTS.md`. If something must stay Claude-only, keep a `CLAUDE.md` whose first line is `@AGENTS.md`.
3. **Repo skills.** Create each in `.agents/skills/<name>/`:
   - Prefix the name with the repo or domain (`hovr-security-review`, not `security-review`). A repo skill with a global skill's name is shadowed in Claude.
   - Follow the Agent Skills spec: lowercase-hyphenated `name` matching the folder, `description` saying what it does and when to use it.
   - Decide who invokes it. Manual skills set `disable-model-invocation: true` in `SKILL.md` **and** `policy: {allow_implicit_invocation: false}` in `agents/openai.yaml`. Model-invoked skills set neither.
   - To reuse another skill, write `Call the Skill tool with "<name>"`; the target must be model-invoked.
4. **Claude link.** `ln -s ../.agents/skills .claude/skills`.
5. **Delete the legacy files** whose content you moved.
6. **Check.** Run `scripts/check-repo.py <repo>` and fix every FAIL.

## 4. Offer the per-repo generators

Tell the user these exist; they run them, since a manual skill cannot start another:

- `/setup-matt-pocock-skills`: issue tracker, triage labels and domain doc layout that `code-review`, `diagnosing-bugs` and `tdd` read.
- `/create-verification-skill`: a `verify-<app>` skill that drives the running app to prove behaviour.

**Reply:** what moved where, the check result, and which generators are worth running next.
