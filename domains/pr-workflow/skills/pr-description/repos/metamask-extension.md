---
repo: metamask-extension
parent: pr-description
---

## PR Template

Fetch before writing: `.github/pull-request-template.md`

Required sections (do not omit):
- **Description** — what the change does and why
- **Changelog** — past-tense user-facing sentence, or `null` with justification
- **Related issues** — link to Linear/GitHub issue
- **Manual testing steps** — steps a reviewer can follow
- **Screenshots/Recordings** — for UI changes
- **Pre-merge author checklist** — include all checkboxes
- **Pre-merge reviewer checklist** — include all checkboxes

## Changelog Format

```
### Changed
- Fixed render cascade in selector layer, reducing re-render count by 80% on home page
```

Categories: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

Use `null` only for: pure internal refactors with no observable behavior change, no modified exports, no API surface change.

## Breaking Changes

Any removed export, changed function signature, or incompatible state shape requires explicit callout in the Description section. Reviewers cannot reliably catch breaking changes from the diff alone.
