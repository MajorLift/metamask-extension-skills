---
name: mv3-service-worker
domain: platform
description: MV3 service worker lifecycle — how Chrome's background termination causes error patterns distinct from MV2
---

# MV3 Service Worker Lifecycle

## MV2 vs MV3

| Manifest | Background | Lifecycle | Timeout Risk |
|----------|------------|-----------|--------------|
| MV3 (Chrome) | Service Worker | Can terminate/restart at any time | High |
| MV2 (Firefox) | Background Page | Always running | None |

## Error Concentration Signal

When an error appears 99%+ in one manifest version, the lifecycle difference is the root cause — not application-level factors that affect both.

| Distribution | Conclusion |
|---|---|
| ~50/50 MV3/MV2 | Application bug (affects both contexts equally) |
| 99%+ MV3 only | MV3 service worker lifecycle is root cause |
| 99%+ MV2 only | Firefox-specific browser behavior |

## Sentry Tag Dimensions

These are independent — do not conflate them.

| Tag | Meaning |
|-----|---------|
| `environment` | Build configuration (production, staging, development) |
| `installType` | How the extension was loaded (normal, development, sideload, admin) |
| `dist` | Manifest version (mv3, mv2) |

A production build can have `installType: development` if loaded unpacked. Filter carefully.

## MV3-Specific Failure Modes

| Failure | Cause |
|---------|-------|
| Background connection unresponsive | Service worker terminated mid-session |
| Keepalive timer not firing | SW sleep before timer callback |
| In-memory state lost | SW restart clears non-persisted state |
| Port disconnected unexpectedly | SW lifecycle ended background port |

## When to Investigate MV3 Separately

- Error volume is 10× higher in Chrome than Firefox
- Error involves background connectivity or keepalive
- Error disappears with `--keep-service-worker-alive` flag
