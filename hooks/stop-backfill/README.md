# Stop-Backfill Hook

Opt-in Claude Code Stop hook that runs a lightweight capture-candidate check when the assistant finishes responding. If recent turns contain HIGH-signal cues and no `/remember` was invoked, it surfaces a single prompt. Otherwise it exits silently.

Phase 1.5. Not installed by default. Users opt in by copying the settings snippet below.

## What it does

At every assistant Stop, the hook:

1. Reads the last N turns from the Claude Code transcript.
2. Scans for HIGH-signal phrases (`/actually,? no/`, `/stop doing/`, `/never|always /`, double-correction patterns).
3. If at least one HIGH signal is present *and* `/remember` was not invoked in this session, emits one prompt into the next assistant turn:

   > Rule-correction pattern in recent turns: "{paraphrase}". Consider `/remember` to capture, or `/backfill` to scan more candidates.

4. Rate-limits to one prompt per session (configurable cooldown).
5. Exits 0 silently on every other Stop.

The hook never writes to the repo. Capture is still user-invoked through `/remember`.

## Installation

Append to `~/.claude/settings.json` (or project `.claude/settings.json`):

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.skills/stop-backfill.sh"
          }
        ]
      }
    ]
  }
}
```

Copy `stop-backfill.sh` into `~/.skills/`:

```bash
cp hooks/stop-backfill/stop-backfill.sh ~/.skills/
chmod +x ~/.skills/stop-backfill.sh
```

## Tuning

| Var | Default | Purpose |
|---|---|---|
| `SURFACE_WINDOW_TURNS` | `20` | How many recent turns to scan |
| `SURFACE_COOLDOWN_SEC` | `3600` | Min seconds between prompts per session |
| `SURFACE_DISABLE` | unset | Any non-empty value disables the hook |

## Why Stop, not SessionEnd

`SessionEnd` fires once, after the session is gone — too late to prompt the user interactively. `Stop` fires at every assistant turn boundary, giving the hook a chance to surface within the live session while the context is still fresh. Cooldown prevents spam.

## Why opt-in

Hooks run on every Stop and count against per-turn overhead. Users who do not capture should not pay for the scan. Users who want the safety net copy the settings snippet above.

## Uninstall

Remove the Stop entry from `settings.json` and delete `~/.skills/stop-backfill.sh`.
