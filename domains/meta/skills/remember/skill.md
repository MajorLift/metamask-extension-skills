---
maturity: draft
name: remember
description: Capture + crystallize a durable team learning. Shape the body at capture time and decide new-vs-edit against existing skills before writing. Defers nothing to later curation.
origin: drafted
---

# /remember

Capture a skill-shaped learning at the moment it surfaces — **shaping the body and deciding new-vs-edit in the same step** — persisting to the configured skills repo.

`/remember` absorbs `/crystallize`: the invoking agent has the conversation context that makes shaping cheap. That context is lost by the time curation happens. Deferring shaping to a later "curation pass" is the antipattern — TODO-riddled stubs pile up in the inbox and nobody can crystallize them without re-deriving the original context.

`/remember` also absorbs **decide-new-vs-edit**: before writing, the invoker searches existing skills for overlap. If the learning refines or contradicts an existing skill, amend that skill. Only create a new inbox entry when no existing skill covers the same ground.

Capture + shape + route fire together. Curation is review, promotion, and deprecation — not drafting from scratch.

## Do Not Use When

- The learning is session-specific context, not a durable rule. Skills persist across sessions and tasks.
- The fact is derivable from the code or public docs in under an hour. Those belong in the code or docs, not as skills.
- You don't have enough context to shape a real body. A one-liner with `TODO` placeholders is strictly worse than waiting for the next time the learning surfaces with fuller context.
- The user is mid-task and the capture would interrupt flow. Wait for a natural pause, or let `skill-capture-cues` surface a prompt.
- The team has already rejected this learning in a prior curation pass. Avoid re-litigating resolved calls.
- The capture would leak private data (credentials, personal info, internal-only names in a public skills repo).

## When To Use

- The user directly asks to capture something (`/remember X`, "let's save that as a skill"). Before committing: search the bundle for overlap, shape a body, decide new-vs-edit.
- A reviewer surfaces a durable convention or antipattern on a PR. `@metamaskbot /remember <text>` in the thread captures the one-liner; the shaping and new-vs-edit decision happen in the opened PR before merge (or in the direct-commit amendment for the `direct` tier if the invoker passed `--edit`).
- A correction or insight has been stated explicitly and the user has signaled it's worth keeping. Shape the body from the preceding exchange; route via `--edit` if it refines an existing skill.
- The `skill-capture-cues` prompt has been accepted and the paraphrase is approved. The paraphrase IS the shaped capture.

## Action shape

**Responsibilities of the invoker (agent or human):**

1. **Search for overlap.** Grep the local skills bundle (`.cursor/rules/`, `.agents/skills/`, or `.claude/skills/` — whatever's synced) for an existing skill that covers this ground. Exact-match name overlap, keyword overlap, or concept overlap all qualify.
2. **Shape the body.** Write `When To Use`, `Do Not Use When`, `Notes` from the live conversation context. One to three sentences per section is usually enough.
3. **Choose new-vs-edit.**
   - No overlap → new capture in `domains/inbox/`.
   - Clear overlap → amend the existing skill with `--edit <path>`.
   - Contradicts an existing skill → amend with `--edit <path>` and note the reversal in the amendment body.
4. **Invoke the tool** with the shaped body and the routing decision.

**Tool CLI (`tools/remember.ts`):**

```
node tools/remember.ts [flags] "capture one-liner"

  --captured-by <user>    Override author
  --source-repo <name>    Override source repo
  --audit-url <url>       Audit backlink (PR comment, issue, etc.)
  --mode <commit|local>   commit writes to the skills repo; local writes a file
  --out-dir <dir>         Root dir for --mode local
  --body-file <path>      Pre-shaped markdown body (headings below H1 title).
                          New: replaces the TODO template.
                          Edit: content of the Amendment section.
  --edit <path>           Amend existing skill at <path>; writes a new Amendment
                          section + changelog entry instead of creating new.
```

**New vs. edit behavior:**

| Mode | Default behavior | With `--body-file` |
|------|------------------|---------------------|
| New (no `--edit`) | Creates `domains/inbox/skills/<slug>/skill.md` with TODO placeholders | Creates same file with shaped body replacing TODOs |
| Edit (`--edit <path>`) | Appends an `## Amendment <timestamp>` section (body = capture one-liner) + changelog entry | Appends amendment with shaped body + changelog entry |

**Output contract (all meta-skills):**

Every meta-skill invocation must return two blocks:

1. **Outcome** — what actually happened (paths, SHAs, URLs, counts). One line per artifact touched.
2. **Follow-ups** *(conservative)* — concrete action items only when warranted. Empty is the default; noise defeats the purpose. Warranted cases for `/remember`:
   - Body is TODO placeholders (no `--body-file`) — "Shape the body before this stub rots."
   - Slug collided (used `-N` suffix) — "Verify this isn't a near-duplicate before promotion."
   - Amendment body is only the capture one-liner (`--edit` without `--body-file`) — "Consider whether parent sections need updating."

Do not emit follow-ups for routine successful captures. Agents that consume the output should be able to trust silence.

**Surfaces:**

- `@metamaskbot /remember <text>` as a PR comment (trust-tiered: direct / PR / reject).
- `tools/remember.ts` locally or as a CI step.
- In-session agent invocation with repo write credentials — the agent runs overlap search + shaping + routing before calling the tool.

## Why this is a skill, not just a command

`/remember` is user-invoked and maps to a concrete implementation, but its contract — what qualifies as a capture, how to shape the body, when to edit vs. create new, why all three decisions belong to the capturing agent — is the kind of durable rule that benefits from living alongside the content skills. Agents consuming the bundle learn how the capture system works without a separate doc, and the rule itself evolves through the same loop it enables.

## Why capture, crystallize, and route collapse into one command

Splitting capture from shaping from routing creates a broken loop:

- The agent with the full conversation context captures a one-liner.
- The inbox fills with stubs, some of which duplicate existing skills the capturer didn't check for.
- A later curator picks up a stub with no conversation context, no memory of the surrounding problem, and has to re-derive what the capture meant — and separately decide whether it's already covered somewhere.
- Most stubs never get shaped. Duplicates survive until someone notices. The inbox becomes a graveyard.

Shaping and routing at capture time cost the invoking agent about a minute of work while the context is live. Deferring them costs the curator many minutes of re-derivation, or (more often) the skill dies in the inbox or ships as a duplicate.

The command that captures is the command that shapes and the command that routes.
