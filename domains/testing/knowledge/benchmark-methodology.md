---
name: benchmark-methodology
domain: testing
description: E2E benchmark design and analysis — session hygiene, round-based reporting, artifact grouping, signal isolation
---

# Benchmark Methodology

## Session Hygiene

System state degrades over long benchmark sessions — background load, memory pressure, I/O contention inflate variance and can **invert** treatment effects.

**Rule:** Run reference/critical benchmarks first. If a late round contradicts clean earlier rounds, suspect session degradation before concluding the early data was wrong.

## Per-Round Reporting

Pooling all rounds blindly dilutes signal when later rounds are noisy. Small N with large effect size can be more defensible than large N with diluted signal.

**Rule:** Compute per-round statistics first. Report the cleanest signal for each metric with explicit round attribution. Show pooled data as supplementary, not primary.

| Decision | Rationale |
|----------|-----------|
| Per-round first | Detect instability before pooling |
| Explicit round attribution | Makes noise visible |
| Pooled as supplementary | Avoids dilution masking real effects |

## Artifact Grouping

Benchmark artifact filenames: `{test}-iteration-{N}-{ISO-timestamp}.json`

Unpadded iteration numbers (`1, 2, 10`) produce incorrect lexicographic sort: `iteration-1, iteration-10, iteration-2`.

**Rule:** Always extract the ISO timestamp and group by time range — never use filename sort position or array index as proxy for round membership.

```javascript
// Extract seconds-since-midnight for round assignment
const match = filename.match(/T(\d{2})-(\d{2})-(\d{2})/);
const secondsOfDay = +match[1] * 3600 + +match[2] * 60 + +match[3];
```

## Benchmark Design

Design each benchmark flow to exercise ONE optimization vector as its primary signal source. Maximize the ratio of optimization-affected time to total measured time.

| Optimization | Cascade vector | Flow design |
|---|---|---|
| Selector memoization | State mutations | Multi-confirmation queue |
| Context memoization | Any state update | Account switching cycle |
| HOC stabilization | Route changes | Rapid route cycling |

## Metric Collection

Add metrics in `test/e2e/webdriver/driver.js` → `collectMetrics()`:

```javascript
// TBT via Long Tasks
const longTasks = performance.getEntriesByType('longtask');
results.tbt = longTasks.reduce((sum, t) => sum + Math.max(0, t.duration - 50), 0);

// LCP
results.lcp = performance.getEntriesByType('largest-contentful-paint').pop()?.startTime || 0;
```

Define new metrics in `test/e2e/benchmarks/constants.ts` → `ALL_METRICS`.

**No `stateHooks` needed** for Performance API metrics. `stateHooks.getCustomTraces()` is only for custom spans from `shared/lib/trace.ts`.
