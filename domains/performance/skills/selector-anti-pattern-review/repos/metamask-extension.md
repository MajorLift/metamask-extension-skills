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

## Regression Watchlist

These five root-cause selectors and HOCs were fixed under the [P0 Break Global Re-render Cascade epic (#6669)](https://github.com/MetaMask/MetaMask-planning/issues/6669). Re-introducing any of their original patterns brings back the 125-200-re-render-per-action cascade. Block any PR that regresses them:

| Target | Original pattern | Fix ticket |
|---|---|---|
| `getPendingApprovals` | Plain function returned `Object.values()` on every call | [#6673](https://github.com/MetaMask/MetaMask-planning/issues/6673) (closed) |
| `pendingConfirmationsSortedSelector` | Plain function chained filter/sort | [#6674](https://github.com/MetaMask/MetaMask-planning/issues/6674) (closed) |
| `getSortedAnnouncementsToShow` | Plain function chained `Object.values` / filter / sort | [#6670](https://github.com/MetaMask/MetaMask-planning/issues/6670) (closed) |
| `MetaMetricsProvider` context value | Unstable object literal + `useLocation()` mutation | [#6640](https://github.com/MetaMask/MetaMask-planning/issues/6640) (closed) |
| `withRouterHooks` HOC | Passed `useParams()` result directly as a new object | [#6671](https://github.com/MetaMask/MetaMask-planning/issues/6671) (closed) |

## Residual Cleanup Tickets

Still open under [#6669](https://github.com/MetaMask/MetaMask-planning/issues/6669) — compensating identity wrappers that became redundant after the P0 fixes:

- [#6663](https://github.com/MetaMask/MetaMask-planning/issues/6663) — Remove 3 identity wrappers (confirmations)
- [#6672](https://github.com/MetaMask/MetaMask-planning/issues/6672) — Remove 7 identity wrappers (`selectors.js`)
- [#6664](https://github.com/MetaMask/MetaMask-planning/issues/6664) — Remove snaps/ identity wrappers
- [#6665](https://github.com/MetaMask/MetaMask-planning/issues/6665) — Remove multichain identity wrapper
- [#6537](https://github.com/MetaMask/MetaMask-planning/issues/6537) — Audit `createDeepEqualSelector` usage (129 → ~25)

## Example Fix Methodology

[PR #37147](https://github.com/MetaMask/metamask-extension/pull/37147) fixed `getInternalAccounts` as the canonical example. Before: `createSelector(selectInternalAccounts, (accounts) => accounts)` (identity function, defeats memoization). After: `createSelector(getInternalAccountsObject, (accounts) => Object.values(accounts))`. Impact: 50+ component re-renders eliminated per state update.

## Reference

- [Frontend Performance Optimization Guidelines](https://github.com/MetaMask/contributor-docs/pull/159) (contributor-docs PR #159, pending merge)
