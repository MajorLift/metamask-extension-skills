#!/usr/bin/env bash
# remember.sh — capture a skill-shaped learning as an experimental skill
# in MajorLift/metamask-extension-skills under domains/inbox/.
#
# Usage: remember.sh [flags] "capture text"
#
# Flags:
#   --captured-by <user>  Override author (default: gh api user --jq .login)
#   --source-repo <name>  Override source repo (default: basename of git toplevel)
#   --audit-url <url>     Optional audit backlink (e.g. PR comment URL)
#   --mode <commit|local> commit = PUT to skills repo (default)
#                         local  = write skill.md under --out-dir, no network write
#   --out-dir <dir>       Root dir for --mode local (default: current dir)
#
# Requires: gh CLI authenticated with write access to the skills repo (commit mode only).

set -euo pipefail

REPO="MajorLift/metamask-extension-skills"
CAPTURED_BY=""
SOURCE_REPO_OVERRIDE=""
AUDIT_URL=""
MODE="commit"
OUT_DIR=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --captured-by) CAPTURED_BY="$2"; shift 2 ;;
    --source-repo) SOURCE_REPO_OVERRIDE="$2"; shift 2 ;;
    --audit-url)   AUDIT_URL="$2"; shift 2 ;;
    --mode)        MODE="$2"; shift 2 ;;
    --out-dir)     OUT_DIR="$2"; shift 2 ;;
    --) shift; POSITIONAL+=("$@"); break ;;
    -*) echo "Unknown flag: $1" >&2; exit 1 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

set -- "${POSITIONAL[@]}"
[[ $# -lt 1 ]] && { echo "Usage: $0 [flags] \"capture text\"" >&2; exit 1; }

case "$MODE" in
  commit|local) ;;
  *) echo "Error: --mode must be 'commit' or 'local' (got '$MODE')" >&2; exit 1 ;;
esac

CAPTURE="$*"

# Staleness warning (non-blocking, commit mode only).
if [[ "$MODE" == "commit" && -f .skills/VERSION ]]; then
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
if [[ -n "$SOURCE_REPO_OVERRIDE" ]]; then
  SOURCE_REPO="$SOURCE_REPO_OVERRIDE"
else
  SOURCE_REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")
  [[ -z "$SOURCE_REPO" ]] && SOURCE_REPO="unknown"
fi

# Slugify: lowercase, non-alphanumeric → hyphen, collapse, trim, truncate to 40.
SLUG=$(echo "$CAPTURE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' \
  | cut -c1-40 \
  | sed -E 's/-+$//')

[[ -z "$SLUG" ]] && { echo "Error: capture produced empty slug" >&2; exit 1; }

# One-line description, no embedded newlines.
DESCRIPTION=$(echo "$CAPTURE" | tr '\n' ' ' | cut -c1-80 | sed 's/[[:space:]]*$//')

# Author + timestamp. Falls back to the authenticated gh user if no override given.
if [[ -z "$CAPTURED_BY" ]]; then
  CAPTURED_BY=$(gh api user --jq .login)
fi
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Title: first sentence, trimmed.
TITLE=$(echo "$CAPTURE" | head -c 100 | sed -E 's/\.$//' | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^[[:space:]]+|[[:space:]]+$//g')

# Build frontmatter. audit_url only emitted when --audit-url is set.
FRONTMATTER="maturity: experimental
name: ${SLUG}
description: ${DESCRIPTION}
origin: captured
captured_by: ${CAPTURED_BY}
captured_at: ${NOW}
source_repo: ${SOURCE_REPO}"
[[ -n "$AUDIT_URL" ]] && FRONTMATTER="${FRONTMATTER}
audit_url: ${AUDIT_URL}"

BODY=$(cat <<EOF
---
${FRONTMATTER}
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
- ${NOW} | ${CAPTURED_BY} | capture | ${DESCRIPTION}
EOF
)

PATH_IN_REPO="domains/inbox/skills/${SLUG}/skill.md"
BASE_SLUG="$SLUG"

# Handle slug collision by checking the remote (authoritative) contents API.
N=2
while gh api "repos/${REPO}/contents/${PATH_IN_REPO}" >/dev/null 2>&1; do
  NEW_SLUG=$(echo "${BASE_SLUG}-${N}" | cut -c1-40 | sed -E 's/-+$//')
  PATH_IN_REPO="domains/inbox/skills/${NEW_SLUG}/skill.md"
  BODY=$(echo "$BODY" | sed -E "s/^name: .*$/name: ${NEW_SLUG}/")
  SLUG="$NEW_SLUG"
  N=$(( N + 1 ))
  (( N > 20 )) && { echo "Error: too many slug collisions" >&2; exit 1; }
done

# Local mode: write to filesystem, emit shell-parseable metadata on stdout.
if [[ "$MODE" == "local" ]]; then
  [[ -z "$OUT_DIR" ]] && OUT_DIR="$(pwd)"
  FULL_PATH="${OUT_DIR}/${PATH_IN_REPO}"
  mkdir -p "$(dirname "$FULL_PATH")"
  printf '%s' "$BODY" > "$FULL_PATH"
  # Machine-readable output: caller evals or greps these.
  echo "SKILL_PATH=${PATH_IN_REPO}"
  echo "SKILL_SLUG=${SLUG}"
  echo "SKILL_DESCRIPTION=${DESCRIPTION}"
  echo "SKILL_FULL_PATH=${FULL_PATH}"
  exit 0
fi

# Commit mode (default): PUT to contents API.
CONTENT_B64=$(printf '%s' "$BODY" | base64)

RESPONSE=$(gh api "repos/${REPO}/contents/${PATH_IN_REPO}" \
  --method PUT \
  -f message="capture(inbox/${SLUG}): ${DESCRIPTION}" \
  -f "content=${CONTENT_B64}")

SHORT=$(echo "$RESPONSE" | jq -r '.commit.sha[0:7]')
URL=$(echo "$RESPONSE" | jq -r '.content.html_url')

echo "✓ ${PATH_IN_REPO} — ${SHORT} — ${URL}"
