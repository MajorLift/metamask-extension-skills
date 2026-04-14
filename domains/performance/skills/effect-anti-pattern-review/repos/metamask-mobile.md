---
repo: metamask-mobile
parent: effect-anti-pattern-review
---

## Paths

- Component sources: [`app/`](https://github.com/MetaMask/metamask-mobile/tree/main/app)
- Shared hooks: [`app/component-library/hooks/`](https://github.com/MetaMask/metamask-mobile/tree/main/app/component-library/hooks)

## Commands

```bash
# Pattern 1: JSON.stringify in deps
grep -rnE 'useEffect\([^)]*\[.*JSON\.stringify' app/ --include="*.ts" --include="*.tsx"

# Pattern 3: setInterval / setTimeout
grep -rnE 'setInterval|setTimeout' app/ --include="*.ts" --include="*.tsx" | wc -l

# Pattern 4: fetch inside useEffect (manual review required for context)
grep -rn 'fetch(' app/ --include="*.ts" --include="*.tsx"
```

## Differences from Extension

- Mobile has no parallel to the [#6525 extension baselines](https://github.com/MetaMask/MetaMask-planning/issues/6525). The patterns apply identically, but repo-specific counts have not been published.
- Mobile has no shared `useIsMounted` hook yet. Prefer `AbortController` for all new async effects.
- React Native's `fetch` behaves identically to browser `fetch` for cancellation purposes.

## Reference Docs

- [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)
