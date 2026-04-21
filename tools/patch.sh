#!/usr/bin/env bash
# patch.sh — patch an existing skill in MajorLift/metamask-extension-skills.
#
# Usage: patch.sh <slug|path> "patch text"
#
# Shell fallback — appends a Changelog entry and updates last_patched_by/at in frontmatter.
# Routes stable/draft skills through a PR; commits experimental directly.

set -euo pipefail

[[ $# -lt 2 ]] && { echo "Usage: $0 <slug|path> \"patch text\"" >&2; exit 1; }

TARGET="$1"; shift
NOTE="$*"
REPO="MajorLift/metamask-extension-skills"

# GH_USER avoids clobbering the shell $USER env var.
GH_USER=$(gh api user --jq .login)
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EPOCH=$(date -u +%s)

# Detect source repo.
SOURCE_REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")
[[ -z "$SOURCE_REPO" ]] && SOURCE_REPO="unknown"

# Resolve path.
if [[ "$TARGET" == */* ]]; then
  SKILL_PATH="$TARGET"
else
  SEARCH=$(gh api "search/code?q=filename:skill.md+repo:${REPO}+path:domains+${TARGET}" 2>/dev/null || echo "{}")
  MATCH_COUNT=$(echo "$SEARCH" | jq '.items | length' 2>/dev/null || echo 0)
  SKILL_PATH=$(echo "$SEARCH" | jq -r '.items[]?.path' | head -1 || true)
  [[ -z "$SKILL_PATH" ]] && { echo "Error: no skill matching slug '$TARGET'" >&2; exit 1; }
  if (( MATCH_COUNT > 1 )); then
    echo "⚠  Multiple matches for '${TARGET}'; using ${SKILL_PATH}. Pass a full path to disambiguate." >&2
  fi
fi

SLUG=$(basename "$(dirname "$SKILL_PATH")")
DOMAIN=$(echo "$SKILL_PATH" | sed -E 's|domains/([^/]+)/.*|\1|')

# Fetch current content + sha.
RESPONSE=$(gh api "repos/${REPO}/contents/${SKILL_PATH}")
SHA=$(echo "$RESPONSE" | jq -r '.sha')
CURRENT=$(echo "$RESPONSE" | jq -r '.content' | base64 -d)

# Extract current maturity.
MATURITY=$(echo "$CURRENT" | awk '/^---$/{f++; next} f==1 && /^maturity:/{print $2; exit}')
[[ -z "$MATURITY" ]] && MATURITY="experimental"

NOTE_SHORT=$(echo "$NOTE" | cut -c1-80 | tr '\n' ' ' | sed 's/[[:space:]]*$//')
CHANGELOG_ENTRY="- ${NOW} | ${GH_USER} | patch | ${NOTE_SHORT} [from: ${SOURCE_REPO}]"

# --- Update frontmatter: add/replace last_patched_by and last_patched_at ---
PATCHED=$(echo "$CURRENT" | awk \
  -v user="$GH_USER" \
  -v now="$NOW" \
  'BEGIN { fm=0; had_by=0; had_at=0 }
   /^---$/ && fm==0 { fm=1; print; next }
   fm==1 && /^last_patched_by:/ { print "last_patched_by: " user; had_by=1; next }
   fm==1 && /^last_patched_at:/ { print "last_patched_at: " now; had_at=1; next }
   fm==1 && /^---$/ {
     if (!had_by) print "last_patched_by: " user
     if (!had_at) print "last_patched_at: " now
     fm=2; print; next
   }
   { print }')

# --- Append changelog entry (newest first under ## Changelog) ---
if echo "$PATCHED" | grep -q "^## Changelog"; then
  NEW_BODY=$(echo "$PATCHED" | awk \
    -v entry="$CHANGELOG_ENTRY" \
    '/^## Changelog$/ { print; print entry; next } { print }')
else
  NEW_BODY=$(printf '%s\n\n## Changelog\n%s\n' "$PATCHED" "$CHANGELOG_ENTRY")
fi

NEW_B64=$(printf '%s' "$NEW_BODY" | base64)
COMMIT_MSG="patch(${DOMAIN}/${SLUG}): ${NOTE_SHORT}"

# --- Route: PR for draft/stable, direct commit for experimental ---
if [[ "$MATURITY" == "stable" || "$MATURITY" == "draft" ]]; then
  BRANCH="patch/${SLUG}-${EPOCH}"

  # Get base SHA.
  BASE_SHA=$(gh api "repos/${REPO}/git/refs/heads/main" --jq '.object.sha')

  # Create branch.
  gh api "repos/${REPO}/git/refs" \
    --method POST \
    -f "ref=refs/heads/${BRANCH}" \
    -f "sha=${BASE_SHA}" >/dev/null

  # Commit to branch.
  gh api "repos/${REPO}/contents/${SKILL_PATH}" \
    --method PUT \
    -f "message=${COMMIT_MSG}" \
    -f "branch=${BRANCH}" \
    -f "sha=${SHA}" \
    -f "content=${NEW_B64}" >/dev/null

  # Open PR with real newlines in body.
  PR_BODY=$(printf 'Patched by **%s** from `%s`.\n\n```\n%s\n```' \
    "$GH_USER" "$SOURCE_REPO" "$NOTE")
  PR_RESPONSE=$(gh api "repos/${REPO}/pulls" \
    --method POST \
    -f "title=patch(${SLUG}): ${NOTE_SHORT}" \
    -f "head=${BRANCH}" \
    -f "base=main" \
    -f "body=${PR_BODY}")

  PR_URL=$(echo "$PR_RESPONSE" | jq -r '.html_url')
  echo "✓ PR opened — ${PR_URL}"

else
  # experimental: direct commit.
  PUT_RESPONSE=$(gh api "repos/${REPO}/contents/${SKILL_PATH}" \
    --method PUT \
    -f "message=${COMMIT_MSG}" \
    -f "sha=${SHA}" \
    -f "content=${NEW_B64}")

  SHORT=$(echo "$PUT_RESPONSE" | jq -r '.commit.sha[0:7]')
  URL=$(echo "$PUT_RESPONSE" | jq -r '.content.html_url')
  echo "✓ patched ${SKILL_PATH} — ${SHORT} — ${URL}"
fi
