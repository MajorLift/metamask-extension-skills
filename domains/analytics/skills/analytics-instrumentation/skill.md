---
name: analytics-instrumentation
description: Create and update Sentry spans, MetaMetrics events, and Segment events — methodology, policies, common pitfalls
requires:
  - metrametrics-identity
  - segment-governance
---

# Analytics Instrumentation

## When To Use

- Adding or modifying a MetaMetrics (Segment) event
- Adding or modifying a Sentry performance span
- Estimating event or span volume from production data
- Auditing existing instrumentation for correctness

---

## Sentry Spans

### Creating a Span

1. **Register a `TraceName` entry** before writing any span code.
2. **Use `trace()` from `shared/lib/trace.ts`**, not raw `Sentry.startSpan()`. The wrapper handles cross-process context serialization.
3. **Inherit parent automatically** — when no `parentContext` is provided, `trace()` should inherit from `Sentry.getActiveSpan()`. If it doesn't (known bug — #6838), the span appears as a sibling of `pageload` instead of a child.
4. **Add wallet size tags** to any new trace that runs on high-traffic paths:

   ```typescript
   'wallet.is_power_user': accountCount >= 10 || tokenCount >= 50 || txCount >= 100,
   'wallet.size_bucket': getSizeBucket(accountCount, tokenCount, txCount),
   ```

### Cross-Process Context (UI → Background)

The extension has two Sentry hubs. A trace starting in UI and continuing in background requires explicit context propagation across the RPC boundary:

```typescript
// Serialize at UI call site
const context: SerializedTraceContext = {
  _name: TraceName.MyOperation,
  _traceId: span.spanContext().traceId,
  _spanId: span.spanContext().spanId,
}

// Background receives context, creates child span
trace({ name: TraceName.MyOperation, parentContext: context }, async () => { ... })
```

Without propagation: Sentry shows disconnected operations. With propagation: complete tree from user action to RPC call.

### Known Issue: Trace Context Propagation (#6838)

Manual traces created via `trace()` currently appear as siblings of `pageload`, not children. Root cause: no parent inheritance from `Sentry.getActiveSpan()`. Fix pending. When adding new spans, note this limitation — trace hierarchy may not render correctly in Sentry until the fix ships.

### Updating a Span

- Adding a tag: no governance required
- Adding wallet size tags: follow tag naming in `ui/helpers/utils/tags.ts`
- Renaming a `TraceName`: grep all callsites; update enum and all references atomically

---

## MetaMetrics / Segment Events

### Creating an Event

1. **Check `MetaMetricsEventName` enum** — event may already exist.
2. **Check segment-schema** — event may be registered under a different name.
3. **Add to `MetaMetricsEventName`** enum.
4. **Implement `trackEvent` call** — do NOT use `isOptIn: true` outside the onboarding opt-in flow. It strips user identity unconditionally (see Reference Knowledge: metrametrics-identity).
5. **Open Data Council review** before merging. There is no CI enforcement — this step is easy to skip (see Reference Knowledge: segment-governance).
6. **Register in `tracking-plans/metamask-extension.yaml`** in `Consensys/segment-schema`.

### Updating an Event

- Adding a property: requires Data Council review and schema update
- Renaming an event: deprecate old + add new in tracking plan; coordinate with data team on migration window
- Removing an event: confirm no active dashboards depend on it before removing

---

## Volume Estimation via Sentry

When direct Segment access is unavailable, estimate from Sentry production span data:

1. **Find a correlated HTTP endpoint** — one that fires 1:1 with the event.
2. **Query Sentry Traces Explorer** (aggregate mode):
   ```
   span.op:http.client span.description:*{endpoint}*
   ```
3. **Extrapolate:**
   ```
   estimated_actual = sampled_count × (1 / tracesSampleRate)
   ```
4. **Interpret as upper bound** — endpoint may have callers outside the event path.

Caveats: sample population is MetaMetrics opted-in users only; verify current `tracesSampleRate` before calculating.

---

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| `isOptIn: true` on post-onboarding events | Strips user identity for all users; only valid in onboarding flow |
| Ship event without segment-schema registration | No CI gate — add Data Council review explicitly to PR checklist |
| Raw `Sentry.startSpan()` instead of `trace()` | Use `trace()` — it handles cross-process context |
| New trace with no `TraceName` entry | Register enum entry first; unnamed spans are invisible in Sentry |
| Omit wallet tags on high-traffic trace | No power user segmentation possible without them |
| Multiply sampled count by `tracesSampleRate` | Multiply by inverse: `sampled × (1 / rate)` |
| Treat Sentry estimates as exact counts | Probabilistic sample — state confidence interval |
