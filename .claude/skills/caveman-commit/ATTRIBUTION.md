# Attribution

`SKILL.md` and `README.md` are the `caveman-commit` skill from the caveman
project, copied unmodified.

- Source: https://github.com/JuliusBrussee/caveman/tree/2fd153c67988e980fb0b2455c90832159a6a5a25/skills/caveman-commit
- Author: Julius Brussee
- License: MIT (see LICENSE). The repo is split-licensed. Skills fall under
  the MIT part; only the engine-linked runtime directories are BSL-1.1.

## Why vendored

The global `CLAUDE.md` applies these rules to every commit and cites the skill
at `~/.claude/skills/caveman-commit`. The caveman plugin that used to supply it
was removed in 81fd085, so the skill lives here and bootstrap links it.

## Known tension

The skill's Boundaries section says it only writes the message and never runs
`git commit`. That fits the `/caveman-commit` command. When Claude commits on
the user's request, `CLAUDE.md` governs and the skill supplies only the message
rules.
