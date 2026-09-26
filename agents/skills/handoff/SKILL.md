---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

First, make the work durable. Stop at a safe boundary: finish the current atomic step or back out of it, and never hand off mid-edit in a known-broken state. Commit outstanding edits as one clear `wip:` commit on the current branch, staging named files rather than `-A` or `.`, so nothing is lost when the session ends. If the tree is broken, say so in one line of the commit body. Take no irreversible action to hand off: no push, and no PR you did not already have open.

Then write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS - not the current workspace.

State plainly what is on disk versus what is still only in the conversation, and name the commits you made and whether the tree is clean.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
