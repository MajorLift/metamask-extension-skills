---
maturity: experimental
name: scope-lock
description: Enforce declared file scope for PRs — changes outside declared set require explicit justification
---

# Scope Lock

## When To Use

- Reviewing agent-authored PRs (automated runs via Cursor, Copilot, etc.)
- Any PR where the diff touches files outside the ticket's stated scope
- Pre-flight check before submitting a PR
- When a targeted change starts pulling you across the dependency graph

## Do Not Use When

- Intentional refactoring PRs with broad, documented scope
- Release/version-bump PRs with expected wide file changes

## Core Principle

A PR should modify only the files necessary to accomplish its stated goal. Every file outside that set is blast radius that creates review burden and risk.

Agents lack the workflow knowledge to self-limit scope. Humans must enforce it.

## Scope Declaration

Before starting work, declare the intended modification set:

```
Scope: app/scripts/controllers/perps/*.ts, ui/pages/perps/**
Reason: Fix decimal formatting in perps display logic
```

Any file outside this set requires explicit justification before inclusion.

## Blast Radius Audit

First pass on any PR (especially agent-authored) should be a scope audit.

**Before staging:** `git diff --stat` and verify every file was explicitly requested or strictly necessary for compilation.

For each modified file, ask:

| File category | Question | Expected answer |
|---------------|----------|-----------------|
| Feature code | Is this file in the ticket scope? | Yes — or justify |
| Dependencies (package.json, yarn.lock) | Are only declared deps changing? | Yes — no version downgrades, no unrelated additions |
| Build/test config (jest.config, webpack, tsconfig) | Why does the feature need config changes? | It shouldn't — see Workaround Cascade Rule |
| Release artifacts (attribution.txt, CHANGELOG.md) | Is this a release PR? | If no, revert these changes |
| Generated files (yarn.lock, package-lock.json) | Do they match declared dep changes? | Yes — and nothing else |
| Dev artifacts (PR_DESC.md, .cursor/*, .vscode/*) | Should this be committed? | No — add to .gitignore |

**Rule:** If a file can't be justified against the original task, revert it.

## Dependency Graph Traversal Discipline

When a targeted change triggers type errors or lint failures in distant files, do NOT follow the error chain into "while I'm here" cleanup territory.

- Only modify direct dependents that would **fail to compile** — do not preemptively refactor consumers that still compile
- Type-level cosmetic cleanups (e.g., `Omit<T, 'field'>` swaps) are not required changes — don't propagate them
- Changes to reporting/announcement infrastructure should not leak from metric collection tasks unless explicitly scoped

## Specification Evasion Detection

Watch for signs that scope is expanding to **avoid confronting a blocker** rather than to accomplish the task:

| Signal | Example | Correct Response |
|--------|---------|------------------|
| Creating new files when existing ones fail | New simplified script instead of fixing original | Diagnose why the original fails |
| Adding CLI flags not in original spec | `--skip-X` to avoid errors | Fix the errors |
| Reduced scope without discussion | "Let's just test account switching" | Surface the choice to the user |
| Reporting success after adding exclusions | "Tests pass now" (with new ignores) | Report what was skipped |
| Phrases like "Let me try a different approach" after errors | Abandoning the correct approach for an easy one | Diagnose first, escalate second |

**Counter-protocol:** When encountering a blocker, diagnose first. If diagnosis is costly, surface the choice to the user. Never modify the spec without explicit approval. Distinguish "ran successfully" from "achieved stated goal."

## Common Agent Anti-Patterns

### "Porting Without Adapting"

Agent mirrors source platform patterns without checking target platform conventions:
- Raw `browser.storage.local` instead of `StorageService`
- Hand-rolled async hooks instead of existing `useAsyncResult`
- Platform-specific workarounds instead of using existing utilities

**Check:** For every new pattern the agent introduces, grep the codebase for existing equivalents.

### "Blast Radius Blindness"

Agent makes changes far beyond ticket scope because it lacks knowledge of:
- Release process conventions (don't touch attribution.txt)
- Dependency hygiene (don't downgrade packages during rebase)
- CI performance implications (don't add transformIgnorePatterns)

**Check:** Count files modified outside the feature directory. Each one needs justification.

### "Workaround Cascade"

Agent's code creates a problem -> agent fixes the problem with a workaround -> workaround has downstream costs. See `specifications-as-guardrails` for the full cascade detection rule.

## Triage Questions

For each file in the diff:

1. Is this file in the declared scope?
2. If not, is the change mechanically required by an in-scope change? (e.g., import update, type export)
3. If not, does it affect shared infrastructure? (config, build, CI)
4. If yes to #3, why don't other consumers need this change?
5. Would reverting this file break the feature? If no, revert it.

## Prevention for Autonomous Agents

These rules should be encoded in agent knowledge files (per ADR 0057 Layer 2):

| Knowledge file | Rule |
|----------------|------|
| `extension-release-process.md` | Never modify attribution.txt, CHANGELOG.md, or version fields in feature PRs |
| `extension-dependency-management.md` | Only change deps declared in ticket scope; version changes need justification |
| `extension-testing.md` | Mock @metamask/* packages in unit tests; never add transformIgnorePatterns for core packages |
| `extension-persistence.md` | Persistence goes through StorageService, not raw browser.storage.local |
| `extension-hooks.md` | Async data fetching uses useAsyncResult from ui/hooks/useAsync.ts |

## Red Flags

```
Bad:  package.json diff contains version changes for packages not in ticket scope
Bad:  yarn.lock diff is disproportionately large relative to declared dep changes
Bad:  attribution.txt or CHANGELOG.md modified in a feature PR
Bad:  jest.config.js or webpack.config.js modified for a single test/feature
Bad:  New utility/hook that duplicates an existing one
Bad:  PR_DESC.md, .cursor/*, or other dev artifacts committed
Bad:  Following type errors across the dependency graph into cleanup territory
Bad:  "Let me try a different approach" after an error instead of diagnosing

Good: Diff is contained to declared scope directories
Good: Only explicitly declared dependencies added/updated
Good: Config files untouched
Good: Existing utilities and conventions reused
Good: Generated files match declared changes
Good: Blocker diagnosed before scope is expanded
```
