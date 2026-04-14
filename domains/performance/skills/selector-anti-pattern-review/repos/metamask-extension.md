---
repo: metamask-extension
parent: selector-anti-pattern-review
---

## Paths

- Selector definitions: [`ui/selectors/`](https://github.com/MetaMask/metamask-extension/tree/develop/ui/selectors)
- Selector creators: [`shared/lib/selectors/selector-creators.ts`](https://github.com/MetaMask/metamask-extension/blob/develop/shared/lib/selectors/selector-creators.ts) — source of truth for `createSelector`, `createDeepEqualSelector`, `createResultEqualSelector`, `createShallowResultSelector`
- Controller state shape: [`app/scripts/metamask-controller.js`](https://github.com/MetaMask/metamask-extension/blob/develop/app/scripts/metamask-controller.js)
- Component consumption sites: anywhere under [`ui/`](https://github.com/MetaMask/metamask-extension/tree/develop/ui) that calls `useSelector`

## Commands

```bash
# Enable WDYR for post-merge diagnosis
ENABLE_WHY_DID_YOU_RENDER=true yarn start

# DevTools
yarn start:dev
yarn devtools:react
yarn devtools:redux

# Pre-merge grep checklist
grep -rE 'export function get' ui/selectors/ --include="*.ts"
grep -rn createDeepEqualSelector ui/ --include="*.ts" | wc -l
grep -rnE 'useSelector\([^,]+,\s*(isEqual|shallowEqual)' ui/ --include="*.ts" --include="*.tsx" | wc -l
grep -rnE '\.find\(' ui/selectors/ | wc -l

# Block-on-warning check
yarn test:unit 2>&1 | grep -c 'result function returned its own inputs'
```

## Selector Creators

`shared/lib/selectors/selector-creators.ts`

| Creator | Use Case |
|---------|----------|
| `createSelector` | Standard memoization (default) |
| `createDeepEqualSelector` | Genuinely unstable inputs (rare — see [narrow exception](../skill.md#overuse-of-createdeepequalselector)) |
| `createResultEqualSelector` | Unstable outputs requiring deep comparison |
| `createShallowResultSelector` | Unstable outputs, shallow comparison sufficient |

## Audit Baselines

From the [Extension Frontend Performance Audit epic](https://github.com/MetaMask/MetaMask-planning/issues/6571) and its [Selector Optimization sub-epic](https://github.com/MetaMask/MetaMask-planning/issues/6524):

| Metric | Baseline | Target |
|---|---|---|
| Reselect CI warnings per test run | 1,696 | <100 |
| `createDeepEqualSelector` instances | 129 | ~25 |
| `useSelector(..., isEqual)` instances | 44 | 0 |
| `.find()` O(n) lookups in selectors | 33 | 0 |

Review action: never allow a PR to increase any of these counters.

## P0 Root-Cause Selectors

Five targets identified as P0 root causes in [#6669](https://github.com/MetaMask/MetaMask-planning/issues/6669). Review any PR touching them with extra scrutiny:

- [`getPendingApprovals`](https://github.com/MetaMask/MetaMask-planning/issues/6673)
- [`pendingConfirmationsSortedSelector`](https://github.com/MetaMask/MetaMask-planning/issues/6674)
- [`getSortedAnnouncementsToShow`](https://github.com/MetaMask/MetaMask-planning/issues/6670)
- `MetaMetricsProvider` context value ([#6640](https://github.com/MetaMask/MetaMask-planning/issues/6640))
- `withRouterHooks` HOC memoization ([#6671](https://github.com/MetaMask/MetaMask-planning/issues/6671))

## Reference Docs

- [Frontend Performance Optimization Guidelines](https://github.com/MetaMask/contributor-docs/pull/159) (contributor-docs PR #159, pending merge)
- [WDYR Technical Analysis](https://github.com/MetaMask/metamask-extension/blob/develop/docs/perf-audit/WDYR_TECHNICAL_ANALYSIS.md)
- [Global Cascade Epic breakdown](https://github.com/MetaMask/metamask-extension/blob/develop/docs/perf-audit/GLOBAL_CASCADE_EPIC.md)
