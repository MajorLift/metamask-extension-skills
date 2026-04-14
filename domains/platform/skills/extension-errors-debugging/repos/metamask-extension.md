---
repo: metamask-extension
parent: extension-errors-debugging
---

## Sentry Filters

Filter by `dist` tag to isolate manifest version:
- `dist:mv3` — Chrome builds
- `dist:mv2` — Firefox builds

Filter by `installType` to exclude developer-loaded builds:
- `installType:normal` — store-installed
- `installType:development` — sideloaded (unpacked); includes production builds loaded via developer mode

## Build Commands

```bash
# MV3 development (Chrome, service worker)
yarn start

# MV2 development (Firefox, background page)
yarn start:mv2

# Production build (both manifests)
yarn dist

# After dependency changes — regenerate LavaMoat policies
yarn lavamoat:auto
```

## Background Keepalive

Background keepalive is managed in `app/scripts/background.js` (the `saveTimestamp` setInterval pattern). Keepalive failures are almost always MV3-only. Check if `keepalive` timers are referenced in the failing stack trace before assuming application bug.

## Controller-Messenger Pattern

Controllers communicate via `ControllerMessenger` (`@metamask/base-controller`). A controller's public API is its registered actions and events — not direct method calls. Cross-controller calls that bypass the messenger will not work across the background/UI boundary.
