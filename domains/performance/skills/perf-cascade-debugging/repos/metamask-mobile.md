---
repo: metamask-mobile
parent: perf-cascade-debugging
---

## Commands

```bash
# Enable WDYR (env var gate, same as extension)
ENABLE_WHY_DID_YOU_RENDER=true yarn start

# Audit selector anti-patterns
grep -r "export function get" app/selectors/ --include="*.ts"
grep -r "createDeepEqualSelector" app/ --include="*.ts" | wc -l
grep -r "\.find(" app/selectors/ | wc -l
```

## WDYR

Mobile has `wdyr.js` at the repo root. It is gated on `__DEV__ && process.env.ENABLE_WHY_DID_YOU_RENDER === 'true'` and imported from the entry file. No manual setup is required — flip the env var and restart metro.

Current configuration (at time of authoring): `trackAllPureComponents: true`, `onlyLogs: true` (Metro/Hermes console doesn't group well).

## File Paths

| Content | Path |
|---------|------|
| Selectors | `app/selectors/` |
| Redux store | `app/store/` |
| Engine / state shape | `app/core/Engine/Engine.ts` |
| WDYR setup | `wdyr.js` (repo root) |
