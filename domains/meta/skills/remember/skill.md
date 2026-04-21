---
maturity: draft
name: remember
description: Capture a durable team learning into the skills inbox for later curation. User-invoked, writes to the configured skills repo as an experimental skill.
origin: drafted
---

# /remember

Capture a skill-shaped learning at the moment it surfaces, persisting it to `domains/inbox/` of the configured skills repo as an experimental skill. The inbox is a low-friction staging area — captures are not yet skills. Team curation promotes them out of the inbox once they've been refined through actual usage.

## Do Not Use When

- The learning is session-specific context, not a durable rule. Skills persist across sessions and tasks.
- The fact is derivable from the code or public docs in under an hour. Those belong in the code or docs, not as skills.
- The user is mid-task and the capture would interrupt flow. Wait for a natural pause, or let `skill-capture-cues` surface a prompt.
- The team has already rejected this learning in a prior curation pass. Avoid re-litigating resolved calls.
- The capture would leak private data (credentials, personal info, internal-only names in a public skills repo).

## When To Use

- The user directly asks to capture something (`/remember X`, "let's save that as a skill").
- A reviewer surfaces a durable convention or antipattern on a PR — `@metamaskbot /remember <text>` in the comment thread.
- A correction or insight has been stated explicitly and the user has signaled it's worth keeping.
- The `skill-capture-cues` prompt has been accepted by the user and the paraphrase is approved.

## Action shape

**Input:** a single string — one or two sentences describing the learning. Longer captures are allowed but should focus on what the rule IS, not the entire supporting argument.

**Behavior:**

1. Write an experimental skill file to `domains/inbox/skills/<slug>/skill.md` in the configured skills repo.
2. Frontmatter records `captured_by`, `captured_at`, `source_repo`, optional `audit_url`.
3. Body includes the capture text and TODO placeholders for curation (When to use, Do not use when, Notes).
4. Handle slug collisions by incrementing a suffix (`-2`, `-3`, ...).

**Output:** path, commit SHA, and URL of the created skill file.

**Surfaces:**

- `@metamaskbot /remember <text>` as a PR comment (trust-tiered: direct / PR / reject based on team membership).
- `tools/remember.ts` locally or as a CI step, for programmatic capture.
- Future: `/remember` in agent sessions with repo write credentials.

## Why this is a skill, not just a command

`/remember` is user-invoked and maps to a concrete implementation, but its contract — what qualifies as a capture, how to shape the one-liner, when curation takes over — is the kind of durable rule that benefits from living alongside the content skills. Agents consuming the bundle learn how the capture system works without a separate doc, and the rule itself evolves through the same loop it enables.
