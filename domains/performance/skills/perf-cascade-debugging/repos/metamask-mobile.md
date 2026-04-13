---
repo: metamask-mobile
parent: perf-cascade-debugging
---

## Commands

```bash
# Enable WDYR (add to index.js entry point)
# import './wdyr'; — see app/wdyr.js or create if absent

# Run Metro bundler (dev)
yarn start

# Audit selector anti-patterns
grep -r "export function get" app/selectors/ --include="*.ts"
grep -r "createDeepEqualSelector" app/ --include="*.ts" | wc -l
grep -r "\.find(" app/selectors/ | wc -l
yarn test 2>&1 | grep -c "result function returned its own inputs"
```

## WDYR Setup (React Native)

Unlike web, WDYR must be imported explicitly — no environment variable toggle:

```javascript
// app/wdyr.js
import React from 'react';
if (__DEV__) {
  const whyDidYouRender = require('@welldone-software/why-did-you-render');
  whyDidYouRender(React, { trackAllPureComponents: false });
}

// index.js (first import)
import './app/wdyr';
```

## File Paths

| Content | Path |
|---------|------|
| Selectors | `app/selectors/` |
| Redux store | `app/store/` |
| State shape | `app/core/Engine.ts` |
