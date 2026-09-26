---
name: resolving-merge-conflicts
description: "Use when you need to resolve an in-progress git merge/rebase conflict."
---

1. **See the current state** of the merge/rebase. Check git history, and the conflicting files.

2. **Find the primary sources** for each conflict. Understand deeply why each change was made, and what the original intent was. Read the commit messages, check the PRs, check original issues/tickets.

3. **Resolve each hunk.** Preserve both intents where possible. Where incompatible, pick the one matching the merge's stated goal and note the trade-off. Do **not** invent new behaviour. Resolve rather than abort: reach for `--abort` only when the merge's premise is wrong, and say why before you do.

4. Discover the project's **automated checks** and run them, typically typecheck, then tests, then format. Fix anything the merge broke.

5. **Finish the merge/rebase.** Stage the conflicted files by name and commit. Never `git add -A` or `git add .`: a conflicted tree is exactly where stray untracked files collect. Before committing, check `git status` for untracked `.env`, `*.key`, or `*.pem` in scope, and halt if any are there. If rebasing, continue the rebase process until all commits are rebased.
