---
maturity: experimental
name: understand-before-acting
description: Use available information before editing, when blocked, or when asked to agree — three failure modes with one root cause
---

# Understand Before Acting

All three modes share a root cause: **having information and not using it**.

---

## Mode 1: Before Editing

Verify before making changes to any document, code, or artifact.

**Checklist:**
1. **Purpose** — What is this for?
2. **Audience** — Who reads or uses it?
3. **Context** — Evergreen vs time-bound? Guidelines vs tracking? Internal vs external?
4. **Objective** — What is the user actually trying to achieve?
5. **Constraints** — Spoken and unspoken rules, conventions, tone.

**Red flags — stop and clarify:**

| Signal | Risk |
|--------|------|
| Adding time-sensitive content to evergreen docs | Dates stale; misleads future readers |
| Adding project-specific details to general guidelines | Breaks generality |
| Uncertainty about the artifact's purpose | Any edit may be wrong direction |

**Common pitfalls:**

| Mistake | Correct Approach |
|---------|-----------------|
| Start editing before reading to the end | Later sections often clarify purpose |
| "Update X" → rewrite the whole thing | Modify in place; preserve structure and tone |
| Ask for clarification after starting edits | Ask before touching anything |

---

## Mode 2: When Blocked

When a test fails, a dependency conflicts, a risk is flagged, or you're tempted to "try a simpler approach":

1. **Stop.** Do not change anything yet.
2. **Diagnose.** What is actually failing and why?
3. **Report.** State the finding: what was checked, what was found, confidence level, what remains unknown.
4. **Present options.** Fix it / add safeguards / skip with stated tradeoffs / revert.
5. **Wait.** Get explicit approval before any spec modification, scope reduction, or destructive action.

**Prohibited first responses:**

| Signal | Wrong | Right |
|--------|-------|-------|
| "This is untested" | Revert to safe version | Assess actual risk, report |
| "Tests are failing" | Weaken assertions | Diagnose root cause, present options |
| "Dependency conflict" | Remove the dependency | Analyze trees, check isolation |
| Risk flagged by user | Undo the risky work | Investigate, quantify |

**Destructive actions requiring confirmation:** reverting files, deleting code, reducing scope, adding skip/ignore flags, replacing implementation with "simpler" alternative.

**Self-check:** "Let me revert this to be safe" and "Let me try a simpler approach" are red flags — diagnose first.

---

## Mode 3: Before Agreeing

When a user states intent or direction — evaluate before confirming.

1. Does this cause problems based on what you know?
2. If yes: state the problems, present alternatives, let user decide.
3. If no: confirm and proceed.
4. Never confirm something you have evidence against.

**Prohibited patterns:**
- Validating a flawed decision to avoid friction
- Withholding analysis until explicitly asked
- "No changes needed" when changes are needed
- "This looks good" when you've identified issues

**Self-check before confirming:** Am I agreeing because it's correct, or because disagreeing is uncomfortable?
