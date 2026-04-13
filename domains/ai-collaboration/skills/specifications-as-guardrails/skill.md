---
name: specifications-as-guardrails
description: Treat failing automated checks as signals to investigate, not obstacles to remove
---

# Specifications as Guardrails

## Core Principle

Automated checks are the specification. When they fail, the code doesn't meet the spec — not the other way around.

Never weaken a spec as the first response to failure.

## Applies To

| Check | Specification | Wrong Response |
|-------|--------------|----------------|
| CI tests | Expected behavior | Weaken assertions |
| TypeScript errors | Contract definitions | Add `any` or casts |
| Lint rules | Code standards | Disable the rule |
| Schema validation | Data contracts | Loosen schemas |
| Access controls | Security boundaries | Add bypass flags |

## Triage Protocol

Before touching the spec, answer in order:

1. Is this failure caused by changes in this PR, or pre-existing?
2. Did this test pass on `main` recently?
3. Is this a known flaky test?
4. What did the PR change that could affect this?

Only after these questions can you determine whether the implementation or the spec is wrong.

## When Spec Changes Are Appropriate

- Requirements genuinely changed (explicit, documented decision)
- Spec itself has a confirmed bug (rare; requires evidence)
- User explicitly requests after understanding the tradeoff

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| "Let me update the test to pass" | Diagnose why code doesn't meet the spec |
| Add `as any` to fix a type error | Find why the type is wrong |
| Adding `// eslint-disable` | Understand and fix the lint violation |
| Arbitrary delay added to fix flaky test | Investigate the actual race condition |
