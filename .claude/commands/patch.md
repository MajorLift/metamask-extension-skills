---
name: patch
description: Patch an existing skill in metamask-extension-skills. Updates last_patched_by/at frontmatter, appends a Changelog entry, and routes stable/draft patches through a PR for team review.
---

# /patch

Correct, extend, or refine an existing skill. Keeps a frontmatter audit trail and routes non-experimental patches through a PR.

## When To Use

- A loaded skill was applied incorrectly — the skill itself needs clearer guidance.
- `When To Use` or `Do Not Use When` is wrong or incomplete.
- An `inbox/` capture has been refined during this session and should reflect the refinement.
- Multiple captures should be consolidated into one.

## Do Not Use When

- The learning is new and unrelated — use `/remember` instead.
- The change is a maturity tier promotion — that's `/graduate`, not `/patch`.
- You haven't referenced the target skill in this session — fetch and review first.

## Procedure

1. **Staleness check** — warn if `.skills/VERSION.synced_at` is older than 3 days (same as `/remember`).

2. **Determine target skill:**
   - `/patch {slug} X` → explicit target; resolve path by searching `domains/**/skills/{slug}/skill.md`.
   - `/patch X` alone → infer from session context (most recently loaded or referenced skill). If ambiguous, ask "which skill?".

3. **Fetch current file:**
   ```
   gh api repos/MajorLift/metamask-extension-skills/contents/{path}
   ```
   Parse `content` (base64-decoded), `sha`, and current `maturity` from frontmatter.

4. **Detect source repo:**
   ```
   SOURCE_REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" || echo "unknown")
   ```

5. **Produce a minimal diff.** Show 2–5 changed lines only, not the whole file. Preserve all frontmatter and body sections not explicitly changing.

6. **Show the diff to the user.** Wait for confirm or redirect. Do not proceed silently.

7. **Apply changes to the in-memory body:**

   a. Update frontmatter — add or overwrite these fields:
      ```yaml
      last_patched_by: {user}
      last_patched_at: {now}
      ```
      Preserve immutable fields: `origin`, `captured_by`, `captured_at`, `source_repo`.

   b. Append changelog entry. If `## Changelog` section exists, insert a new entry immediately after the header (newest first). If absent, add the section at end of file:
      ```markdown
      ## Changelog
      - {now} | {user} | patch | {one-line summary} [from: {source_repo}]
      ```

8. **Write back — route depends on maturity:**

   **If `maturity: experimental`** — direct commit:
   ```
   gh api repos/MajorLift/metamask-extension-skills/contents/{path} \
     --method PUT \
     -f message="patch({path}): {summary}" \
     -f sha={sha} \
     -f "content={base64 new body}"
   ```
   Confirm: `✓ patched {path} — {short-sha} — {html_url}`

   **If `maturity: draft` or `stable`** — PR route:
   ```
   # 1. Get base SHA
   BASE_SHA=$(gh api repos/MajorLift/metamask-extension-skills/git/refs/heads/main --jq '.object.sha')

   # 2. Create branch
   BRANCH="patch/{slug}-{epoch}"
   gh api repos/MajorLift/metamask-extension-skills/git/refs \
     --method POST -f ref="refs/heads/{branch}" -f sha="{base_sha}"

   # 3. Commit to branch
   gh api repos/MajorLift/metamask-extension-skills/contents/{path} \
     --method PUT \
     -f message="patch({path}): {summary}" \
     -f branch="{branch}" \
     -f sha={sha} \
     -f "content={base64 new body}"

   # 4. Open PR
   gh api repos/MajorLift/metamask-extension-skills/pulls \
     --method POST \
     -f title="patch({slug}): {summary}" \
     -f head="{branch}" \
     -f base="main" \
     -f body="Patched by {user} from {source_repo}.\n\n{diff}"
   ```
   Confirm: `✓ PR opened — {pr_url}`

## Rules

- Show the diff before writing. Never silent-overwrite.
- `origin`, `captured_by`, `captured_at`, `source_repo` are immutable via `/patch`.
- `maturity` changes via `/patch` require explicit user confirmation — usually a `/graduate` concern.
- Path changes (moving out of `inbox/`) are a `/graduate` concern, not `/patch`.
- On SHA mismatch (409): re-fetch, re-diff, re-confirm. Someone else changed the file.
- The PR route applies to `draft` and `stable` only — `experimental` skills take the fast path.

## Related

- `/remember` — capture a new skill
- `/backfill` — surface missed captures from current session
- `/graduate` (future) — promote skill up maturity tier
