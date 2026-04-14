---
repo: metamask-extension
parent: effect-anti-pattern-review
---

## Paths

- Component sources: [`ui/`](https://github.com/MetaMask/metamask-extension/tree/develop/ui)
- Shared hooks: [`ui/hooks/`](https://github.com/MetaMask/metamask-extension/tree/develop/ui/hooks)
- Future `useIsMounted`: [#6544](https://github.com/MetaMask/MetaMask-planning/issues/6544) (extension-platform)

## Commands

```bash
# Pattern 1: JSON.stringify in deps
grep -rnE 'useEffect\([^)]*\[.*JSON\.stringify' ui/ --include="*.ts" --include="*.tsx"

# Pattern 3: setInterval / setTimeout
grep -rnE 'setInterval|setTimeout' ui/ --include="*.ts" --include="*.tsx" | wc -l

# Pattern 4: fetch inside useEffect (manual review required for context)
grep -rn 'fetch(' ui/ --include="*.ts" --include="*.tsx"
```

## Audit Baselines

From [#6525](https://github.com/MetaMask/MetaMask-planning/issues/6525):

| Metric | Baseline | Target |
|---|---|---|
| `JSON.stringify` in deps | 4 (in 4 files) | 0 |
| `useEffect` + `setState` | 200+ (in 152 files) | Triaged |
| `setInterval` / `setTimeout` without cleanup | 122 (in 75 files) | 0 |
| `addEventListener` without cleanup | 32 (in 24 files) | 0 |
| `AbortController` usage (good) | 28 (in 8 files) | Growing |
| `isMounted` usage (good) | 63 (in 13 files) | Replaced by [`useIsMounted`](https://github.com/MetaMask/MetaMask-planning/issues/6544) |

Review action: never allow a PR to increase the broken counters.

## Related Tickets

- [#6525](https://github.com/MetaMask/MetaMask-planning/issues/6525) — Epic parent
- [#6545](https://github.com/MetaMask/MetaMask-planning/issues/6545) — 🔴 P0: Remove `JSON.stringify` from deps
- [#6540](https://github.com/MetaMask/MetaMask-planning/issues/6540) — Replace `useEffect` + `setState`
- [#6541](https://github.com/MetaMask/MetaMask-planning/issues/6541) — Ensure interval cleanup
- [#6542](https://github.com/MetaMask/MetaMask-planning/issues/6542) — Add `AbortController`
- [#6543](https://github.com/MetaMask/MetaMask-planning/issues/6543) — Ensure `isMounted` checks
- [#6544](https://github.com/MetaMask/MetaMask-planning/issues/6544) — Create shared `useIsMounted` hook

## Reference Docs

- [Frontend Performance Optimization Guidelines](https://github.com/MetaMask/contributor-docs/pull/159) (contributor-docs PR #159)
- [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)
