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

| Domain | Skills | Knowledge |
|---|---|---|
| `ai-collaboration` | `diagnose-before-acting`, `evaluate-before-agreeing`, `specifications-as-guardrails`, `understand-before-acting` | `ai-failure-modes` |
| `coding` | `search-before-write` | `context-breaking-changes` |
| `performance` | `perf-cascade-debugging` | `cascade-amplification`, `selector-anti-patterns`, `web-vitals-instrumentation` |
| `platform` | `extension-errors-debugging`, `extension-lifecycle-assumptions` | `extension-architecture`, `metrametrics-identity`, `mv3-service-worker`, `segment-governance` |
| `pr-workflow` | `pr-description`, `commit-discipline` | — |
| `testing` | — | `benchmark-methodology` |

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
