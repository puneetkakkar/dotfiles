# Attribution

`block-dangerous-git.sh` began as the script from Matt Pocock's
`git-guardrails-claude-code` skill.

- Source: https://github.com/mattpocock/skills (`skills/misc/git-guardrails-claude-code/`)
- License: MIT

That skill is **not** shipped in the `mattpocock-skills` plugin, which promotes
only the 25 `engineering/` and `productivity/` skills. Vendoring is the only way
to get it, so this copy is maintained locally.

## Local changes

- `git push` no longer blocks. Plain push adds commits and is reversible, and
  it is a routine request here. Force-push still blocks.
- Patterns are anchored with `[[:space:]]` instead of bare substrings, so
  `git log --grep="git push"` no longer trips the guard.
- Deduplicated `reset --hard`, which appeared twice.
- Added: `stash clear` / `stash drop`, `filter-branch`, `update-ref -d`,
  `reflog expire`, `gc --prune=now`, and `reset --merge`.

The rule behind the list: block what destroys uncommitted work or rewrites
published history. Allow what adds commits.
