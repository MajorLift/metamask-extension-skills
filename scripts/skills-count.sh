#!/usr/bin/env bash
# skills-count.sh — dashboard of skill counts by origin, maturity, domain.
# Walks domains/**/skill.md, parses frontmatter, aggregates.
#
# Usage: ./scripts/skills-count.sh [--json]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON=false
[[ "${1:-}" == "--json" ]] && JSON=true

declare -a SKILLS PATCHES
declare -A BY_ORIGIN BY_MATURITY BY_DOMAIN AUTHORS PATCH_AUTHORS LATEST

while IFS= read -r -d '' file; do
  origin=$(awk '/^origin: */{print $2; exit}' "$file" 2>/dev/null || echo "drafted")
  [[ -z "$origin" ]] && origin="drafted"
  maturity=$(awk '/^maturity: */{print $2; exit}' "$file" 2>/dev/null || echo "experimental")
  captured_by=$(awk '/^captured_by: */{print $2; exit}' "$file" 2>/dev/null || echo "")
  captured_at=$(awk '/^captured_at: */{print $2; exit}' "$file" 2>/dev/null || echo "")
  last_patched_by=$(awk '/^last_patched_by: */{print $2; exit}' "$file" 2>/dev/null || echo "")
  last_patched_at=$(awk '/^last_patched_at: */{print $2; exit}' "$file" 2>/dev/null || echo "")
  source_repo=$(awk '/^source_repo: */{print $2; exit}' "$file" 2>/dev/null || echo "")
  name=$(awk '/^name: */{print $2; exit}' "$file" 2>/dev/null || echo "")

  domain=$(echo "$file" | sed -E 's|.*/domains/([^/]+)/.*|\1|')

  BY_ORIGIN[$origin]=$(( ${BY_ORIGIN[$origin]:-0} + 1 ))
  BY_MATURITY[$maturity]=$(( ${BY_MATURITY[$maturity]:-0} + 1 ))
  BY_DOMAIN[$domain]=$(( ${BY_DOMAIN[$domain]:-0} + 1 ))

  if [[ -n "$captured_by" ]]; then
    AUTHORS[$captured_by]=$(( ${AUTHORS[$captured_by]:-0} + 1 ))
  fi

  if [[ -n "$captured_at" ]]; then
    SKILLS+=("${captured_at}|${name}|${domain}|${captured_by}|${source_repo}")
  fi

  if [[ -n "$last_patched_at" && -n "$last_patched_by" ]]; then
    PATCH_AUTHORS[$last_patched_by]=$(( ${PATCH_AUTHORS[$last_patched_by]:-0} + 1 ))
    PATCHES+=("${last_patched_at}|${name}|${domain}|${last_patched_by}")
  fi

done < <(find "$REPO_ROOT/domains" -name 'skill.md' -print0 2>/dev/null)

TOTAL=$(find "$REPO_ROOT/domains" -name 'skill.md' | wc -l | tr -d ' ')

if $JSON; then
  printf '{"total":%d,"by_origin":{' "$TOTAL"
  first=true
  for k in "${!BY_ORIGIN[@]}"; do
    $first || printf ','
    printf '"%s":%d' "$k" "${BY_ORIGIN[$k]}"
    first=false
  done
  printf '},"by_maturity":{'
  first=true
  for k in "${!BY_MATURITY[@]}"; do
    $first || printf ','
    printf '"%s":%d' "$k" "${BY_MATURITY[$k]}"
    first=false
  done
  printf '}}\n'
  exit 0
fi

echo "Skills: ${TOTAL} total"
echo
echo "  By origin:"
for k in "${!BY_ORIGIN[@]}"; do
  printf "    %-12s %d\n" "$k:" "${BY_ORIGIN[$k]}"
done
echo
echo "  By maturity:"
for k in "${!BY_MATURITY[@]}"; do
  printf "    %-15s %d\n" "$k:" "${BY_MATURITY[$k]}"
done
echo
echo "  By domain:"
for k in $(printf '%s\n' "${!BY_DOMAIN[@]}" | sort); do
  printf "    %-20s %d\n" "$k:" "${BY_DOMAIN[$k]}"
done

if (( ${#AUTHORS[@]} > 0 )); then
  echo
  echo "  Captures by author:"
  for k in "${!AUTHORS[@]}"; do
    printf "    %-20s %d\n" "$k:" "${AUTHORS[$k]}"
  done
fi

if (( ${#PATCH_AUTHORS[@]} > 0 )); then
  echo
  echo "  Patches by author:"
  for k in "${!PATCH_AUTHORS[@]}"; do
    printf "    %-20s %d\n" "$k:" "${PATCH_AUTHORS[$k]}"
  done
fi

if (( ${#SKILLS[@]} > 0 )); then
  echo
  echo "  Latest captures:"
  printf '%s\n' "${SKILLS[@]}" | sort -r | head -5 | while IFS='|' read -r ts name dom by src; do
    src_label=${src:+ "($src)"}
    printf "    %s  [%s] %s — %s%s\n" "$ts" "$dom" "$name" "$by" "$src_label"
  done
fi

if (( ${#PATCHES[@]} > 0 )); then
  echo
  echo "  Latest patches:"
  printf '%s\n' "${PATCHES[@]}" | sort -r | head -5 | while IFS='|' read -r ts name dom by; do
    printf "    %s  [%s] %s — %s\n" "$ts" "$dom" "$name" "$by"
  done
fi
