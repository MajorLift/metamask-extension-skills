#!/usr/bin/env bash
# backfill-origin.sh — one-shot migration to tag every existing skill with origin: drafted.
#
# Run ONCE, after AUTHORING.md is updated to document the origin field.
# Every skill merged before the capture pipeline shipped was authored by a human from scratch,
# so they are all origin: drafted by definition.
#
# Usage:
#   ./scripts/backfill-origin.sh            # dry run — lists changes, writes nothing
#   ./scripts/backfill-origin.sh --apply    # perform PUTs via gh api

set -euo pipefail

REPO="MajorLift/metamask-extension-skills"
APPLY=false
[[ "${1:-}" == "--apply" ]] && APPLY=true

# List all skill.md paths in domains/.
PATHS=$(gh api "repos/${REPO}/git/trees/main?recursive=1" \
  --jq '.tree[] | select(.path | test("^domains/.*/skill\\.md$")) | .path')

COUNT=0
SKIP=0

while read -r skill_path; do
  [[ -z "$skill_path" ]] && continue

  RESPONSE=$(gh api "repos/${REPO}/contents/${skill_path}")
  SHA=$(echo "$RESPONSE" | jq -r '.sha')
  BODY=$(echo "$RESPONSE" | jq -r '.content' | base64 -d)

  # Skip if origin already present.
  if echo "$BODY" | awk '/^---$/{f++; next} f==1 && /^origin:/{found=1} f>=2{exit} END{exit !found}'; then
    echo "skip (already has origin): $skill_path"
    SKIP=$(( SKIP + 1 ))
    continue
  fi

  # Insert `origin: drafted` after the `maturity:` line in the frontmatter.
  # If no maturity line, insert immediately after opening `---`.
  NEW_BODY=$(echo "$BODY" | awk '
    BEGIN { inserted=0; fm=0 }
    /^---$/ { fm++; print; next }
    fm==1 && /^maturity:/ && !inserted { print; print "origin: drafted"; inserted=1; next }
    fm==1 && /^---$/ && !inserted { print "origin: drafted"; print; inserted=1; next }
    { print }
  ')

  # Fallback: if awk produced nothing new, force insert after first `---`.
  if [[ "$NEW_BODY" == "$BODY" ]]; then
    NEW_BODY=$(echo "$BODY" | awk '
      BEGIN { inserted=0; count=0 }
      /^---$/ { count++; print; if (count==1 && !inserted) { print "origin: drafted"; inserted=1 }; next }
      { print }
    ')
  fi

  if [[ "$NEW_BODY" == "$BODY" ]]; then
    echo "WARN: no change produced for $skill_path — investigate frontmatter manually"
    continue
  fi

  COUNT=$(( COUNT + 1 ))

  if ! $APPLY; then
    echo "would update: $skill_path"
    continue
  fi

  NEW_B64=$(printf '%s' "$NEW_BODY" | base64)
  gh api "repos/${REPO}/contents/${skill_path}" \
    --method PUT \
    -f message="chore: backfill origin=drafted on pre-capture skills" \
    -f sha="$SHA" \
    -f "content=${NEW_B64}" >/dev/null

  echo "✓ updated: $skill_path"
done <<< "$PATHS"

echo
if $APPLY; then
  echo "Backfill complete: ${COUNT} updated, ${SKIP} skipped."
else
  echo "Dry run: ${COUNT} would be updated, ${SKIP} already tagged. Re-run with --apply to commit."
fi
