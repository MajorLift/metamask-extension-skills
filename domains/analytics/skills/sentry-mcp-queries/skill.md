---
name: sentry-mcp-queries
description: Query Sentry via MCP tools — error triage, tag distribution analysis, volume estimation, replay and profile retrieval
---

# Sentry MCP Queries

## When To Use

- Investigating a production error before attributing root cause
- Checking MV3 vs MV2 error distribution
- Estimating event or span volume from production data
- Retrieving session replay or profiling data for a specific event
- Running AI-assisted root cause analysis on an issue

## Setup

```
mcp__sentry__whoami           → confirm authenticated org/user
mcp__sentry__find_organizations → get org slug
mcp__sentry__find_projects    → get project slug(s)
```

Run these once per session. All subsequent tools require `organization_slug` and usually `project_slug`.

## Workflow: Error Triage

1. `mcp__sentry__search_issues` — find the issue by title, fingerprint, or keyword
2. `mcp__sentry__get_issue_tag_values` — check `dist` tag distribution before attributing root cause
3. If 99%+ one dist value → platform lifecycle root cause (see platform/extension-errors-debugging)
4. `mcp__sentry__search_issue_events` — get individual events for stack trace detail
5. `mcp__sentry__analyze_issue_with_seer` — AI-assisted root cause if pattern isn't clear

## Workflow: Volume Estimation

1. `mcp__sentry__search_events` — aggregate mode, filter by `span.op:http.client` + endpoint
2. Read sampled span count from results
3. Extrapolate: `estimated = sampled × (1 / tracesSampleRate)`
4. Treat as upper bound (endpoint may have other callers)

## Workflow: Replay and Profile Retrieval

1. `mcp__sentry__search_issue_events` — find an event ID with replay or profile attached
2. `mcp__sentry__get_replay_details` — session replay for that event
3. `mcp__sentry__get_profile_details` — profiling data for that event

## Tag Filters

Apply these to narrow results before reading counts or drawing conclusions:

| Tag | Values | Use |
|-----|--------|-----|
| `dist` | `mv3`, `mv2` | Isolate by manifest version |
| `environment` | `production`, `staging` | Exclude non-prod noise |
| `installType` | `normal`, `development`, `sideload`, `admin` | Exclude developer-loaded builds |

**Do not conflate `environment` and `installType`** — a production build can have `installType:development` if loaded unpacked.

## MCP Tool Reference

| Tool | Purpose |
|------|---------|
| `mcp__sentry__whoami` | Confirm auth, get org context |
| `mcp__sentry__find_organizations` | List orgs and slugs |
| `mcp__sentry__find_projects` | List projects and slugs |
| `mcp__sentry__search_issues` | Search error/performance issues |
| `mcp__sentry__search_events` | Search individual events (span data, aggregate mode) |
| `mcp__sentry__search_issue_events` | Events within a specific issue |
| `mcp__sentry__get_issue_tag_values` | Tag distribution for an issue (dist, env, installType) |
| `mcp__sentry__get_replay_details` | Session replay for a specific event |
| `mcp__sentry__get_profile_details` | Profiling data for a specific event |
| `mcp__sentry__get_sentry_resource` | Fetch any Sentry resource by URL |
| `mcp__sentry__analyze_issue_with_seer` | AI-assisted root cause analysis |
| `mcp__sentry__find_releases` | List releases — useful for regression bisection |
| `mcp__sentry__find_teams` | List teams and their project ownership |

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Attribute root cause before checking `dist` distribution | Check tag values first — 99%+ MV3 → lifecycle, not app logic |
| Use raw sampled count as event volume | Multiply by `1 / tracesSampleRate` to extrapolate |
| Filter by `environment:development` to exclude dev builds | Filter by `installType:normal` — environment ≠ install method |
| Skip `whoami` and guess org slug | Slug mismatch causes silent empty results |
| Treat Seer analysis as ground truth | Use as hypothesis to validate against code/traces |
