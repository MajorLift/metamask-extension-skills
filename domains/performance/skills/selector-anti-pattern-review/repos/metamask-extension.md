---
repo: metamask-extension
parent: selector-anti-pattern-review
---

## Paths

- Selector definitions: [`ui/selectors/`](https://github.com/MetaMask/metamask-extension/tree/develop/ui/selectors)
- Selector creators: [`shared/lib/selectors/selector-creators.ts`](https://github.com/MetaMask/metamask-extension/blob/develop/shared/lib/selectors/selector-creators.ts) — source of truth for `createSelector`, `createDeepEqualSelector`, `createResultEqualSelector`, `createShallowResultSelector`
- Component consumption sites: anywhere under `ui/` that calls `useSelector`

## Audit Baselines

From the [Extension Frontend Performance Audit epic](https://github.com/MetaMask/MetaMask-planning/issues/6571) and its [Selector Optimization sub-epic](https://github.com/MetaMask/MetaMask-planning/issues/6524):

| Metric | Baseline | Target |
|---|---|---|
| Reselect CI warnings per test run | 1,696 | <100 |
| `createDeepEqualSelector` instances | 129 | ~25 |
| `useSelector(..., isEqual)` instances | 44 | 0 |
| `.find()` O(n) lookups in selectors | 33 | 0 |

Review action: never allow a PR to increase any of these counters.

## Related Sub-Epic Tickets

These five selectors were identified as P0 root causes in [#6669](https://github.com/MetaMask/MetaMask-planning/issues/6669) — the global re-render cascade. Review any PR touching them with extra scrutiny:

- [`getPendingApprovals`](https://github.com/MetaMask/MetaMask-planning/issues/6673)
- [`pendingConfirmationsSortedSelector`](https://github.com/MetaMask/MetaMask-planning/issues/6674)
- [`getSortedAnnouncementsToShow`](https://github.com/MetaMask/MetaMask-planning/issues/6670)
- `MetaMetricsProvider` context value ([#6640](https://github.com/MetaMask/MetaMask-planning/issues/6640))
- `withRouterHooks` HOC memoization ([#6671](https://github.com/MetaMask/MetaMask-planning/issues/6671))

## Reference Docs

- [Frontend Performance Optimization Guidelines](https://github.com/MetaMask/contributor-docs/pull/159) (contributor-docs PR #159, pending merge)
- [WDYR Technical Analysis](https://github.com/MetaMask/metamask-extension/blob/develop/docs/perf-audit/WDYR_TECHNICAL_ANALYSIS.md)
- [Global Cascade Epic breakdown](https://github.com/MetaMask/metamask-extension/blob/develop/docs/perf-audit/GLOBAL_CASCADE_EPIC.md)
