# metamask-extension-skills

A working model for capturing team-specific, battle-tested engineering knowledge as skills that AI coding agents ([Claude Code](https://claude.com/claude-code), [Cursor](https://cursor.com), [OpenCode](https://opencode.ai)) can load on demand.

## What this is

- **Narrow, actionable skills.** Each skill is scoped tightly enough to act on in a crisis — not a generic best-practices essay.
- **Battle-tested, not aspirational.** Every skill traces back to a real incident, review, or postmortem.
- **Two-layer structure.** A generic `skill.md` encodes the workflow; `repos/<repo>.md` overlays encode paths, commands, and repo-specific details. One skill body can serve multiple codebases.
- **Shared knowledge files.** Skills declare `requires:` in frontmatter to pull in longer-form pattern explanations without inlining them. One knowledge file, many skills.
- **Intentionally thin.** The catalog stays sparse until new incidents justify new entries. Everything is `experimental`.
- **Loaded on demand by agents**, not read end-to-end by humans.

The specific examples here are drawn from MetaMask browser extension and mobile work, but the method generalizes to any team running agents in the loop.

## Admission filter

A skill earns entry only if it passes all three tests:

- **Non-derivable.** An agent cannot reconstruct it from reading the code.
- **Invariant.** It holds across time and refactors, not just today's layout.
- **Sourced from real intervention.** A PR comment, incident, or postmortem — not a hypothetical.

Every skill also carries a `Do Not Use When` section, drafted *first* at capture time, that caps scope before the body is written. See [AUTHORING.md](AUTHORING.md) for the full filter, structure, and install instructions.

## Flagship examples

Three skills that illustrate what passes the filter and what the method looks like when it works.

### [`extension-lifecycle-decoupling`](domains/platform/skills/extension-lifecycle-decoupling/skill.md)

- Teaches the single most load-bearing architectural fact about MV3 browser extensions: **platform lifecycle and application lifecycle are decoupled.**
- Service worker eviction is not a lock. Timers tied to SW restart are not auto-lock. State in `chrome.storage.session` is not lost when the SW dies. Each is a trap an agent will otherwise walk into on first contact.
- Supplies a verification checklist and an assumption-vs-reality table so the agent checks the handler chain before reasoning about side effects.
- **Portable shape:** "before claiming a platform event causes an application effect, verify the actual handler." Ports to any runtime with a decoupled platform/application lifecycle (web workers, iOS background, Kubernetes pod eviction).
- Requires [`mv3-service-worker`](domains/platform/knowledge/mv3-service-worker.md).

### [`selector-anti-pattern-review`](domains/ui-performance/skills/selector-anti-pattern-review/skill.md)

- A dual-mode review skill for React+Redux render cascades.
- **Mode A:** pre-merge grep checklist against five named selector anti-patterns.
- **Mode B:** post-merge diagnostic workflow driven by why-did-you-render output.
- One skill both *reviews* incoming PRs and *investigates* cascades found in production, backed by a shared knowledge file.
- **Portable shape:** any codebase where a memoization layer like reselect is load-bearing.
- Cross-repo overlays: [extension](domains/ui-performance/skills/selector-anti-pattern-review/repos/metamask-extension.md), [mobile](domains/ui-performance/skills/selector-anti-pattern-review/repos/metamask-mobile.md).
- Requires [`render-cascade`](domains/ui-performance/knowledge/render-cascade.md) and [`selector-anti-patterns`](domains/ui-performance/knowledge/selector-anti-patterns.md).

### [`sentry-mcp-queries`](domains/analytics/skills/sentry-mcp-queries/skill.md)

- Operational observability via a Sentry MCP server.
- Encodes **build-variant discipline** — check the right release channel before attributing root cause.
- Encodes **release-comparison methodology** — normalize by sessions, filter unreliable releases by rollout age.
- Encodes **span volume estimation** for cost control.
- Any team with production errors needs this discipline; most write it down only after they have been burned by its absence.
- [Extension overlay](domains/analytics/skills/sentry-mcp-queries/repos/metamask-extension.md).

## Full catalog

| Domain | Skills | Knowledge | Overlays |
|---|---|---|---|
| ai-collaboration | [`specifications-as-guardrails`](domains/ai-collaboration/skills/specifications-as-guardrails/skill.md) | — | — |
| analytics | [`analytics-instrumentation`](domains/analytics/skills/analytics-instrumentation/skill.md), [`sentry-mcp-queries`](domains/analytics/skills/sentry-mcp-queries/skill.md) | [`metrametrics-identity`](domains/analytics/knowledge/metrametrics-identity.md), [`segment-governance`](domains/analytics/knowledge/segment-governance.md) | [ext (analytics-instrumentation)](domains/analytics/skills/analytics-instrumentation/repos/metamask-extension.md), [ext (sentry-mcp-queries)](domains/analytics/skills/sentry-mcp-queries/repos/metamask-extension.md) |
| platform | [`extension-errors-debugging`](domains/platform/skills/extension-errors-debugging/skill.md), [`extension-lifecycle-decoupling`](domains/platform/skills/extension-lifecycle-decoupling/skill.md) | [`extension-architecture`](domains/platform/knowledge/extension-architecture.md), [`mv3-service-worker`](domains/platform/knowledge/mv3-service-worker.md) | [ext (errors)](domains/platform/skills/extension-errors-debugging/repos/metamask-extension.md) |
| pr-workflow | [`commit-discipline`](domains/pr-workflow/skills/commit-discipline/skill.md), [`pr-description`](domains/pr-workflow/skills/pr-description/skill.md) | — | [ext (pr-description)](domains/pr-workflow/skills/pr-description/repos/metamask-extension.md) |
| testing | [`benchmark-design`](domains/testing/skills/benchmark-design/skill.md) | — | — |
| ui-performance | [`selector-anti-pattern-review`](domains/ui-performance/skills/selector-anti-pattern-review/skill.md), [`effect-anti-pattern-review`](domains/ui-performance/skills/effect-anti-pattern-review/skill.md) | [`render-cascade`](domains/ui-performance/knowledge/render-cascade.md), [`selector-anti-patterns`](domains/ui-performance/knowledge/selector-anti-patterns.md), [`effect-anti-patterns`](domains/ui-performance/knowledge/effect-anti-patterns.md) | [ext (selector)](domains/ui-performance/skills/selector-anti-pattern-review/repos/metamask-extension.md), [mobile (selector)](domains/ui-performance/skills/selector-anti-pattern-review/repos/metamask-mobile.md), [ext (effect)](domains/ui-performance/skills/effect-anti-pattern-review/repos/metamask-extension.md), [mobile (effect)](domains/ui-performance/skills/effect-anti-pattern-review/repos/metamask-mobile.md) |
