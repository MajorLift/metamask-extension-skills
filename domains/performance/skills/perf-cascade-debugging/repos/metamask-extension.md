---
repo: metamask-extension
parent: perf-cascade-debugging
---

## Commands

```bash
# Enable WDYR
ENABLE_WHY_DID_YOU_RENDER=true yarn start

# DevTools
yarn start:dev
yarn devtools:react
yarn devtools:redux

# Audit selector anti-patterns
grep -r "export function get" ui/selectors/ --include="*.ts"
grep -r "createDeepEqualSelector" ui/ --include="*.ts" | wc -l
grep -r "\.find(" ui/selectors/ | wc -l
yarn test:unit 2>&1 | grep -c "result function returned its own inputs"
```

## Selector Creators

`shared/lib/selectors/selector-creators.ts`

| Creator | Use Case |
|---------|----------|
| `createSelector` | Standard memoization (default) |
| `createDeepEqualSelector` | Genuinely unstable inputs (rare) |
| `createResultEqualSelector` | Unstable outputs requiring deep comparison |
| `createShallowResultSelector` | Unstable outputs, shallow comparison sufficient |

## File Paths

| Content | Path |
|---------|------|
| UI selectors | `ui/selectors/` |
| Selector creators | `shared/lib/selectors/selector-creators.ts` |
| Controller state shape | `app/scripts/metamask-controller.js` |

