# Attribution and local edits

Every skill in `skills/` is vendored from an MIT-licensed upstream. Licences
are in `licenses/`. `skills.lock.json` pins each skill to its upstream repo,
path and commit, and carries a one-line `localEdit` note for each skill that
differs from that commit.

| source | skills | licence |
|---|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | 18 | `licenses/mattpocock-skills.LICENSE` |
| [cursor/plugins pstack](https://github.com/cursor/plugins/tree/main/pstack) | 5 | `licenses/pstack.LICENSE` |
| [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) | `caveman-commit` | `licenses/caveman.LICENSE` (the skills part of a split MIT/BSL licence) |

## Additions that are not edits

- **`agents/openai.yaml`** on the pstack and caveman skills. Upstream ships
  none, and without one Codex invokes a skill implicitly even when Claude
  treats it as manual. Manual skills set `allow_implicit_invocation: false` to
  match `disable-model-invocation: true`, following the invocation convention
  mattpocock/skills documents in `.agents/invocation.md`.

## Local edits

### handoff

Upstream writes a handoff document but commits nothing, so uncommitted work
stays uncommitted when the session ends, and handoffs here usually accompany
switching laptops or worktrees. Adds a durability step first: stop at a safe
boundary, commit outstanding edits as one `wip:` commit staging named files,
take no irreversible action, and state what is on disk versus still in the
conversation. Adapted from pstack's `pause-safely` playbook.

### resolving-merge-conflicts

Step 5 staged everything and committed, which is `git add -A` behaviour, and a
conflicted tree is where stray untracked files collect. It now stages
conflicted files by name and halts on untracked `.env`, `*.key` or `*.pem`.
Step 3 said never `--abort`; it now allows aborting when the merge's premise is
wrong, after saying why.

### create-verification-skill

Upstream writes the generated skill to `.cursor/skills/verify-<app>/`, which
only Cursor reads. It now writes to `.agents/skills/verify-<app>/`, the project
skills dir most agents read, and tells the agent to add the `.claude/skills`
symlink Claude Code needs. Step 5 still points at `maintain-verification-skill`,
which is not vendored yet; vendor it with the same repath once a repo has a
verification skill worth maintaining.

### typescript-best-practices

Upstream sets both `paths` and `disable-model-invocation: true`. In pstack the
`poteto-mode` router reaches it, but standalone the Claude Code docs are
explicit that `disable-model-invocation` blocks `paths` auto-loading, so it
would never fire. The line is removed. Codex ignores `paths` and matches on the
description, which names `.ts`/`.tsx`.

Its first line, "Apply the **type-system-discipline** principle skill first",
was not followed in live tests: the model loaded this skill and skipped the
principle. It now reads `Call the Skill tool with
"principle-type-system-discipline" first.`, the phrasing mattpocock/skills
uses for operative dependencies because naming the tool gets it fired.

### principle-type-system-discipline

The TypeScript skill's first line is "Apply the type-system-discipline
principle skill first", and a manual skill cannot be called by another skill.
`disable-model-invocation` is replaced by `paths` for typed languages so it
loads on the same files, TypeScript and typed Python included.

## Known soft references

Prose mentions of skills that are not vendored, left as upstream wrote them
because nothing breaks: `blast-radius` names `why`, `arena` and `unslop`;
`typescript-best-practices` and `principle-type-system-discipline` name the
`boundary-discipline` and `encode-lessons-in-structure` principles.
`scripts/check-agents` enforces only operative dependencies.

## Updating

```bash
scripts/skills-upstream outdated   # what changed upstream since the pinned commit
# copy the new upstream folder over agents/skills/<name>, re-apply the edit above,
# bump the source commit in skills.lock.json, then:
scripts/skills-upstream diff       # every difference is a recorded edit
scripts/check-agents               # structure, invocation parity, links
```
