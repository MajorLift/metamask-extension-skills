---
name: remember
description: Capture a skill-shaped learning from the current session into metamask-extension-skills as an experimental skill in domains/inbox/. Records source_repo, author, and timestamp for team audit trail.
---

# /remember

Capture a learning as an experimental skill. Lands in `domains/inbox/skills/{slug}/skill.md` for shepherd curation.

## When To Use

- You hit a correction, pattern, or pitfall the agent should know next time.
- You noticed the same issue twice in one session.
- A teammate's approach worked better and should be encoded.

## Do Not Use When

- Learning is personal preference, not team-valid.
- Better enforced as a lint rule, test, or type.
- Content is ephemeral (one-off bug fix, specific file name).
- Content contains secrets, PII, internal URLs, or credentials.

## Procedure

1. **Staleness check.** Read `.skills/VERSION` in the current working directory. If it exists and `synced_at` is older than 3 days, emit a one-line warning:
   ```
   ⚠  Skills last synced {N} days ago. Run `yarn skills:sync` before capturing.
   ```
   Continue regardless — warning only, not a block.

2. Read user input after `/remember` — this is the raw capture.

3. **Generate slug:**
   - Lowercase.
   - Replace non-alphanumeric runs with single hyphens.
   - Trim leading/trailing hyphens.
   - Truncate to 40 chars.

4. **Resolve metadata:**
   - User: `gh api user --jq .login`
   - Timestamp: `date -u +%Y-%m-%dT%H:%M:%SZ`
   - Source repo: `basename "$(git rev-parse --show-toplevel 2>/dev/null)"` — the consuming repo where the learning occurred. Fall back to `"unknown"` if not in a git repo.

5. **Compose file body:**
   ```markdown
   ---
   maturity: experimental
   name: {slug}
   description: {first 80 chars of capture, one line, no newlines}
   origin: captured
   captured_by: {user}
   captured_at: {timestamp}
   source_repo: {source_repo}
   ---

   # {Title cased from first sentence}

   ## Capture
   {raw user input, verbatim}

   ## When To Use
   TODO — shepherd to fill in during curation.

   ## Do Not Use When
   TODO — shepherd to fill in during curation.

   ## Notes
   Experimental capture. Awaiting curation.

   ## Changelog
   - {timestamp} | {user} | capture | {description}
   ```

6. **Write via gh api:**
   ```
   gh api repos/MajorLift/metamask-extension-skills/contents/domains/inbox/skills/{slug}/skill.md \
     --method PUT \
     -f message="capture(inbox/{slug}): {description}" \
     -f "content=$(printf '%s' '{body}' | base64)"
   ```

7. **On 422 (slug collision):** append `-2`, `-3`, etc. to slug and retry. Never overwrite existing files.

8. **On 401/403:** direct user to `gh auth login`. Stop.

9. **Confirm on success:** one line, exactly this format:
   ```
   ✓ domains/inbox/skills/{slug}/skill.md — {short-sha} — {html_url}
   ```

## Rules

- Always `inbox` domain. Do not classify at capture time — that's shepherd work.
- No admission filter at capture. Filter at promotion.
- Never ask "are you sure?" or "which domain?". One invocation, one file, one line out.
- Never silent-overwrite on slug collision.
- `source_repo` is detected automatically — do not prompt user for it.

## Related

- `/patch` — fix an existing skill
- `/backfill` — surface missed captures from current session
- `CONTRIBUTING.md` in metamask-extension-skills — full intake and promotion flow
