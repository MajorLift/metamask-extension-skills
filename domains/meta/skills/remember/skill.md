---
maturity: draft
name: remember
description: Capture + crystallize a durable team learning into the skills inbox. Shape the body at the moment of capture, using conversation context that's lost if deferred.
origin: drafted
---

# /remember

Capture a skill-shaped learning at the moment it surfaces, **and shape it into a full skill body in the same step**, persisting to `domains/inbox/` of the configured skills repo as an experimental skill.

`/remember` absorbs `/crystallize`: the invoking agent has the conversation context that makes shaping cheap. That context is lost by the time curation happens. Deferring shaping to a later "curation pass" is the antipattern — you end up with TODO-riddled stubs nobody can crystallize without re-deriving the original context.

Capture + shape fire together. Curation is review, edit, and promotion — not drafting from scratch.

## Do Not Use When

- The learning is session-specific context, not a durable rule. Skills persist across sessions and tasks.
- The fact is derivable from the code or public docs in under an hour. Those belong in the code or docs, not as skills.
- You don't have enough context to shape a real body. A one-liner with `TODO` placeholders is strictly worse than waiting for the next time the learning surfaces with fuller context.
- The user is mid-task and the capture would interrupt flow. Wait for a natural pause, or let `skill-capture-cues` surface a prompt.
- The team has already rejected this learning in a prior curation pass. Avoid re-litigating resolved calls.
- The capture would leak private data (credentials, personal info, internal-only names in a public skills repo).

## When To Use

- The user directly asks to capture something (`/remember X`, "let's save that as a skill"). Before committing, shape a body: write `When to use`, `Do not use when`, `Notes` from the conversation context.
- A reviewer surfaces a durable convention or antipattern on a PR. `@metamaskbot /remember <text>` in the thread captures the one-liner; the invoking author (or a follow-up agent) shapes the sections in the opened PR before merge.
- A correction or insight has been stated explicitly and the user has signaled it's worth keeping. Shape the body from the preceding exchange.
- The `skill-capture-cues` prompt has been accepted and the paraphrase is approved. The paraphrase IS the shaped capture.

## Action shape

**Input:**

- `capture` — one or two sentences stating the rule. Always required.
- `body` (optional, via `--body-file`) — pre-shaped markdown with `When to use` / `Do not use when` / `Notes` sections. When present, this replaces the TODO template.

**Behavior:**

1. Write an experimental skill file to `domains/inbox/skills/<slug>/skill.md` in the configured skills repo.
2. Frontmatter records `maturity: experimental`, `origin: captured`, `captured_by`, `captured_at`, `source_repo`, optional `audit_url`.
3. Body is either the pre-shaped markdown (preferred) or a TODO template (fallback — signals the capture needs follow-up shaping before it's useful).
4. Handle slug collisions by incrementing a suffix (`-2`, `-3`, ...).

**Output:** path, commit SHA, and URL of the created skill file.

**Surfaces:**

- `@metamaskbot /remember <text>` as a PR comment (trust-tiered: direct / PR / reject).
- `tools/remember.ts` locally or as a CI step, for programmatic capture. Pass `--body-file` with a shaped markdown file.
- In-session agent invocation with repo write credentials — the agent shapes the body from conversation context before calling the tool.

## Why this is a skill, not just a command

`/remember` is user-invoked and maps to a concrete implementation, but its contract — what qualifies as a capture, how to shape the body, why shaping is part of capture rather than deferred — is the kind of durable rule that benefits from living alongside the content skills. Agents consuming the bundle learn how the capture system works without a separate doc, and the rule itself evolves through the same loop it enables.

## Why capture and crystallize are one command

Splitting capture from shaping creates a broken loop:

- The agent with the full conversation context captures a one-liner.
- The inbox fills with stubs.
- A later curator (human or agent) picks up a stub with no conversation context, no memory of the surrounding problem, and has to re-derive what the capture meant before they can even start shaping.
- Most stubs never get shaped. The inbox becomes a graveyard.

Shaping at capture time costs the invoking agent 30 seconds of work while the context is live. Deferring it costs the curator 30 minutes of re-derivation, or (more often) the skill dies in the inbox.

The command that captures is the command that shapes.
