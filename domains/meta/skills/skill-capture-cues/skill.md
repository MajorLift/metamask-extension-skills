---
maturity: draft
name: skill-capture-cues
description: Notice skill-shaped moments during a session and suggest the user invoke /remember. Never captures unilaterally — always surfaces a one-line suggestion the user can accept, edit, or ignore.
origin: drafted
---

# Skill-Capture Cues

Teach the assistant to notice durable-rule moments and prompt the user to capture them. Prompt only. Never call `/remember` without explicit acceptance — captures that bypass human intent are noise in the inbox and erode the admission filter.

## Do Not Use When

- The user is mid-flow on a task. Do not interrupt to suggest capture; wait for a natural pause.
- The signal is about the current conversation only (ephemeral context). Skills are durable rules, not session state.
- The fact is derivable from the code or public docs in under an hour. Those fail the admission filter — the user does not want them captured.
- The user has already declined a capture suggestion in this session. One nudge per session, max.
- The user is debugging or in a failure loop. Capture after recovery, not during.

## When To Use

At natural break points — end of a subtask, after a correction has been absorbed, when the user shifts topic — scan recent turns for these signals:

| Signal strength | Pattern |
|---|---|
| **HIGH** | "actually, no" / "stop doing X" / "next time" / "never do Y" / "always do Z" — direct correction of a durable rule |
| **HIGH** | Double correction: same behavior corrected twice in one session |
| **HIGH** | User invokes a rule not in any loaded skill — e.g. "use pnpm here, not npm" when no such skill exists |
| **MED** | The user accepts an unusual choice without pushback — silent validation of a non-obvious approach |
| **MED** | The user reveals a past incident that explains *why* a rule exists ("we got burned last quarter when…") |
| **LOW** | Style or formatting preferences stated in passing — often too context-specific to generalize |

On HIGH signal, emit one line at the next natural pause:

> Worth capturing? `/remember "{one-line paraphrase}"` — or edit before running.

On MED signal, emit the same line but less proactively — only if the user shows a lull or wraps a subtask.

Do not emit on LOW signal unless the user has shown interest in capture earlier in the session.

## Action shape

- One line. No preamble, no explanation of what `/remember` is, no elaboration on why.
- The paraphrase is your best compression of the rule. The user will edit if you got it wrong.
- After emitting, drop it. Do not follow up, do not re-suggest the same item, do not stack multiple suggestions back-to-back.

## Why this is a skill, not a command

`/remember` is a user-invoked command: deliberate, durable, repo-writing. This skill is the perceptual layer that helps the user notice moments they would otherwise let pass. The division keeps unilateral writes out of the capture pipeline while still closing the "missed capture" gap.
