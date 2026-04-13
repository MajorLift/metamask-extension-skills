---
repo: metamask-extension
parent: shape-change-refactoring
---

## E2E Crash Signal

UI render crashes manifest as the `.controller-loaded` class never being added to the DOM, which causes E2E tests to timeout waiting for it. This looks like infrastructure flakiness — it isn't.

```
UI initialization fails → `controller-loaded` class never added
    ↓
E2E waiting for `.controller-loaded` times out
    ↓
First triage question: "What did this PR change that affects this test?"
```

## Search Commands

```bash
# All useContext consumers in UI
grep -rn "useContext(ContextName)" ui/ --include="*.js" --include="*.tsx"

# Whole-assignment pattern (no destructuring braces)
grep -rn "useContext(" ui/ --include="*.js" | grep -v "const {" | grep -v "= use"
```

## Mixed Codebase Note

`ui/` is mixed JS/TSX. Assume any `.js` consumer is untyped. TypeScript strict mode does not apply to `.js` files even with `allowJs`.

## Known Historical Cases

`MetaMetricsContext` — changed from function-with-properties to object. `StorageErrorToast` used whole-assignment; crashed silently until caught in E2E.
