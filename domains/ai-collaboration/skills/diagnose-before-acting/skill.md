---
name: diagnose-before-acting
description: When blocked, diagnose before reverting, reducing scope, or creating workarounds
---

# Diagnose Before Acting

## When To Use

- A test fails, a dependency conflicts, or a risk is flagged
- Any unexpected failure during implementation
- Tempted to "try a simpler approach" after hitting a snag

## Protocol

1. **Stop.** Do not change anything yet.
2. **Diagnose.** What is actually failing and why? Check logs, dependency trees, docs.
3. **Report.** State the finding with evidence. Include: what was checked, what was found, confidence level, what remains unknown.
4. **Present options.** Fix it / add safeguards / skip with stated tradeoffs / revert.
5. **Wait.** Get explicit approval before any spec modification, scope reduction, or destructive action.

## Prohibited First Responses

| Signal | Wrong Response | Right Response |
|--------|----------------|----------------|
| "This is untested" | Revert to safe version | Assess actual risk, report finding |
| "Tests are failing" | Weaken assertions | Diagnose root cause, present options |
| "Dependency conflict" | Remove the dependency | Analyze dependency trees, check isolation |
| Risk flagged by user | Undo the risky work | Investigate the risk, quantify it |
| "This might not work" | Create simplified alternative | Investigate compatibility, report |

## Self-Monitoring Red Flags

- "Let me revert this to be safe" — without diagnosing what's unsafe
- "Let me try a simpler approach" — after the specified approach hit a snag
- Reporting "success" after silently excluding the hard parts
- Any destructive action taken without explicit user approval

## Destructive Actions That Require Confirmation

Reverting files, deleting code, reducing implementation scope, adding skip/ignore flags, replacing an implementation with a "simpler" alternative.
