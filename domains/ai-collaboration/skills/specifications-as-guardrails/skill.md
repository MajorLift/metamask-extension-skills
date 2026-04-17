---
maturity: experimental
name: specifications-as-guardrails
description: Treat failing automated checks as signals to investigate, not obstacles to remove
---

# Specifications as Guardrails

## When To Use

- A failing CI test, TypeScript error, lint rule, or schema check is blocking work
- Considering disabling, weakening, or bypassing an automated check
- A pre-existing flaky test is tempting to delete rather than diagnose

## Do Not Use When

- The check is genuinely wrong and the team has explicitly agreed to update it
- The spec change is part of a documented requirement change

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
| Build/test config | Platform constraints | Add workarounds |

## Triage Protocol

Before touching the spec, answer in order:

1. Is this failure caused by changes in this PR, or pre-existing?
2. Did this test pass on `main` recently?
3. Is this a known flaky test?
4. What did the PR change that could affect this?
5. Does the fix touch shared config? If so, why don't other consumers need this?

Only after these questions can you determine whether the implementation or the spec is wrong.

## Workaround Cascade Rule

When a fix requires changing shared config (jest.config, webpack, CI pipelines), that is a signal you are working around a problem, not fixing it. Each workaround layer masks the root cause and creates downstream costs.

**Detection:** If your fix chain crosses an abstraction boundary (test code -> test config -> build config), stop and trace backwards.

**The cascade pattern:**
```
Root cause (unmocked import)
  -> Symptom (ESM parse failure in Jest)
    -> Workaround (transformIgnorePatterns exclusion)
      -> Downstream cost (CI transpiles extra packages for all tests)
```

**The correct response:**
```
Symptom (ESM parse failure in Jest)
  -> "Why is Jest loading this module?"
    -> "The test doesn't mock it"
      -> Fix: mock the module
```

**Rule:** Count the hops between your fix and the failing line. If hops > 1, you are likely patching a symptom. Each hop is a red flag:

| Hops | Fix location | Confidence |
|------|-------------|------------|
| 0 | Same file as failure | High — direct fix |
| 1 | Adjacent file (test helper, mock) | Moderate — verify necessity |
| 2+ | Config, build, CI | Low — almost certainly a workaround |

**Corollary for agent-authored PRs:** When an agent adds config-level workarounds, check how the codebase handles the same situation elsewhere. If other packages/features don't need the workaround, the agent's code is the problem, not the config.

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

## Red Flags

```
Bad:  "Let me update the test to pass"
Bad:  "I'll add a type cast to fix this"
Bad:  Adding arbitrary delays or looser assertions
Bad:  "Let me add this package to transformIgnorePatterns"
Bad:  Changing jest/webpack/build config to accommodate one test

Good: "The test expects X, but code does Y. Investigating why."
Good: "This might be a flaky test. Should I check history?"
Good: "Uncertain whether test or code is correct. Here's what I found..."
Good: "This config change affects all tests. Is there a scoped fix?"
Good: "Other ESM deps don't need this exclusion. What's different here?"
```
