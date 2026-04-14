# metamask-extension-skills

A working model for capturing team-specific, battle-tested engineering knowledge as skills that AI coding agents ([Claude Code](https://claude.com/claude-code), [Cursor](https://cursor.com), [OpenCode](https://opencode.ai)) can load on demand. Each skill is narrow enough to act on in a crisis, written only after a real incident or review, and admitted only after passing a three-part filter.

The specific examples are drawn from MetaMask browser extension and mobile work, but the method, structure, and authoring rules generalize to any team running agents in the loop. See [AUTHORING.md](AUTHORING.md) for the admission filter and the forcing-function rules.

## Why this exists

Agents are already in the review and debugging loop. Generic best-practices guidance is not enough. It either rehashes what the agent already knows, or it drifts into preferences a team would not actually enforce. What is missing is the thin sliver of hard-won, non-derivable knowledge that lives in postmortems, PR comments, and Slack threads — the stuff every team relearns every few years. A skills library that captures that sliver, and nothing else, is what this repo prototypes.

The value proposition is usage-shaped. A skill is worth writing only if an agent loading it will act differently, on a specific problem, in a way the team would have insisted on anyway. Anything that does not move the agent's behavior fails the filter.

## What this is, and isn't

| This is | This is not |
|---|---|
| Battle-tested. Each skill traces to a real incident or review. | Aspirational or speculative. |
| Intentionally specific. Narrow scope, real paths, real symbols. | A generic "best practices" library. |
| Non-comprehensive. Thin until more incidents justify more. | A complete map of any one codebase. |
| Loaded on demand by agents. | A standalone reference humans read end-to-end. |
| A target for iteration. All skills are `experimental`. | A finished spec. |

Skills earn entry by being non-derivable, invariant, and sourced from real intervention on real code. Patterns that are obvious from the code, or matters of taste, stay out. Every skill carries a [`Do Not Use When`](AUTHORING.md#skill-structure) forcing function that caps scope at capture time.

## Flagship examples

Three skills that illustrate what passes the filter and what the method looks like when it works.

- [`selector-anti-pattern-review`](domains/ui-performance/skills/selector-anti-pattern-review/skill.md). A dual-mode review skill for React+Redux render cascades. Mode A is a pre-merge grep checklist against five named selector anti-patterns. Mode B is a post-merge diagnostic workflow driven by why-did-you-render output. The value is the shape: one skill that both *reviews* incoming PRs and *investigates* cascades found in production, backed by a shared knowledge file. The shape is portable to any codebase where a memoization layer like reselect is load-bearing. Cross-repo: [extension overlay](domains/ui-performance/skills/selector-anti-pattern-review/repos/metamask-extension.md), [mobile overlay](domains/ui-performance/skills/selector-anti-pattern-review/repos/metamask-mobile.md). Requires [`render-cascade`](domains/ui-performance/knowledge/render-cascade.md) and [`selector-anti-patterns`](domains/ui-performance/knowledge/selector-anti-patterns.md).
- [`sentry-mcp-queries`](domains/analytics/skills/sentry-mcp-queries/skill.md). Operational observability via a Sentry MCP server. Encodes build-variant discipline (check the right release channel before attributing root cause), release-comparison methodology (normalize by sessions, filter unreliable releases by rollout age), and span volume estimation for cost control. Any team with production errors needs this kind of discipline; most write it down only after they have been burned by its absence. [Extension overlay](domains/analytics/skills/sentry-mcp-queries/repos/metamask-extension.md).
- [`specifications-as-guardrails`](domains/ai-collaboration/skills/specifications-as-guardrails/skill.md). The broadest entry in the repo. An AI-collaboration posture any team can adopt on day one: failing type checks, lint rules, and tests are signal, not obstacles to remove. The skill exists because "just delete the failing test" is a near-universal agent failure mode, and a short explicit counter-rule corrects it.

These three make the case. Skills succeed when they encode something the team learned the hard way, in terms specific enough to act on in a crisis.

## Full catalog

| Domain | Skills | Knowledge | Overlays |
|---|---|---|---|
| ai-collaboration | [`specifications-as-guardrails`](domains/ai-collaboration/skills/specifications-as-guardrails/skill.md) | — | — |
| analytics | [`analytics-instrumentation`](domains/analytics/skills/analytics-instrumentation/skill.md), [`sentry-mcp-queries`](domains/analytics/skills/sentry-mcp-queries/skill.md) | [`metrametrics-identity`](domains/analytics/knowledge/metrametrics-identity.md), [`segment-governance`](domains/analytics/knowledge/segment-governance.md) | [ext (analytics-instrumentation)](domains/analytics/skills/analytics-instrumentation/repos/metamask-extension.md), [ext (sentry-mcp-queries)](domains/analytics/skills/sentry-mcp-queries/repos/metamask-extension.md) |
| platform | [`extension-errors-debugging`](domains/platform/skills/extension-errors-debugging/skill.md), [`extension-lifecycle-decoupling`](domains/platform/skills/extension-lifecycle-decoupling/skill.md) | [`extension-architecture`](domains/platform/knowledge/extension-architecture.md), [`mv3-service-worker`](domains/platform/knowledge/mv3-service-worker.md) | [ext (errors)](domains/platform/skills/extension-errors-debugging/repos/metamask-extension.md) |
| pr-workflow | [`commit-discipline`](domains/pr-workflow/skills/commit-discipline/skill.md), [`pr-description`](domains/pr-workflow/skills/pr-description/skill.md) | — | [ext (pr-description)](domains/pr-workflow/skills/pr-description/repos/metamask-extension.md) |
| testing | [`benchmark-design`](domains/testing/skills/benchmark-design/skill.md) | — | — |
| ui-performance | [`selector-anti-pattern-review`](domains/ui-performance/skills/selector-anti-pattern-review/skill.md), [`effect-anti-pattern-review`](domains/ui-performance/skills/effect-anti-pattern-review/skill.md) | [`render-cascade`](domains/ui-performance/knowledge/render-cascade.md), [`selector-anti-patterns`](domains/ui-performance/knowledge/selector-anti-patterns.md), [`effect-anti-patterns`](domains/ui-performance/knowledge/effect-anti-patterns.md) | [ext (selector)](domains/ui-performance/skills/selector-anti-pattern-review/repos/metamask-extension.md), [mobile (selector)](domains/ui-performance/skills/selector-anti-pattern-review/repos/metamask-mobile.md), [ext (effect)](domains/ui-performance/skills/effect-anti-pattern-review/repos/metamask-extension.md), [mobile (effect)](domains/ui-performance/skills/effect-anti-pattern-review/repos/metamask-mobile.md) |

Skills load their required knowledge via frontmatter (`requires: [render-cascade, selector-anti-patterns]`). Overlays encode repo-specific paths and commands, so the same skill body can serve multiple repos when the underlying patterns apply to all of them.

## What generalizes, even if the individual skills do not

The transferable assets in this repo are the method and the structure, not the skill catalog.

- **Admission filter.** Three tests (non-derivable, invariant, sourced from real intervention) applied before writing, with a `Do Not Use When` list drafted *first* as a forcing function. Any team can lift it.
- **Two-layer file structure.** A generic `skill.md` that encodes the workflow, plus `repos/<repo>.md` overlays that encode paths, commands, and repo-specific baselines. One skill can serve multiple codebases without forking.
- **Knowledge files as shared dependencies.** Skills declare `requires:` frontmatter to pull in a knowledge file (longer-form pattern explanations, reference tables) without inlining it. One knowledge file, many skills.
- **Narrow scope by default.** Flagships are illustrative, not exhaustive. The catalog stays thin until more incidents justify more entries.

Everything above applies to any team running agents in the loop, regardless of language, stack, or problem domain.

## Install

```bash
tools/install.sh --repo metamask-extension --target ~/dev/metamask/metamask-extension
```

Writes to gitignored `.claude/skills/`, `.cursor/rules/`, and `.agents/skills/` in the target repo. Adapt the `--repo` and `--target` arguments for any overlay you have authored; the script does not assume a specific codebase.
