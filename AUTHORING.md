# Authoring Guidelines

All content in this repo is consumed by LLM agents. Every token costs latency and context window. Write accordingly.

## Rules

1. **Every line must change agent behavior.** If removing a line doesn't change what the agent does, delete it.
2. **Tables over prose.** Structured data is faster to parse than paragraphs.
3. **Bullet points over paragraphs.** One idea per line.
4. **No filler.** No "it's important to note", "please ensure", "as mentioned above", "in order to".
5. **No redundant context.** Don't explain what a skill is inside a skill. Don't describe the repo structure inside a knowledge file.
6. **Concrete over abstract.** File paths, function names, testIDs > vague descriptions.
7. **Commands over descriptions.** "Run `yarn test`" > "You should run the test suite".
8. **Max 300 lines per file.** Split into knowledge refs if longer.

## Frontmatter

Every `.md` file starts with a frontmatter block between `---` markers.

### Skills (`skill.md`)

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | Skill identifier |
| `description` | yes | One-line summary |
| `maturity` | yes | `experimental` \| `stable` \| `deprecated` — install.sh syncs `stable` by default |
| `requires` | no | List of knowledge file names to inline |

### Knowledge files

| Field | Required | Purpose |
|---|---|---|
| `name` | yes | Knowledge identifier |
| `domain` | yes | Parent domain name |
| `description` | yes | One-line summary |

### Repo overlays (`repos/metamask-extension.md`)

| Field | Required | Purpose |
|---|---|---|
| `repo` | yes | `metamask-extension` |
| `parent` | yes | Skill this overlay belongs to |

## Skill Structure

```markdown
---
name: <name>
description: <one line>
requires: [<knowledge refs>]
---

# <Name>

## When To Use
<trigger conditions>

## Workflow
<numbered steps>

## Common Pitfalls
<table: mistake → correct approach>
```

## Repo Overlay Structure

Repo-specific details only. Do not duplicate content from `skill.md`.

```markdown
---
repo: metamask-extension
parent: <skill-name>
---

## File Paths
## Commands
## Architectural Notes
```

## Review Checklist

- [ ] Frontmatter present and valid
- [ ] No line is pure filler
- [ ] Tables used where 3+ items share structure
- [ ] File under 300 lines
- [ ] `requires:` refs point to existing knowledge files
- [ ] Overlays don't duplicate generic skill content
