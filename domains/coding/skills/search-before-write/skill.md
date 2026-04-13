---
maturity: experimental
name: search-before-write
description: Search for existing abstractions before writing new logic — in the PR, in the codebase, in tests
---

# Search Before Write

## When To Use

- About to write a utility function or helper
- About to inline logic that could already exist
- Implementing anything a senior engineer might describe as "standard"
- Before creating a new test fixture

## Workflow

1. **Search the PR diff first** — Is there already a function doing this in a file you touched?
2. **Search the codebase** — Grep for the function name pattern, input/output types, or concept.
3. **Check test fixtures** — Existing fixtures may already cover your case.
4. **Only then write new logic** — If nothing exists, write it once in the right place.

## Search Commands

```bash
# Find similar utility patterns
grep -r "functionNamePattern" shared/lib/ ui/helpers/ --include="*.ts"

# Find existing test fixtures
find test/e2e/fixtures/ -name "*.json" | xargs grep "relevantKey"

# Find selector creators (don't write inline selector logic)
grep -r "createSelector" ui/selectors/ --include="*.ts" | grep "yourConcept"
```

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Write O(n) lookup inline | Check if state is already normalized — use `state.items[id]` |
| Write a custom deep-clone | Search for existing utilities in `shared/lib/` |
| Copy fixture data from another test | Extend the existing fixture or extract to shared fixture file |
| Write a new selector from scratch | Check `ui/selectors/selectors.js` (~2500 lines) and feature selector files |
| Inline a `createSelector` in a component | Selectors belong in `ui/selectors/` — find or add one there |

## Test Fixture Rule

Verify fixture content matches the comment/test description before committing. Mismatched fixtures cause tests that pass in isolation but fail in context.
