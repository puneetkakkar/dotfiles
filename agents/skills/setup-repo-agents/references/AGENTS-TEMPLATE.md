# AGENTS.md template

Every agent reads the repo's `AGENTS.md` on top of the user's global
instructions, every session. Each line costs context, so keep only what an
agent would get wrong without it. Skip any section the repo has nothing for.

```markdown
# <Project name>

<One or two sentences: what it is, who uses it.>

## Stack

- <framework, language, datastore, notable libraries: one line each>

## Commands

    <install>
    <dev server, with port>
    <typecheck>
    <lint>
    <test>

Run <typecheck> and <lint> before declaring work done.

## Layout

- `<dir>/`: <what lives here, only where the name does not say it>

## Rules

- **MUST** <a rule an agent would otherwise break>.
- **NEVER** <a rule an agent would otherwise break>.

## Workflow

<Branching, commit format, PR requirements, CI gates. Point to the full
policy doc instead of copying it.>

## Reference

- `docs/agents/<topic>.md`: <when to read it>
```

Guidance:

- **Rules are testable.** "MUST call `requireAdmin()` in admin routes" beats
  "be careful with auth". MUST/NEVER rules are review blockers; everything else
  is advice.
- **Point, don't paste.** Link long policies, schemas and checklists from
  `docs/agents/`. Agents load them only when the pointer's condition applies.
- **Nested files override.** Put a package-specific `AGENTS.md` in that
  package only when its commands or rules differ from the root.
- **No personal or machine data.** No key fingerprints, home paths, tokens or
  email addresses; those belong in the user's global or machine-local config.
