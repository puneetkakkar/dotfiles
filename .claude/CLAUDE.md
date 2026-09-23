# Global preferences

## Engineering practice

- **Repeated manual work produces a file.** The third time you make the same edit, or whenever a throwaway analysis script is worth rerunning, write a committed script, codemod, or generator instead of doing it by hand again. If you cite this rule and there is no such file in the diff, you have not applied it.
- **Clean up only your own orphans.** Remove imports, variables, and functions that your change made unused. Do not delete pre-existing dead code unless asked — mention it instead.
- **Prefer a structural fix over a feedback memory.** When a correction recurs, first try to encode it where it cannot be forgotten: a lint rule, a hook, a test, or a CI check. Write a `feedback_*` memory only when no structural mechanism fits, and record in it why not.

## Git commits and PRs

- **No AI attribution anywhere.** Automatic attribution is disabled through the `attribution` setting; this rule covers what that setting cannot reach. Never write AI or Anthropic attribution into a commit message, PR title, or PR body by hand, and strip any "🤖 Generated with [Claude Code]" footer that a repo's own PR template supplies before opening.

### Commit message style — caveman-commit by default

Apply the `~/.claude/skills/caveman-commit` rules to every commit, without waiting for the user to type `/caveman-commit`. Key rules (full spec in the skill file):

- **Subject:** `<type>(<scope>): <imperative summary>` — Conventional Commits, ≤50 chars when possible, hard cap 72, no trailing period.
- **Types:** `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`.
- **Body:** skip entirely when the subject is self-explanatory. Add a body only for non-obvious *why*, breaking changes, migration notes, or linked issues. Wrap at 72 chars. Bullets `-` not `*`.
- **Imperative mood:** "add", "fix", "remove" — never "added", "adds", "adding".
- **Never include:** "This commit does X", "I"/"we"/"now"/"currently" filler, "As requested by ..." (use a `Co-authored-by:` trailer for real co-authors only — never for Claude), emoji unless the project explicitly uses them, restating the filename when `<scope>` already says it.
- **Always include a body for:** breaking changes (`type!: ...`), security fixes, data migrations, reverts.
- **Per-project trailers** (e.g. a ticket or slice tag a given repo requires) take precedence and append to the subject.
