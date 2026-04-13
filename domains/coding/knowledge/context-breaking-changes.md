---
name: context-breaking-changes
domain: coding
description: React Context value structure changes break consumers using whole-assignment access silently at runtime
---

# Context Breaking Changes

## The Pattern

Context consumers can access the value in two ways:

```javascript
// Pattern A: Destructure specific properties (SAFE with any value shape)
const { trackEvent } = useContext(MyContext);

// Pattern B: Whole-assignment (BREAKS if value shape changes)
const trackEvent = useContext(MyContext); // assumes context IS the function
```

## Why Refactors Break Silently

| Reason | Impact |
|--------|--------|
| Pattern A consumers work with any value shape | No breakage, no signal |
| Pattern B breaks only at runtime when called | Not a compile error unless consumers are typed |
| TypeScript catches it — but only if consumers are typed | Typed files safe; untyped files fail at runtime |
| Mocks may match old structure | Tests pass; production breaks |
| Large files hide single bad usage | 900-line file, one bad usage → easy to miss |

## Cascade Effect

One broken consumer crashes the entire UI:

```
Component throws during render
    ↓
React error boundary (or full crash)
    ↓
UI initialization fails → `controller-loaded` class never added
    ↓
E2E tests waiting for `.controller-loaded` timeout
    ↓
Symptom looks like infrastructure flakiness, not a code bug
```

## Detection Procedure

When changing context value structure:

```bash
# 1. Find ALL consumers
grep -rn "useContext(MyContext)" --include="*.js" --include="*.tsx"

# 2. For each match, check for whole-assignment pattern:
#    const x = useContext(...)  ← DANGEROUS
#    const { x } = useContext(...)  ← SAFE

# 3. Trace how the variable is used — called as function or property-accessed?
```

## First Question When E2E Fails

"Is this test related to the changes in this PR?"
- If test only fails on this branch (not main) → your changes broke it
- Find the connection between the test's assertion and what you changed
