# metamask-extension-skills

Agent skills, rules, and platform knowledge for MetaMask extension development. Readable by humans, optimized for agents — every file is structured so LLM agents (Cursor, Claude Code, OpenCode) can find and apply the right knowledge without guessing.

> **Migration note:** Maintained under `MajorLift/metamask-extension-skills` pending transfer to `MetaMask/` org.

## Structure

```
domains/<domain>/
  knowledge/*.md            # Reference material consumed by skills
  skills/<name>/
    skill.md                # Generic workflow (shared baseline)
    repos/
      metamask-extension.md # Extension-specific paths, commands, validation
tools/
  install.sh                # Sync skills into consuming repo
```

## Domains

| Domain | Content |
|---|---|
| `coding` | TypeScript safety, refactoring patterns, code quality |
| `platform` | Extension architecture — background/UI boundary, MV3, context isolation, build types |
| `performance` | Cascade debugging, state management optimization, benchmarking |
| `testing` | E2E fixtures, performance testing |
| `pr-workflow` | PR descriptions, changelogs, commit discipline, ticket workflow |

## Install

```bash
tools/install.sh --repo metamask-extension --target ~/dev/metamask/metamask-extension

# Preview without writing
tools/install.sh --repo metamask-extension --target ~/dev/metamask/metamask-extension --dry-run
```

Writes to three gitignored directories in the target repo:

| Operator | Target Path |
|---|---|
| Claude Code | `.claude/skills/<name>/SKILL.md` |
| Cursor | `.cursor/rules/<name>/RULE.md` |
| OpenCode | `.agents/skills/<name>/SKILL.md` |

## Authoring

See [AUTHORING.md](AUTHORING.md). Key rule: every line must change agent behavior or be cut.
