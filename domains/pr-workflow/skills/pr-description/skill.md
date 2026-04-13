---
name: pr-description
description: Write PR descriptions that convey intent and impact, not diff inventory
---

# PR Description

## When To Use

Any PR description — new feature, bug fix, refactor, dependency update.

## Workflow

1. **Fetch the repo's PR template** before writing anything. Use the template's section headers exactly. Do not invent custom sections.
2. **Write Motivation** — describe the problem in the current codebase (pre-PR names and behavior). Explains why the reviewer should care.
3. **Write Description** — describe the solution and its new names/behavior (post-PR).
4. **Write Changelog** — past-tense, user-facing sentence. Default to writing an entry; omit only for zero-observable-change internal refactors.
5. **Fill all template sections** — leave placeholder or "N/A" rather than omitting.

## Temporal Frame Rule

| Section | Frame | Names should match |
|---------|-------|--------------------|
| Motivation | Pre-PR (`main`) | Current codebase names |
| Description | Post-PR (branch) | Changed/new names |
| Changelog | Post-PR (user-facing) | Outcome language |

Writing a post-PR name in Motivation is a common mistake — it confuses reviewers who haven't seen the branch.

## Content Rules

| Rule | Anti-pattern | Good |
|------|------------|------|
| Motivation first | Starting with "This PR adds X" | Opening with the problem that prompted the change |
| Major changes only | Per-file walkthrough of every rename | One paragraph on approach + Breaking changes if applicable |
| Impact over inventory | "Removed DynamicImportType and added AnyComponent alias" | "Replaces monomorphic type with generic, eliminating casts at ~30 call sites" |
| No per-file catalogs | Section for each modified file | Non-obvious context in one sentence per file if needed |

## Changelog Rules

- Default to writing an entry. Burden of proof is on omitting.
- Omit (`null`) only for pure internal refactors: no exports modified, no behavior change, no API surface change.
- Type changes that affect downstream imports or call signatures → write an entry.

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Fetch template after writing description | Fetch first — template structure is not negotiable |
| Skip sections that seem empty | Leave placeholder or "N/A" — template-checking bots fail on missing sections |
| `null` changelog for any non-UI change | Write entry if API, type, or behavior changes — even if not user-facing |
| Reference post-PR names in Motivation | Use pre-PR (current `main`) names to describe the problem |
