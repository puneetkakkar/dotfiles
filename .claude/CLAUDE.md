# Global preferences

## Engineering practice

- **Repeated manual work produces a file.** The third time you make the same edit, or whenever a throwaway analysis script is worth rerunning, write a committed script, codemod, or generator instead of doing it by hand again. If you cite this rule and there is no such file in the diff, you have not applied it.
- **Clean up only your own orphans.** Remove imports, variables, and functions that your change made unused. Do not delete pre-existing dead code unless asked. Mention it instead.
- **Prefer a structural fix over a feedback memory.** When a correction recurs, first try to encode it where it cannot be forgotten: a lint rule, a hook, a test, or a CI check. Write a `feedback_*` memory only when no structural mechanism fits, and record in it why not.

## Git commits and PRs

- **No AI attribution anywhere.** The `attribution` setting disables automatic attribution; this rule covers what that setting cannot reach. Never write AI or Anthropic attribution into a commit message, PR title, or PR body by hand, and strip any "🤖 Generated with [Claude Code]" footer that a repo's own PR template supplies before opening.

### Commit message style: caveman-commit by default

Apply the `~/.claude/skills/caveman-commit` rules to every commit, without waiting for the user to type `/caveman-commit`. Key rules (full spec in the skill file):

- **Subject.** `<type>(<scope>): <imperative summary>`, Conventional Commits, ≤50 chars when possible, hard cap 72, no trailing period.
- **Types.** `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`, `style`, `revert`.
- **Body.** Skip entirely when the subject is self-explanatory. Add a body only for non-obvious *why*, breaking changes, migration notes, or linked issues. Wrap at 72 chars. Bullets `-` not `*`.
- **Imperative mood.** "add", "fix", "remove", never "added", "adds", "adding".
- **Never include:** "This commit does X", "I"/"we"/"now"/"currently" filler, "As requested by ..." (use a `Co-authored-by:` trailer for real co-authors only, never for Claude), emoji unless the project explicitly uses them, restating the filename when `<scope>` already says it.
- **Always include a body for:** breaking changes (`type!: ...`), security fixes, data migrations, reverts.
- **Per-project trailers** (e.g. a ticket or slice tag a given repo requires) take precedence and append to the subject.

## Writing style (prose, not code)

Applies to chat replies, PR bodies, plan files, tickets, docs, code comments
and commit message bodies. Not to commit subjects, which `caveman-commit` and
the commit-msg hook govern. In comments these rules cover wording only; what a
comment should say is the repo's own convention.

- **No em dashes.** End the sentence or use a comma. If a thought needs separating, it needs a full stop.
- **Active voice, and name the actor.** "queries are validated" becomes "the compiler validates queries". Use passive only when the actor is genuinely unknown or irrelevant.
- **Bold is for lead-ins, not emphasis.** A bold label ending in a period that introduces new detail is fine. Bolding proper nouns, acronyms, or every other clause makes emphasis mean nothing.
- **Cut adverbs that prop up a weak verb.** "silently fails" becomes "fails without reporting"; "runs quickly" becomes the number. Keep quantifiers: "reports exactly one" is a different claim from "reports one".
- **Plain word over the fancy synonym.** "use" not "utilize", "help" not "facilitate", "if" not "in the event that".
- **Whole sentences, not compressed notes.** Dropped articles, verbless fragments and abbreviations make the reader decode instead of read. Two exceptions: commit subjects, which have no room for it once the scope and any ticket trailer come out of 72 characters, and real notation in code comments (`Settings → Security → Screen lock`, `green→amber→red`), where spelling it out is worse.

`/unslop` runs the full pstack rule set on a file when you want a deeper pass.
