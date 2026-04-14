# metamask-extension-skills

A library of **battle-tested, intentionally-specific** skills that teach AI coding agents (Claude Code, Cursor, OpenCode) how engineers on this team actually debug, ship, and review MetaMask code.

Every skill here was written after a real incident, review, or outage — not before. The goal is not to document everything; the goal is to stop the same mistakes from happening twice.

> **Status:** Experimental prototype. Maintained under `MajorLift/metamask-extension-skills` pending transfer to the `MetaMask/` org.

## Contents

- [What this is](#what-this-is)
- [What this is not](#what-this-is-not)
- [Design choices](#design-choices)
- [Skills today](#skills-today)
- [Flagship examples](#flagship-examples)
- [Broad applicability](#broad-applicability)
- [Iteration targets](#iteration-targets)
- [For contributors](#for-contributors)

## What this is

A repository of small, opinionated agent instructions that encode team knowledge agents can't derive from reading the codebase alone:

- **Invariants the team has learned the hard way** — `isOptIn: true` strips identity for all users, not just opted-out ones.
- **Canonical locations that moved** — selectors live in `shared/lib/selectors/selector-creators.ts`, not where an agent would first guess.
- **Tooling the team has standardized on** — use the repo's `trace()` wrapper, not raw `Sentry.startSpan()`.
- **Workflows that failed without them** — check `dist` tag before attributing a Sentry issue; otherwise you'll blame app logic for an MV3 lifecycle artifact.

Agents load the relevant skill on demand and produce work that matches how the team already operates.

## What this is not

| This repo is... | It is **not**... |
|---|---|
| Intentionally specific | A generic "best practices" library |
| Non-representative | A complete map of the codebase |
| Non-comprehensive | A replacement for docs, ADRs, or onboarding |
| Battle-tested | Aspirational or speculative |
| A set of targets for iteration | A finished spec to be frozen |
| Skills agents load on demand | A standalone reference humans read end-to-end |

If a pattern is obvious from reading the code, it does not belong here. If it's a matter of personal taste, it does not belong here. Skills earn their place by being **non-derivable, invariant, and sourced from real team work** (see [AUTHORING.md](AUTHORING.md)).

## Design choices

**Specific over general.** A skill that names `shared/lib/trace.ts` and the `TraceName` enum is more useful in a crisis than one that says "use your observability tooling." Generic content gets skipped; specific content gets followed.

**Admission filter, not review filter.** Most candidate skills fail at capture, not at review. Three tests gate entry:
1. **Non-derivable** — can the agent figure this out from the code?
2. **Invariant, not preference** — is there a documented reason, or just a stylistic lean?
3. **Atomic-network sourced** — did this come from real work on this team, or from a blog post?

**Forcing function on scope.** Every skill includes a `Do Not Use When` section. If the exclusions outnumber the inclusions, the skill is too broad and gets split or rejected.

**Two-layer structure.** `skill.md` holds the generic workflow; `repos/<repo>.md` overlays the concrete paths, commands, and symbols. The same skill can serve extension and mobile without either one lying about the other.

## Skills today

| Domain | Skill | What it encodes |
|---|---|---|
| `ai-collaboration` | `specifications-as-guardrails` | Failing checks are signal, not obstacles — don't weaken the spec first |
| `analytics` | `analytics-instrumentation` | Tracking plan, `isOptIn` pitfalls, `trace()` wrapper, volume estimation |
| `analytics` | `sentry-mcp-queries` | Error triage, release comparison, replay retrieval via Sentry MCP |
| `coding` | `shape-change-refactoring` | Rename-shape-first discipline for field/type renames |
| `performance` | `render-cascade-debugging` | WDYR workflow + selector-creator fixes for React+Redux render cascades |
| `platform` | `extension-errors-debugging` | MV3 lifecycle attribution before blaming app logic |
| `platform` | `extension-lifecycle-decoupling` | Service worker ephemerality, port reconnection, state rehydration |
| `pr-workflow` | `commit-discipline` | GPG-signed commits, subject style, no conventional-commit prefixes |
| `pr-workflow` | `pr-description` | Template discipline, pre/post-PR temporal framing, changelog rules |
| `testing` | `benchmark-design` | E2E benchmark harness, session hygiene, metric selection |

Supporting `knowledge/` documents encode longer-form reference material skills depend on (MV3 architecture, render-cascade patterns, selector anti-patterns, MetaMetrics identity, Segment governance).

## Flagship examples

Three skills showcase what this library does well:

**`render-cascade-debugging`** — a real debugging workflow. Intentionally scoped to React+Redux render cascades, not "performance" in general. Names the render-counter pattern, the WDYR message table, and the root-cause fix map. The specificity is the point: every step maps to a real symptom the team has seen.

**`sentry-mcp-queries`** — operational observability. Encodes the `dist` tag discipline (check MV3 vs MV2 before attributing root cause), release comparison methodology (normalize by sessions, filter unreliable releases by rollout age), and span volume estimation (multiply by `1 / tracesSampleRate`). These are things engineers got wrong before the skill existed.

**`analytics-instrumentation`** — a governance trap disguised as a how-to. The `isOptIn: true` pitfall silently strips user identity for every user, not just non-opted-in ones. No amount of code-reading catches this. The skill exists because the team burned on it.

Each flagship has the same shape: a narrow problem, a specific workflow, and a pitfall table that maps real mistakes to corrected approaches.

## Broad applicability

These are MetaMask-specific skills, but the **method** generalizes:

- Any team with an extension codebase can apply the admission filter, the two-layer `skill.md` + `repos/<repo>.md` structure, and the `Do Not Use When` forcing function.
- Any team with AI agents in the loop benefits from encoding non-derivable team invariants rather than re-explaining them every session.
- The principle — "skills are battle-tested, intentionally specific, and earn their place" — applies to any domain where agents do real work alongside humans.

The library is a proof-of-concept for a discipline, not a product.

## Iteration targets

The whole library is `maturity: experimental`. Known open questions:

- **Lifecycle and telemetry** — how do we measure whether a skill is actually loaded and affects outcomes? (Tracked under the AI ADR series, not here.)
- **Rot detection** — how do we catch a skill that's drifted from the code it names?
- **Cross-repo overlays** — mobile overlays exist for one skill; most skills are extension-only today.
- **Domain coverage gaps** — many domains have one skill or zero. The library is deliberately thin until more real incidents justify more skills.

Skills should evolve as the team learns. None of these are frozen.

## For contributors

See [AUTHORING.md](AUTHORING.md) for the admission filter, frontmatter schema, and the forcing-function rules every skill must pass.

Install skills into a consuming repo:

```bash
tools/install.sh --repo metamask-extension --target ~/dev/metamask/metamask-extension

# Preview without writing
tools/install.sh --repo metamask-extension --target ~/dev/metamask/metamask-extension --dry-run
```

Writes to three gitignored directories in the target repo:

| Operator | Target Path |
|---|---|
| Claude Code | `.claude/skills/<name>/SKILL.md` |
| Cursor | `.cursor/rules/<name>/RULE.md` |
| OpenCode | `.agents/skills/<name>/SKILL.md` |
