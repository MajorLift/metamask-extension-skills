---
maturity: experimental
name: context-refactoring
description: Safely refactor React Context value structure without silently breaking whole-assignment consumers
---

# Context Refactoring

## When To Use

- Changing the shape of a React Context value (function → object, adding/removing properties)
- Wrapping or unwrapping a context value
- Any PR that touches a `createContext` definition or its `.Provider` usage

## Workflow

1. **Grep ALL consumers** before touching anything.

   ```bash
   grep -rn "useContext(ContextName)" --include="*.js" --include="*.tsx"
   ```

2. **Classify each consumer** — safe or dangerous:

   ```javascript
   const { trackEvent } = useContext(MyContext)  // ✓ destructure — safe
   const trackEvent = useContext(MyContext)       // ✗ whole-assignment — breaks on shape change
   ```

3. **Fix whole-assignment consumers** before changing the context value shape.

4. **Change the context value**.

5. **Verify** — run TypeScript and E2E. If `.controller-loaded` timeout appears in E2E, a component crashed on render — find the bad consumer.

## Why Whole-Assignment Consumers Break Silently

| Reason | Impact |
|--------|--------|
| Pattern A (destructure) works with any shape | No breakage, no signal |
| Pattern B (whole-assign) breaks only at call time | Not a type error unless consumer is typed |
| Mocks often match old structure | Tests pass; production breaks |
| Large files hide one bad usage | Easy to miss in a 900-line file |

## E2E Failure Signal

```
UI initialization fails → `controller-loaded` class never added
    ↓
E2E tests waiting for `.controller-loaded` timeout
    ↓
Looks like infrastructure flakiness — it's a code bug
```

First question when E2E fails on this branch only: "What did my PR change that could affect this test?" Trace from the test's DOM assertion back to the component.

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Search only for the context import | Search for `useContext(ContextName)` — consumers may not import the context directly |
| Assume TypeScript will catch it | Only if the consumer file is typed; `.js` files fail silently |
| Fix consumers after changing shape | Fix consumers first; the change is a breaking migration |
