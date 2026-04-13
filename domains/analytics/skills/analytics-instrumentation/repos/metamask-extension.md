---
repo: metamask-extension
parent: analytics-instrumentation
---

## Key Files

| Content | Path |
|---------|------|
| Sentry trace wrapper | `shared/lib/trace.ts` |
| Trace name enum | `shared/constants/traces.ts` → `TraceName` |
| Wallet size tags | `ui/helpers/utils/tags.ts` |
| MetaMetrics controller | `app/scripts/controllers/metametrics-controller.ts` |
| Event enum | `shared/constants/metametrics.ts` → `MetaMetricsEventName` |
| Sentry setup + sample rate | `app/scripts/lib/setupSentry.js` → `getTracesSampleRate()` |
| Segment tracking plan | `Consensys/segment-schema` → `tracking-plans/metamask-extension.yaml` |

## Sentry Sample Rate

```bash
grep -n "tracesSampleRate" app/scripts/lib/setupSentry.js
# Production: 0.0075 (0.75%) → multiplier ≈ 133×
# Verify before calculating — value has changed before
```

## Sentry Traces Explorer Query (Volume Estimation)

```
Environment: production | Time range: 30 days | Mode: aggregate
Query: span.op:http.client span.description:*{endpoint}*
Group by: span.description, transaction
Sort: -count(span.duration)
```

## Wallet Size Tag Thresholds

| Bucket | Accounts | Tokens | Transactions |
|--------|----------|--------|--------------|
| `small` | < 3 | < 10 | < 20 |
| `medium` | 3–9 | 10–49 | 20–99 |
| `large` | 10–29 | 50–149 | 100–499 |
| `xl` | 30+ | 150+ | 500+ |
| `is_power_user` | ≥ 10 OR | ≥ 50 OR | ≥ 100 |

## Detect `isOptIn` Misuse

```bash
grep -rn "isOptIn: true" app/scripts/ ui/ --include="*.ts" --include="*.tsx"
# Any occurrence outside creation-successful.tsx is suspect
```

## Open Issues

| Issue | Status | Impact |
|-------|--------|--------|
| #6838 Fix trace context propagation | In progress | Manual spans appear as siblings of pageload |
| #6858 Sentry SDK v8 → v10 upgrade | Planned | Improves OTel v2 support |
| #6733 Wallet size tags on 10+ traces | Planned | Required for power user segmentation |

## Data Council Contact

- Slack: `#metamask-metametrics`
- Team: `@consensys/data-council`
