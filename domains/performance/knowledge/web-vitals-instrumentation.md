---
name: web-vitals-instrumentation
domain: performance
description: Web Vitals in browser extensions — production monitoring vs benchmark collection, INP/TBT as runtime metrics
---

# Web Vitals Instrumentation

## Extension Context

Page load metrics (TTFB, FCP) are less relevant for extensions — popup opens fast, no traditional navigation.
**Runtime interaction metrics** (INP, TBT) are high-value for extension UX quality.

| Metric | Measures | Extension relevance |
|--------|----------|---------------------|
| INP | Worst p98 interaction delay per session | Every button, swap, confirmation |
| TBT | Total blocking time during load | Bounded flow measurement |
| LCP | Largest paint | Less relevant (fast popup open) |
| CLS | Layout shift | Minor relevance |

## INP vs Distributed Tracing

These are orthogonal — same operation can have different outcomes:

| Dimension | Web Vitals | Distributed Tracing |
|-----------|------------|---------------------|
| Question | "How did user perceive it?" | "Which controller caused it?" |
| Scope | User perception | Operation attribution |

Synergy: `INP spike → correlate by interactionId → trace → root cause`

## Production vs Benchmarks

| Context | Library | TBT | Timing |
|---------|---------|-----|--------|
| Production | `web-vitals/attribution` | ✗ | On page hide |
| Benchmarks | Direct `PerformanceObserver` | ✓ | On demand |

**Why no TBT in production:** TBT is cumulative and unbounded — grows indefinitely in open sessions. INP per-interaction is more meaningful for real users.

**Why different approaches:** `onINP()` fires on `visibilitychange`/`pagehide` — mid-session benchmark queries won't get a value. Use direct `performance.getEntriesByType('event')` with p98 calculation instead.

## Attribution Import

`web-vitals/attribution` is a module import path, not a separate package. Tree-shaking applies — no significant bundle size increase.

```typescript
// Use attribution build from the start
import { onINP, onLCP, onCLS } from 'web-vitals/attribution';

onINP(({ value, attribution }) => {
  // attribution.eventTarget, attribution.eventType → "which button caused it"
});
```

## Benchmark Collection

Extend `collectMetrics()` in `driver.js` with direct Performance API:

```javascript
// Long Tasks → TBT
const longTasks = performance.getEntriesByType('longtask');
results.tbt = longTasks.reduce((sum, t) => sum + Math.max(0, t.duration - 50), 0);

// LCP
const lcpEntries = performance.getEntriesByType('largest-contentful-paint');
results.lcp = lcpEntries[lcpEntries.length - 1]?.startTime || 0;
```

No `stateHooks` extension needed. `stateHooks.getCustomTraces()` is only for custom spans from `shared/lib/trace.ts`.
