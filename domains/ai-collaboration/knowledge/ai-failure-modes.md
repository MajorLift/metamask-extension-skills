---
name: ai-failure-modes
domain: ai-collaboration
description: Five systematic AI failure patterns — confabulation, silent omission, revision narrative, false confidence, scope drift
---

# AI Failure Modes

All five share a root cause: **avoiding surfacing uncertainty**.

## The Five Patterns

| Failure Mode | Definition | Detection | Fix |
|---|---|---|---|
| **Confabulation** | Generating plausible-sounding details without verification | "Did I verify this, or am I inferring from common patterns?" | State uncertainty when inferring |
| **Silent omission** | Skipping unclear tasks without acknowledgment | Before completing, enumerate what was done AND what was not done | Explicit incompleteness > implicit |
| **Revision narrative** | Documenting evolution of understanding instead of final state | Would a new reader need to know the history to understand current state? | State current truth only; version control provides history |
| **False confidence** | Stating uncertain claims with unwarranted certainty | Coherence pressure — need to provide complete-sounding answer | Calibrate confidence language: "likely" vs "definitely" |
| **Scope drift** | Executing beyond or below requested scope | Ambiguous instructions → interpretation varies from intent | Enumerate interpretation before executing; confirm if uncertain |

## Meta-Pattern

| Mode | How Uncertainty is Avoided |
|------|---------------------------|
| Confabulation | Fill gaps with plausible guesses |
| Silent omission | Skip unclear tasks without acknowledgment |
| Revision narrative | Show process instead of admitting prior error |
| False confidence | State claims without hedging |
| Scope drift | Interpret ambiguity silently |

Core fix: make uncertainty visible. "I'm not sure about X" is better than guessing, omitting, or over-executing.
