# ADR 001: Skills Repo Architecture

| | |
|---|---|
| **Status** | Accepted |
| **Scope** | `MajorLift/metamask-extension-skills` |
| **Migration target** | `MetaMask/metamask-extension-skills` |

## Context

Agent skills and platform knowledge for MetaMask extension development were distributed across individual developer configs with no shared layer. Agents carried stale copies, and cross-team knowledge (extension architecture, MV3 patterns, performance debugging) required repeated explanation.

## Decision

Single repo, synced into the consuming repo at install time. Content is gitignored in the target — never checked in, always fresh.

## Structure

```
domains/<domain>/
  knowledge/*.md     # Reference material (consumed via requires:)
  skills/<name>/
    skill.md         # Generic workflow, shared baseline
    repos/
      metamask-extension.md  # Extension-specific paths, commands, validation
tools/
  install.sh         # Merges and writes to three operator formats
```

### Domain split

| Domain | Audience | Content type |
|---|---|---|
| `coding` | Extension engineers | TypeScript safety, refactoring patterns |
| `platform` | All teams | Extension architecture, MV3, background/UI boundary |
| `performance` | Extension engineers | Cascade debugging, benchmarking |
| `testing` | All teams | E2E fixtures, performance testing |
| `pr-workflow` | All teams | PRs, changelogs, commits, tickets |

`platform` is intentionally separate from `coding` — it targets mobile, feature, and delivery teams who need architectural context, not coding guidelines.

## Operator output

| Operator | Output path |
|---|---|
| Claude Code | `.claude/skills/<name>/SKILL.md` |
| Cursor | `.cursor/rules/<name>/RULE.md` |
| OpenCode | `.agents/skills/<name>/SKILL.md` + `agents/openai.yaml` |

All output is gitignored in the consuming repo. Install overwrites on each run.

## Migration

Repo lives under `MajorLift/` during authoring. Transfer to `MetaMask/` org once content is reviewed and install hook is integrated into `yarn setup`.
