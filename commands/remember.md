---
description: Capture a durable team learning. Shape the body, pick a domain, and route new-vs-edit in a single step.
argument-hint: [--domain <name>] [--edit <path>] <capture>
---

# /remember

Persist a skill-shaped learning to the configured skills repo. See the full contract in the `remember` meta-skill (`.agents/skills/remember/SKILL.md` after sync, or `domains/meta/skills/remember/skill.md` upstream).

## What you do when this runs

1. **Search for overlap.** Grep the local skills bundle (`.agents/skills/`, `.claude/skills/`, or `.cursor/rules/`) for an existing skill covering this ground.
2. **Shape the body.** Write `When To Use`, `Do Not Use When`, `Notes` from live conversation context. Save to a temp file for `--body-file`.
3. **Pick a domain** from existing ones (`ai-collaboration`, `analytics`, `coding`, `meta`, `performance`, `platform`, `pr-workflow`, `testing`, `ui-performance`). Propose a new domain only if none fits.
4. **Choose new-vs-edit.**
   - No overlap → new capture (`--domain <name>`).
   - Clear overlap or contradiction → amend (`--edit <path>`; note reversals in the amendment body).
5. **Invoke the tool:**

   ```bash
   node tools/remember.ts --domain <name> --body-file <path> "<capture one-liner>"
   # or
   node tools/remember.ts --edit <path> --body-file <path> "<capture one-liner>"
   ```

   Run from the skills repo checkout, or pass `--mode local --out-dir <dir>` to write locally without committing.

## Output contract

Return two blocks:

1. **Outcome** — paths, SHAs, URLs, counts. One line per artifact touched.
2. **Follow-ups** *(conservative)* — concrete action items only when warranted. Empty is the default.

Warranted follow-ups:
- No `--body-file` (TODO stub) → "Shape the body before this stub rots."
- No `--domain` → "Falling back to 'inbox'; pick a domain at capture so the skill ships to the bundle."
- Slug collision → "Verify this isn't a near-duplicate before promotion."
- Amendment body is only the one-liner → "Consider whether parent sections need updating."

## Do not use when

- The learning is session-specific, not a durable rule.
- The fact is derivable from the code or public docs in under an hour.
- You don't have enough context to shape a real body — wait for the next surfacing.
- The team has already rejected this learning in a prior curation pass.
- The capture would leak private data.
