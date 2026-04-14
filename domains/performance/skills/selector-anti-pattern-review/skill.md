---
maturity: experimental
name: selector-anti-pattern-review
description: Review PR diffs that touch Redux selectors or `useSelector` calls for the five memoization-breaking patterns
requires:
  - selector-anti-patterns
---

# Selector Anti-Pattern Review

**Scope:** Pre-merge review of PRs that add or modify Redux selectors, `useSelector` calls, or selector creators. The workflow is a grep-driven checklist against the five patterns catalogued in [`selector-anti-patterns`](../../knowledge/selector-anti-patterns.md), extended with two team-specific workarounds the [Extension Frontend Performance Audit epic](https://github.com/MetaMask/MetaMask-planning/issues/6571) flagged as systemic.

## When To Use

- Reviewing a PR that touches `ui/selectors/` or adds a new `useSelector` call
- Reviewing a PR that introduces or modifies a `createSelector` / `createDeepEqualSelector` definition
- Reviewing a PR that imports a selector into a new component (consumption site)
- Auditing a file flagged by the `1,696 CI warnings` baseline from [#6524](https://github.com/MetaMask/MetaMask-planning/issues/6524)

## Do Not Use When

- Diagnosing an already-merged render cascade (use [`render-cascade-debugging`](../render-cascade-debugging/skill.md))
- Writing your own selector (read [`selector-anti-patterns`](../../knowledge/selector-anti-patterns.md) directly)
- Reviewing non-selector performance concerns (effects, context providers, virtualization)

## Workflow

1. **List the selectors the PR touches.** `git diff --name-only origin/main...HEAD | grep -E '(selectors|useSelector)'`
2. **Run the grep checklist below** against the changed files.
3. **Match each hit to a pattern** in [`selector-anti-patterns`](../../knowledge/selector-anti-patterns.md) (numbered 1–5) or to one of the [team-specific workarounds](#team-specific-workarounds) below.
4. **Block on Jest warning.** If the PR's test run surfaces `"result function returned its own inputs"`, the PR introduces [Pattern 2](../../knowledge/selector-anti-patterns.md#2-identity-function-selector). Do not merge.
5. **Require a fix, not a justification.** None of the five patterns have a valid use case in MetaMask selectors. See [Pitfalls](#common-pitfalls) for the one narrow exception to `createDeepEqualSelector`.

## Grep Checklist

| Pattern | Detection | Knowledge ref |
|---|---|---|
| 1. Plain function selector | `grep -rE 'export function get' ui/selectors/` | [§1](../../knowledge/selector-anti-patterns.md#1-plain-function-selector) |
| 2. Identity function selector | Jest warning `result function returned its own inputs` | [§2](../../knowledge/selector-anti-patterns.md#2-identity-function-selector) |
| 3. Unnecessary `createDeepEqualSelector` | `grep -rn 'createDeepEqualSelector' ui/selectors/` then verify each input is not from Immer state | [§3](../../knowledge/selector-anti-patterns.md#3-unnecessary-deep-equality) |
| 4. O(n) lookup | `grep -rnE '\.find\(.*=>.*address' ui/selectors/` | [§4](../../knowledge/selector-anti-patterns.md#4-on-lookups) |
| 5. Chained unmemoized transforms | `grep -rnE 'export function get.*\{' ui/selectors/ -A5` and check for multiple `.filter/.map/.sort` without memoization | [§5](../../knowledge/selector-anti-patterns.md#5-chained-transforms-unmemoized) |

## Team-Specific Workarounds

The [Selector Optimization sub-epic (#6524)](https://github.com/MetaMask/MetaMask-planning/issues/6524) added two patterns beyond the five in the knowledge file. Both are workarounds for broken selectors downstream — the fix is always to fix the selector, never to propagate the workaround.

### `useSelector(selector, isEqual)` from `react-redux`

```typescript
// Workaround that hides the real problem
const accounts = useSelector(getAccounts, isEqual)
```

- **Baseline:** 44 instances across the repo ([#6524](https://github.com/MetaMask/MetaMask-planning/issues/6524)), target 0.
- **Detection:** `grep -rnE 'useSelector\([^,]+,\s*(isEqual|shallowEqual)' ui/`
- **Review action:** Find `getAccounts` (or whichever selector). Fix it to return a stable reference. Remove the `isEqual` argument in the same PR.
- **Why it's wrong:** Deep equality at the consumption site adds O(n) per render and leaves every other consumer of the same selector broken.

### Overuse of `createDeepEqualSelector`

```typescript
// Unnecessary when input is from Immer-managed Redux state
const getTokens = createDeepEqualSelector(
  (state) => state.metamask.tokens,
  (tokens) => transformTokens(tokens),
)
```

- **Baseline:** 129 instances, target ~25 ([#6524](https://github.com/MetaMask/MetaMask-planning/issues/6524)).
- **Detection:** `grep -rn createDeepEqualSelector ui/selectors/`
- **Review action:** For each instance, check if the inputs come from Redux state. If yes, swap to `createSelector` — Immer already gives stable references.
- **The narrow exception:** Inputs that are genuinely not from Immer/Redux state (e.g. derived from a non-Redux source, or passed in as props). These stay.

## Common Pitfalls

| Mistake | Correct approach |
|---|---|
| Accept `useSelector(sel, isEqual)` because "it works" | The underlying selector is broken; fix it and remove the workaround |
| Approve `createDeepEqualSelector` without checking input source | Trace every input to verify it's not already Immer-stable |
| Treat the five patterns as preferences | They are measurably broken — each generates CI warnings |
| Ask the author to justify rather than fix | None of the patterns have a valid use case except the narrow `createDeepEqualSelector` exception above |
| Review only the selector definition, not consumption sites | Pattern 1 (plain function) hides at the call site, not the definition |
