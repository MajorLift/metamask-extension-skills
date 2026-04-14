# Authoring Guidelines

All content in this repo is consumed by LLM agents. Every token costs latency and context window. Write accordingly.

## Admission Filter (before you write)

**Default answer is no.** Most useful principles are not team skills. Apply all three tests at capture time. A candidate must pass every one.

| Test | Question | Fails if |
|---|---|---|
| **Non-derivable** | Can a team member figure this out in < 1 hour from the code + public docs? | Yes — it's onboarding material or general knowledge, not a skill |
| **Invariant, not preference** | Would the team reject a PR that violated this? | No — it's personal style or a writing preference |
| **Atomic-network sourced** | Does this come from a real intervention on team code in the last ~4 weeks? | Sourced from personal memory, conference talks, or "general best practice" |

**Forcing function:** draft the `do_not_use_when` list *before* the `when_to_use` list. If `do_not_use_when` is longer, the candidate is not a skill — it's a preference with no clear scope.

**Concrete trigger required.** "An agent might benefit" is not enough. "Last sprint's bug N would have been caught by this" is.

**What fails this filter (examples):** generic debugging methodology (non-derivable fails), rhetorical structure for analytical prose (invariant fails), general AI collaboration hygiene (non-derivable fails), a contributor workflow for this repo itself (belongs in this file, not a skill).

**What passes (and why the existing skills qualify):** `perf-cascade-debugging` names the real `selector-creators.ts` location and the creators (non-derivable — the canonical location moved); `analytics-instrumentation` encodes the `isOptIn: true` pitfall and cross-process context propagation (invariant — the team has burned on these); `benchmark-design` encodes session hygiene discovered empirically (atomic-network — came from real benchmark work).

## Rules

1. **Every line must change agent behavior.** If removing a line doesn't change what the agent does, delete it.
2. **Tables over prose.** Structured data is faster to parse than paragraphs.
3. **Bullet points over paragraphs.** One idea per line.
4. **No filler.** No "it's important to note", "please ensure", "as mentioned above", "in order to".
5. **No redundant context.** Don't explain what a skill is inside a skill. Don't describe the repo structure inside a knowledge file.
6. **Concrete over abstract.** File paths, function names, testIDs > vague descriptions.
7. **Commands over descriptions.** "Run `yarn test`" > "You should run the test suite".
8. **Max 300 lines per file.** Split into knowledge refs if longer.

## Frontmatter

Every `.md` file starts with a frontmatter block between `---` markers.

### Skills (`skill.md`)

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | Skill identifier |
| `description` | yes | One-line summary |
| `maturity` | yes | `experimental` \| `stable` \| `deprecated` — install.sh syncs `stable` by default |
| `requires` | no | List of knowledge file names to inline |

### Knowledge files

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | Knowledge identifier |
| `domain` | yes | Parent domain name |
| `description` | yes | One-line summary |

### Repo overlays (`repos/metamask-extension.md`)

| Field | Required | Purpose |
|---|---|---|
| `repo` | yes | `metamask-extension` |
| `parent` | yes | Skill this overlay belongs to |

## Skill Structure

Required sections: `When To Use`, `Do Not Use When`, and `Common Pitfalls`. `Workflow` is required for procedural skills.

```markdown
---
maturity: experimental
name: <name>
description: <one line>
requires: [<knowledge refs>]
---

# <Name>

## When To Use
<concrete triggers — specific situations in team code where this applies>

## Do Not Use When
<out-of-scope conditions. Draft this list before When To Use.
If this list ends up longer, the candidate is not a skill — see Admission Filter.>

## Workflow
<numbered steps>

## Common Pitfalls
<table: mistake → correct approach>
```

## Repo Overlay Structure

Repo-specific details only. Do not duplicate content from `skill.md`.

```markdown
---
repo: metamask-extension
parent: <skill-name>
---

## File Paths
## Commands
## Architectural Notes
```

## Review Checklist

- [ ] Passes all three Admission Filter tests (non-derivable, invariant, atomic-network sourced)
- [ ] `Do Not Use When` section is shorter than `When To Use`
- [ ] Frontmatter present and valid
- [ ] No line is pure filler
- [ ] Tables used where 3+ items share structure
- [ ] File under 300 lines
- [ ] `requires:` refs point to existing knowledge files
- [ ] Overlays don't duplicate generic skill content
