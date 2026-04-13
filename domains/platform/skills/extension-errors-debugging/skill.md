---
name: extension-errors-debugging
description: Diagnose browser extension errors — MV3 vs MV2, background/UI context, error tagging
requires:
  - extension-architecture
  - mv3-service-worker
---

# Extension Errors Debugging

## When To Use

- Errors appear in one manifest version but not the other
- Background connection or keepalive failures
- Errors that are hard to reproduce in development (only manifest in prod)
- Diagnosing Sentry errors before attributing root cause

## Workflow

1. **Check distribution** — Filter by `dist` tag. Is the error 99%+ MV3, MV2, or split?
2. **Classify root cause** — MV3-only → service worker lifecycle. Split → application logic. MV2-only → Firefox behavior.
3. **Identify context** — Is the error from background (`app/scripts/`) or UI (`ui/`)? Stack trace file paths reveal this.
4. **Check error tags** — Verify `environment`, `installType`, and `dist` are what you expect (see Reference Knowledge — these are independent dimensions).
5. **Reproduce** — Use `dist` tag filter to reproduce in the right manifest version.

## Context Identification from Stack Traces

| Path prefix in trace | Context |
|---------------------|---------|
| `app/scripts/controllers/` | Background controller |
| `app/scripts/metamask-controller.js` | Background aggregator |
| `ui/components/` or `ui/pages/` | UI (React) |
| `shared/` | Either — shared module |

## Background-Specific Error Types

| Error | MV3 Root Cause | Not Application Logic |
|-------|---------------|----------------------|
| Background connection unresponsive | SW terminated | ✓ |
| Port disconnected | SW lifecycle ended | ✓ |
| Keepalive timer missed | SW slept before callback | ✓ |

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Attribute 99% MV3 error to application code | Check if error requires running background; MV3 SW termination is likely root cause |
| Use `environment` to filter for dev builds | Use `installType: development` — a prod build can be sideloaded |
| Conflate `dist` and `environment` | They are independent; filter both when needed |
| Reproduce MV2-only error in Chrome | Use Firefox; `installType` doesn't replicate MV3/MV2 lifecycle difference |
