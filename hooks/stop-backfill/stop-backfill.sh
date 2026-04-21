#!/usr/bin/env bash
# stop-backfill.sh — Claude Code Stop hook. Surfaces one capture suggestion per
# session when HIGH-signal rule-correction patterns appear in recent turns.
#
# Reads the transcript path from the Stop hook JSON payload on stdin:
#   {"transcript_path": "/path/to/transcript.jsonl", "session_id": "...", ...}
#
# Emits a suggestion via stdout JSON (Claude Code reads structured hook output)
# when a candidate is found. Otherwise exits 0 silently.

set -euo pipefail

[[ -n "${SURFACE_DISABLE:-}" ]] && exit 0

WINDOW=${SURFACE_WINDOW_TURNS:-20}
COOLDOWN=${SURFACE_COOLDOWN_SEC:-3600}
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/stop-backfill"
mkdir -p "$STATE_DIR"

# Parse payload.
PAYLOAD=$(cat)
TRANSCRIPT=$(echo "$PAYLOAD" | jq -r '.transcript_path // empty')
SESSION=$(echo "$PAYLOAD" | jq -r '.session_id // empty')
[[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]] && exit 0
[[ -z "$SESSION" ]] && SESSION="unknown"

STATE_FILE="$STATE_DIR/${SESSION}.state"
NOW=$(date -u +%s)

# Respect cooldown.
if [[ -f "$STATE_FILE" ]]; then
  LAST=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
  (( NOW - LAST < COOLDOWN )) && exit 0
fi

# Pull last N user/assistant messages.
RECENT=$(tail -n "$WINDOW" "$TRANSCRIPT" 2>/dev/null || true)
[[ -z "$RECENT" ]] && exit 0

# If /remember was already invoked this session, no need to nudge.
if echo "$RECENT" | grep -qE '(/remember|/patch|/backfill)\b'; then
  exit 0
fi

# HIGH-signal patterns (user messages only — correction signals).
SIGNALS=$(echo "$RECENT" \
  | jq -r 'select(.type=="user") | .message.content[]? | select(.type=="text") | .text' 2>/dev/null \
  | grep -iE 'actually,?\s*no|stop doing|next time|never (do|use|run)|always (do|use|run)' \
  | head -3 || true)

[[ -z "$SIGNALS" ]] && exit 0

# Paraphrase: first matching line, trimmed.
FIRST=$(echo "$SIGNALS" | head -1 | tr -s '[:space:]' ' ' | cut -c1-120 | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')

# Record cooldown stamp.
echo "$NOW" > "$STATE_FILE"

# Emit structured output for Claude Code to surface in next turn.
cat <<EOF
{
  "systemMessage": "Rule-correction pattern in recent turns: \"${FIRST}\". Consider /remember to capture, or /backfill to scan more candidates."
}
EOF
