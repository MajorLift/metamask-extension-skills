---
maturity: experimental
name: shape-change-refactoring
description: Change the shape of a value with multiple consumers without silently breaking whole-assignment callers
---

# Shape Change Refactoring

## When To Use

Any change to the shape of a value that has multiple consumers and isn't fully type-checked across all of them:

- React Context value (function → object, adding/removing properties)
- Custom hook return value
- Redux selector return shape
- Module exports (`export default` object reshape)
- Function return type
- API or RPC response shape

## The Failure Mode

Two consumer access patterns produce different breakage characteristics:

```javascript
const { trackEvent } = useContext(MyContext)  // ✓ destructure — tolerates additive shape change
const ctx = useContext(MyContext)              // ✗ whole-assign — binds the entire shape
```

| Pattern | Break-time | Surfaces as type error? |
|---|---|---|
| Destructure | Compile time (if typed) or never | Yes (typed) / No (untyped) |
| Whole-assign | Call time, only when accessed property doesn't exist | Only if consumer file is typed |

In a mixed JS/TS codebase, untyped whole-assign consumers fail **silently at runtime** — no compile error, mocks may match the old structure so tests still pass, the only signal is a crashed render or a thrown property access.

## Workflow

1. **Grep all consumers** before touching the producer.

   ```bash
   grep -rn "useContext(ContextName)"  --include="*.{js,jsx,ts,tsx}"
   grep -rn "useMyHook("               --include="*.{js,jsx,ts,tsx}"
   grep -rn "from '@/path/to/module'"  --include="*.{js,jsx,ts,tsx}"
   ```

2. **Classify each consumer** — destructure or whole-assign?

3. **Fix whole-assign consumers first** — convert to destructure or explicit property access. Land this in a separate commit before the shape change.

4. **Change the producer shape**.

5. **Verify** — typecheck, unit tests, E2E. A test that times out waiting for a UI ready signal often means a component crashed during render — find the unfixed consumer.

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Search only for the producer's import | Search for the call site (`useContext(X)`, `useMyHook()`) — consumers may not import the producer directly |
| Trust TypeScript to catch it | Only catches typed consumers; `.js` files in mixed codebases fail silently |
| Update mocks to match new shape, then change producer | Mocks tracking the old shape mask the bug — fix consumers, not mocks |
| Change producer + fix consumers in one commit | Two commits — easier to bisect when a silent break surfaces later |
