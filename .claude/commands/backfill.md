---
name: backfill
description: Backfill capture candidates from the current session — corrections, decisions, patterns, and preferences that went uncaptured. Present candidates for user acceptance; route accepted ones to /remember.
---

# /backfill

Scan the current session for skill-shaped learnings that went uncaptured, present candidates, and route accepted ones to `/remember`.

## When To Use

- Before session wrap or context clear.
- After several mid-session corrections without captures.
- As a periodic sweep during long sessions.

## Do Not Use When

- Session is short (< 20 turns) — insufficient signal.
- Just did a `/backfill` within the last 10 turns.
- Session was purely exploratory with no decisions, corrections, or patterns that landed.

## Procedure

1. **Scan last 30–50 turns** of the current session.

2. **Identify candidates across all learning types:**

   **Corrections and constraints**
   | Signal | Confidence |
   |---|---|
   | User corrected a direction — explicit ("actually no", "instead", "stop") | High |
   | Same approach rejected twice in session | High |
   | Agent violated a rule already in context | High |
   | User revealed a constraint agent didn't know ("we can't X because Y") | High |

   **Decisions and rationale**
   | Signal | Confidence |
   |---|---|
   | User made a non-obvious choice and explained why | High |
   | Approach was debated then settled — settled approach has durable value | Medium |
   | Trade-off resolved in a reusable way | Medium |

   **Patterns and approaches that proved useful**
   | Signal | Confidence |
   |---|---|
   | Agent tried an approach, user accepted without modification — non-obvious approach | Medium |
   | User narrated a workflow or technique that worked | Medium |
   | Technical gotcha discovered or worked around | Medium |
   | Tooling, library, or API behavior clarified through trial | Medium |

   **Preferences revealed through the work**
   | Signal | Confidence |
   |---|---|
   | User consistently chose one pattern over alternatives across multiple turns | Medium |
   | Style or taste signal — accepted framing, phrasing, or structure without comment | Low |
   | Terminology or naming preference revealed | Low |

   Ignore: exploratory threads closed without conclusion, reasoning steps with no outcome, restated context already in existing skills.

3. **For each candidate produce:** one-line description, confidence tag, source turn reference.

4. **Present as numbered list, max 5** (top by confidence if more):

   ```
   {N} capture candidates from this session:

   1. [HIGH] {one-line description}
      — turn {N}, {source reason}

   2. [MED] {one-line description}
      — turn {N}, {source reason}

   3. [LOW] {one-line description}
      — turn {N}, {source reason}

   Accept? [all | none | 1,2 | edit N: <revision>]
   ```

5. **Route based on user response:**
   - `all` → invoke `/remember` for each candidate in order.
   - `none` → stop.
   - `1,3` → invoke `/remember` for listed candidates only.
   - `edit 2: X` → invoke `/remember` with X (replacing the proposed description for candidate 2).

6. **Report each result on its own line** as `/remember` returns.

## Rules

- Never auto-persist. `/backfill` produces candidates; the user decides.
- Maximum 5 candidates per invocation. If more than 5 present, show top 5 by confidence.
- Skip candidates that duplicate a skill captured earlier in this session.
- Personal style preferences surface as LOW only.
- If user rejects a candidate, do not resurface it later in the same session.

## Auto-invoke (Phase 1.5 — not this release)

Will trigger at:
- Session end (`Stop` hook)
- Explicit `/wrap` or `/pause` command
- Context pressure ~70%

V1 is manual-only. Engineer invokes `/backfill` explicitly.

## Related

- `/remember` — capture a single learning directly
- `/patch` — fix an existing skill
