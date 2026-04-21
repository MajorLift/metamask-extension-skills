#!/usr/bin/env bash
# remember.sh — capture a skill-shaped learning as an experimental skill
# in MajorLift/metamask-extension-skills under domains/inbox/.
#
# Usage: remember.sh "capture text"
#
# Requires: gh CLI authenticated with write access to the skills repo.

set -euo pipefail

[[ $# -lt 1 ]] && { echo "Usage: $0 \"capture text\"" >&2; exit 1; }

CAPTURE="$*"
REPO="MajorLift/metamask-extension-skills"

# Staleness warning (non-blocking).
if [[ -f .skills/VERSION ]]; then
  SYNCED_AT=$(grep '^synced_at=' .skills/VERSION | cut -d= -f2 || echo "")
  if [[ -n "$SYNCED_AT" ]]; then
    if date -j >/dev/null 2>&1; then
      SYNC_EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$SYNCED_AT" +%s 2>/dev/null || echo 0)
    else
      SYNC_EPOCH=$(date -u -d "$SYNCED_AT" +%s 2>/dev/null || echo 0)
    fi
    NOW_EPOCH=$(date -u +%s)
    AGE_DAYS=$(( (NOW_EPOCH - SYNC_EPOCH) / 86400 ))
    if (( AGE_DAYS > 3 )); then
      echo "⚠  Skills last synced ${AGE_DAYS}d ago. Run \`yarn skills:sync\` before capturing." >&2
    fi
  fi
fi

# Detect source repo (where the learning occurred).
SOURCE_REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")
[[ -z "$SOURCE_REPO" ]] && SOURCE_REPO="unknown"

# Slugify: lowercase, non-alphanumeric → hyphen, collapse, trim, truncate to 40.
SLUG=$(echo "$CAPTURE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' \
  | cut -c1-40 \
  | sed -E 's/-+$//')

[[ -z "$SLUG" ]] && { echo "Error: capture produced empty slug" >&2; exit 1; }

# One-line description, no embedded newlines.
DESCRIPTION=$(echo "$CAPTURE" | tr '\n' ' ' | cut -c1-80 | sed 's/[[:space:]]*$//')

# Author + timestamp. GH_USER avoids clobbering the shell $USER env var.
GH_USER=$(gh api user --jq .login)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Title: first sentence, trimmed.
TITLE=$(echo "$CAPTURE" | head -c 100 | sed -E 's/\.$//' | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+|[[:space:]]+$//g')

BODY=$(cat <<EOF
---
maturity: experimental
name: ${SLUG}
description: ${DESCRIPTION}
origin: captured
captured_by: ${GH_USER}
captured_at: ${NOW}
source_repo: ${SOURCE_REPO}
---

# ${TITLE}

## Capture
${CAPTURE}

## When To Use
TODO — shepherd to fill in during curation.

## Do Not Use When
TODO — shepherd to fill in during curation.

## Notes
Experimental capture. Awaiting curation.

## Changelog
- ${NOW} | ${GH_USER} | capture | ${DESCRIPTION}
EOF
)

PATH_IN_REPO="domains/inbox/skills/${SLUG}/skill.md"
BASE_SLUG="$SLUG"

# Handle slug collision: always increment from BASE_SLUG, never chain suffixes.
N=2
while gh api "repos/${REPO}/contents/${PATH_IN_REPO}" >/dev/null 2>&1; do
  NEW_SLUG=$(echo "${BASE_SLUG}-${N}" | cut -c1-40 | sed -E 's/-+$//')
  PATH_IN_REPO="domains/inbox/skills/${NEW_SLUG}/skill.md"
  BODY=$(echo "$BODY" | sed -E "s/^name: .*$/name: ${NEW_SLUG}/")
  SLUG="$NEW_SLUG"
  N=$(( N + 1 ))
  (( N > 20 )) && { echo "Error: too many slug collisions" >&2; exit 1; }
done

CONTENT_B64=$(printf '%s' "$BODY" | base64)

RESPONSE=$(gh api "repos/${REPO}/contents/${PATH_IN_REPO}" \
  --method PUT \
  -f message="capture(inbox/${SLUG}): ${DESCRIPTION}" \
  -f "content=${CONTENT_B64}")

SHORT=$(echo "$RESPONSE" | jq -r '.commit.sha[0:7]')
URL=$(echo "$RESPONSE" | jq -r '.content.html_url')

echo "✓ ${PATH_IN_REPO} — ${SHORT} — ${URL}"
