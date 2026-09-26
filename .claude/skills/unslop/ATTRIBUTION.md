# Attribution

`SKILL.md` is the `unslop` skill from the pstack plugin, copied unmodified.

- Source: https://github.com/cursor/plugins/tree/70b2dc8b4/pstack/skills/unslop
- Author: Lauren Tan (poteto)
- License: MIT (see LICENSE)

## Invocation

Upstream sets `disable-model-invocation: true`, so the skill runs only when
the user types `/unslop`. That is kept. The global `CLAUDE.md` covers
everyday prose style and names `/unslop` as the deliberate deeper pass, so
letting the model fire it on every piece of writing would duplicate that and
cost context. An earlier local copy removed the line; that edit is reverted.

Rule numbers are stable ids that other pstack skills cite by number, so do not
renumber or delete rules.
