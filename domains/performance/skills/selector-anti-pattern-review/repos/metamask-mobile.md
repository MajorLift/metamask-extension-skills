---
repo: metamask-mobile
parent: selector-anti-pattern-review
---

## Paths

- Selector definitions: [`app/selectors/`](https://github.com/MetaMask/metamask-mobile/tree/main/app/selectors)
- Redux store: [`app/store/`](https://github.com/MetaMask/metamask-mobile/tree/main/app/store)
- Engine / state shape: [`app/core/Engine/Engine.ts`](https://github.com/MetaMask/metamask-mobile/blob/main/app/core/Engine/Engine.ts)
- WDYR setup: [`wdyr.js`](https://github.com/MetaMask/metamask-mobile/blob/main/wdyr.js) at repo root
- Component consumption sites: anywhere under [`app/`](https://github.com/MetaMask/metamask-mobile/tree/main/app) that calls `useSelector`

## Commands

```bash
# Enable WDYR (env var gate, same as extension)
ENABLE_WHY_DID_YOU_RENDER=true yarn start

# Pre-merge grep checklist
grep -rE 'export function get' app/selectors/ --include="*.ts"
grep -rn createDeepEqualSelector app/ --include="*.ts" | wc -l
grep -rnE 'useSelector\([^,]+,\s*(isEqual|shallowEqual)' app/ --include="*.ts" --include="*.tsx" | wc -l
grep -rnE '\.find\(' app/selectors/ | wc -l
```

## WDYR

Mobile has `wdyr.js` at the repo root. It is gated on `__DEV__ && process.env.ENABLE_WHY_DID_YOU_RENDER === 'true'` and imported from the entry file. No manual setup required — flip the env var and restart Metro.

Current configuration (at time of authoring): `trackAllPureComponents: true`, `onlyLogs: true` (Metro/Hermes console doesn't group well).

## Differences from Extension

- Mobile has no parallel to the Extension Frontend Performance Audit epic baselines. The same patterns apply, but repo-specific counts have not been published.
- Mobile has no documented P0 root-cause list. Apply the [pre-merge checklist](../skill.md#mode-a-pre-merge-review-grep-driven) on every selector-touching PR.
- React Compiler adoption and `"use no memo"` opt-outs are extension-only at this time.
