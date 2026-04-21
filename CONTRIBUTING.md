# Contributing

Skills are added through one of three intake sinks. All sinks produce captures in `domains/inbox/` — the bot never direct-commits to merged skills outside `inbox/`.

## Intake sinks

| Sink | Trigger | Status |
|---|---|---|
| **Chat slash** | `/remember X` during a Claude Code / Cursor / CLI session | Available |
| **Shell** | `remember "X"` in any terminal | Available |
| **Backfill** | `/backfill` to surface missed captures from current session | Available (manual) |
| **PR comment** | `@metamaskbot /remember X` on a GitHub PR | Phase 3 — deferred |

All captures land as `maturity: experimental`, `origin: captured`, under `domains/inbox/skills/{slug}/skill.md`.

## The three commands

| Command | Action |
|---|---|
| `/remember X` | Create a new experimental skill in `domains/inbox/` |
| `/patch {slug} X` | Correct or extend an existing skill |
| `/backfill` | Surface missed capture candidates from current session |

Each command exists as a Claude Code slash command (`.claude/commands/`), a Cursor rule (`.cursor/rules/`), and (for `remember` and `patch`) a shell script (`.skills/`).

## Maturity tiers

| Tier | Meaning | Assigned by |
|---|---|---|
| `experimental` | Newly captured; admission filter not yet confirmed | Bot or author at capture |
| `draft` | Human-reviewed; admission filter confirmed; not yet production-validated | Reviewer |
| `stable` | Exercised in real agent sessions; synced by `install.sh` by default | Curator |

Skills start `experimental`. TTL: 60 days without promotion → auto-archived to `docs/archive/`.

## Origin field

Every skill carries an `origin` frontmatter field:

| Value | Meaning |
|---|---|
| `captured` | Created via `/remember` or a capture sink — came from a real session |
| `drafted` | Written by a human from scratch, not from a specific session |

Used for A/B metrics comparing capture vs authoring paths. Do not change `origin` on existing skills.

## Shepherd curation

Captures in `domains/inbox/` move out into real domains during shepherd curation:

1. Shepherd reads new captures in `inbox/`.
2. For each: classify domain, tighten prose, fill in `When To Use` / `Do Not Use When` TODOs.
3. Move file to `domains/{domain}/skills/{slug}/` via `/patch` or manual PR.
4. Optionally flip `maturity` to `draft` if the admission filter is confirmed.

Inbox is intentionally lossy. Shepherd deletes captures that don't survive the admission filter rather than promoting them.

## Manual contribution (no bot required)

Open a PR directly:

1. Create `domains/<domain>/skills/<name>/skill.md` following [AUTHORING.md](AUTHORING.md).
2. Set `maturity: experimental`, `origin: drafted` in frontmatter.
3. Write `Do Not Use When` **before** `When To Use`. If that section ends up longer than `When To Use`, stop — the candidate is not a skill.
4. Run the [Review Checklist](AUTHORING.md#review-checklist) before requesting review.

## Promotion path

`experimental → draft`: reviewer confirms the admission filter, tightens prose, flips frontmatter.

`draft → stable`: curator confirms the skill has been exercised in real sessions. `install.sh` begins syncing on merge.

## Promotion to upstream (future)

Stable skills may eventually promote to an upstream org-wide repo via an explicit cross-repo PR. That PR is the privacy scrub and taste gate in one — skills with MetaMask-internal paths or config go through a generalization pass before promotion.

Deferred until upstream intake is designed.

## What does not belong here

- **Postmortems** — diagnostic narrative goes in PR descriptions or commit messages; git history is the archive.
- **Retro documents** — retros surface skill candidates; they do not produce separate artifacts.
- **Known-broken workarounds** — if a skill compensates for unfixed code, file a ticket instead.
- **General best practices** — if an agent can derive it from code + public docs in under an hour, it fails the admission filter.

## Patch review gate

`/patch` on `experimental` skills commits directly. `/patch` on `draft` or `stable` skills opens a PR instead — teammates can review before merge. This keeps the fast iteration path for captures while protecting promoted skills from silent modification.

## Metrics

`scripts/skills-count.sh` outputs a dashboard of total skills, counts by origin/maturity/domain, captures by author, and latest captures. Used for visibility into intake volume and origin A/B.

## Staying in sync

Run `yarn skills:sync` (or `tools/sync.sh --target .`) in the consuming repo to pull the latest skills. Commands like `/remember` emit a warning if the last sync was more than 3 days ago.
