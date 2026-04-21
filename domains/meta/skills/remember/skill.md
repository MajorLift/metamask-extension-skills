---
maturity: draft
name: remember
description: Capture a durable team learning. Shape the body, pick a domain, and route new-vs-edit in a single step.
origin: drafted
---

# /remember

Capture a skill-shaped learning at the moment it surfaces, persist it to the configured skills repo, and route it to the right domain — all in one step.

## Do Not Use When

- The learning is session-specific context, not a durable rule. Skills persist across sessions and tasks.
- The fact is derivable from the code or public docs in under an hour. Those belong in the code or docs, not as skills.
- You don't have enough context to shape a real body. A one-liner with `TODO` placeholders is strictly worse than waiting for the next time the learning surfaces with fuller context.
- The user is mid-task and the capture would interrupt flow. Wait for a natural pause, or let `skill-capture-cues` surface a prompt.
- The team has already rejected this learning in a prior curation pass. Avoid re-litigating resolved calls.
- The capture would leak private data (credentials, personal info, internal-only names in a public skills repo).

## When To Use

- The user directly asks to capture something (`/remember X`, "let's save that as a skill").
- A reviewer surfaces a durable convention or antipattern on a PR. `@metamaskbot /remember <text>` in the thread captures the one-liner; for the `direct` tier the invoker passes `--edit` or `--domain` as appropriate.
- A correction or insight has been stated explicitly and the user has signaled it's worth keeping.
- The `skill-capture-cues` prompt has been accepted and the paraphrase is approved.

## Action shape

**Responsibilities of the invoker (agent or human):**

1. **Search for overlap.** Grep the local skills bundle (`.cursor/rules/`, `.agents/skills/`, or `.claude/skills/` — whatever's synced) for an existing skill that covers this ground. Exact-match name overlap, keyword overlap, or concept overlap all qualify.
2. **Shape the body.** Write `When To Use`, `Do Not Use When`, `Notes` from the live conversation context. One to three sentences per section is usually enough.
3. **Pick a domain.** Match the capture against existing domains (`ai-collaboration`, `analytics`, `coding`, `meta`, `performance`, `platform`, `pr-workflow`, `testing`, `ui-performance`). Propose a new domain only if the capture genuinely doesn't fit any existing one.
4. **Choose new-vs-edit.**
   - No overlap → new capture in the chosen domain.
   - Clear overlap → amend the existing skill with `--edit <path>`.
   - Contradicts an existing skill → amend with `--edit <path>` and note the reversal in the amendment body.
5. **Invoke the tool** with the shaped body, domain, and routing decision.

**Tool CLI (`tools/remember.ts`):**

```
node tools/remember.ts [flags] "capture one-liner"

  --captured-by <user>    Override author
  --source-repo <name>    Override source repo
  --audit-url <url>       Audit backlink (PR comment, issue, etc.)
  --mode <commit|local>   commit writes to the skills repo; local writes a file
  --out-dir <dir>         Root dir for --mode local
  --domain <name>         Route new capture to domains/<name>/. Required for new
                          captures; missing --domain falls back to 'inbox' and
                          emits a follow-up nudge.
  --body-file <path>      Pre-shaped markdown body (headings below H1 title).
                          New: replaces the TODO template.
                          Edit: content of the Amendment section.
  --edit <path>           Amend existing skill at <path>; writes a new Amendment
                          section + changelog entry instead of creating new.
```

**New vs. edit behavior:**

| Mode | Default behavior | With `--body-file` |
|------|------------------|---------------------|
| New (no `--edit`) | Creates `domains/<domain>/skills/<slug>/skill.md` with TODO placeholders | Creates same file with shaped body replacing TODOs |
| Edit (`--edit <path>`) | Appends an `## Amendment <timestamp>` section (body = capture one-liner) + changelog entry | Appends amendment with shaped body + changelog entry |

**Output contract (all meta-skills):**

Every meta-skill invocation must return two blocks:

1. **Outcome** — what actually happened (paths, SHAs, URLs, counts). One line per artifact touched.
2. **Follow-ups** *(conservative)* — concrete action items only when warranted. Empty is the default; noise defeats the purpose. Warranted cases for `/remember`:
   - Body is TODO placeholders (no `--body-file`) — "Shape the body before this stub rots."
   - No `--domain` passed — "Falling back to 'inbox'; pick a domain at capture so the skill ships to the bundle."
   - Slug collided (used `-N` suffix) — "Verify this isn't a near-duplicate before promotion."
   - Amendment body is only the capture one-liner (`--edit` without `--body-file`) — "Consider whether parent sections need updating."

Do not emit follow-ups for routine successful captures. Agents that consume the output should be able to trust silence.

**Surfaces:**

- `@metamaskbot /remember [--domain <name>] <text>` as a PR comment (trust-tiered: direct / PR / reject).
- `tools/remember.ts` locally or as a CI step.
- In-session agent invocation with repo write credentials — the agent runs overlap search + shaping + routing before calling the tool.
