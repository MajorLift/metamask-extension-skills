---
repo: metamask-extension
parent: context-refactoring
---

## Search Commands

```bash
# Find all consumers of a specific context
grep -rn "useContext(MetaMetricsContext)" ui/ --include="*.js" --include="*.tsx"

# Find whole-assignment pattern (no destructuring braces)
grep -rn "useContext(" ui/ --include="*.js" | grep -v "const {" | grep -v "= use"
```

## Known Historical Cases

`MetaMetricsContext` — changed from function-with-properties to object. `StorageErrorToast` used whole-assignment; crashed silently until caught in E2E.

## TypeScript Coverage

`ui/` is mixed JS/TSX. Assume any `.js` consumer is untyped. TypeScript strict mode does not apply to `.js` files even with `allowJs`.
