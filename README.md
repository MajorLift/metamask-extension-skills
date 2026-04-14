# metamask-extension-skills

A prototype library of battle-tested, intentionally-specific skills that teach AI coding agents ([Claude Code](https://claude.com/claude-code), [Cursor](https://cursor.com), [OpenCode](https://opencode.ai)) how engineers on this team actually debug, ship, and review MetaMask code.

Every skill here was written after a real incident, review, or outage (never before). See [AUTHORING.md](AUTHORING.md) for the admission filter and the forcing-function rules every skill must pass.

> Status: experimental prototype. Maintained under `MajorLift/metamask-extension-skills` pending transfer to the `MetaMask/` org.

## What this is, and isn't

| This is | This is not |
|---|---|
| Battle-tested. Each skill traces to real team work. | Aspirational or speculative. |
| Intentionally specific. Narrow scope, real paths, real symbols. | A generic "best practices" library. |
| Non-comprehensive. Thin until more incidents justify more. | A complete map of the codebase. |
| Loaded on demand by agents. | A standalone reference humans read end-to-end. |
| A target for iteration. All skills are `experimental`. | A finished spec. |

Skills earn entry by being non-derivable, invariant, and sourced from real team work. Patterns that are obvious from the code, or matters of taste, stay out. Every skill carries a [`Do Not Use When`](AUTHORING.md#skill-structure) forcing function that caps scope at capture time.

## Flagship examples

- [`selector-anti-pattern-review`](domains/performance/skills/selector-anti-pattern-review/skill.md). Dual-mode React+Redux render cascade review, grounded in the [Extension Frontend Performance Audit epic](https://github.com/MetaMask/MetaMask-planning/issues/6571). Mode A is a pre-merge grep checklist against the five selector anti-patterns; Mode B is WDYR-driven post-merge diagnosis. Measured baselines from [#6524](https://github.com/MetaMask/MetaMask-planning/issues/6524): 1,696 CI warnings, 129 `createDeepEqualSelector`, 44 `useSelector(..., isEqual)`, 33 O(n) `.find()` lookups. Cross-repo: [extension overlay](domains/performance/skills/selector-anti-pattern-review/repos/metamask-extension.md), [mobile overlay](domains/performance/skills/selector-anti-pattern-review/repos/metamask-mobile.md). Requires [`render-cascade`](domains/performance/knowledge/render-cascade.md) and [`selector-anti-patterns`](domains/performance/knowledge/selector-anti-patterns.md).
- [`effect-anti-pattern-review`](domains/performance/skills/effect-anti-pattern-review/skill.md). Pre-merge review for the four `useEffect` anti-patterns catalogued by [#6525](https://github.com/MetaMask/MetaMask-planning/issues/6525): `JSON.stringify` in deps (P0), state-mirror effects (200+ instances), missing interval/timer cleanup (122 instances), and missing `AbortController` in async effects. Cross-repo: [extension overlay](domains/performance/skills/effect-anti-pattern-review/repos/metamask-extension.md), [mobile overlay](domains/performance/skills/effect-anti-pattern-review/repos/metamask-mobile.md). Requires [`effect-anti-patterns`](domains/performance/knowledge/effect-anti-patterns.md).
- [`sentry-mcp-queries`](domains/analytics/skills/sentry-mcp-queries/skill.md). Operational observability. Encodes `dist`-tag discipline (check MV3 vs MV2 before attributing root cause), release-comparison methodology (normalize by sessions, filter unreliable releases by rollout age), and span volume estimation. [Extension overlay](domains/analytics/skills/sentry-mcp-queries/repos/metamask-extension.md). The kind of thing every team with production errors needs, and gets wrong before writing it down.
- [`analytics-instrumentation`](domains/analytics/skills/analytics-instrumentation/skill.md). A governance trap disguised as a how-to. `isOptIn: true` silently strips identity for every user, not just non-opted-in ones. No amount of code-reading catches this. The skill exists because the team burned on it. [Extension overlay](domains/analytics/skills/analytics-instrumentation/repos/metamask-extension.md). Requires [`metrametrics-identity`](domains/analytics/knowledge/metrametrics-identity.md) and [`segment-governance`](domains/analytics/knowledge/segment-governance.md).
- [`specifications-as-guardrails`](domains/ai-collaboration/skills/specifications-as-guardrails/skill.md). Broadest applicability in the repo. An AI-collaboration posture any team can adopt: failing checks are signal, not obstacles to remove.

These five make the case. Skills succeed when they encode something the team learned the hard way, in terms specific enough to act on in a crisis.

## All skills

| Domain | Skills | Knowledge | Overlays |
|---|---|---|---|
| ai-collaboration | [`specifications-as-guardrails`](domains/ai-collaboration/skills/specifications-as-guardrails/skill.md) | — | — |
| analytics | [`analytics-instrumentation`](domains/analytics/skills/analytics-instrumentation/skill.md), [`sentry-mcp-queries`](domains/analytics/skills/sentry-mcp-queries/skill.md) | [`metrametrics-identity`](domains/analytics/knowledge/metrametrics-identity.md), [`segment-governance`](domains/analytics/knowledge/segment-governance.md) | [ext (analytics-instrumentation)](domains/analytics/skills/analytics-instrumentation/repos/metamask-extension.md), [ext (sentry-mcp-queries)](domains/analytics/skills/sentry-mcp-queries/repos/metamask-extension.md) |
| performance | [`selector-anti-pattern-review`](domains/performance/skills/selector-anti-pattern-review/skill.md), [`effect-anti-pattern-review`](domains/performance/skills/effect-anti-pattern-review/skill.md) | [`render-cascade`](domains/performance/knowledge/render-cascade.md), [`selector-anti-patterns`](domains/performance/knowledge/selector-anti-patterns.md), [`effect-anti-patterns`](domains/performance/knowledge/effect-anti-patterns.md) | [ext (selector)](domains/performance/skills/selector-anti-pattern-review/repos/metamask-extension.md), [mobile (selector)](domains/performance/skills/selector-anti-pattern-review/repos/metamask-mobile.md), [ext (effect)](domains/performance/skills/effect-anti-pattern-review/repos/metamask-extension.md), [mobile (effect)](domains/performance/skills/effect-anti-pattern-review/repos/metamask-mobile.md) |
| platform | [`extension-errors-debugging`](domains/platform/skills/extension-errors-debugging/skill.md), [`extension-lifecycle-decoupling`](domains/platform/skills/extension-lifecycle-decoupling/skill.md) | [`extension-architecture`](domains/platform/knowledge/extension-architecture.md), [`mv3-service-worker`](domains/platform/knowledge/mv3-service-worker.md) | [ext (errors)](domains/platform/skills/extension-errors-debugging/repos/metamask-extension.md) |
| pr-workflow | [`commit-discipline`](domains/pr-workflow/skills/commit-discipline/skill.md), [`pr-description`](domains/pr-workflow/skills/pr-description/skill.md) | — | [ext (pr-description)](domains/pr-workflow/skills/pr-description/repos/metamask-extension.md) |
| testing | [`benchmark-design`](domains/testing/skills/benchmark-design/skill.md) | — | — |

Skills load their required knowledge via frontmatter (`requires: [render-cascade, selector-anti-patterns]`). Overlays encode repo-specific paths, commands, and audit baselines; the same skill body can serve both `metamask-extension` and `metamask-mobile` when the React + Redux patterns apply to both.

The method generalizes even where individual skills don't. The admission filter, the [two-layer `skill.md` + `repos/<repo>.md` overlay structure](AUTHORING.md), and the `Do Not Use When` forcing function apply to any team running agents in the loop.

## Install

```bash
tools/install.sh --repo metamask-extension --target ~/dev/metamask/metamask-extension
```

Writes to gitignored `.claude/skills/`, `.cursor/rules/`, and `.agents/skills/` in the target repo.
