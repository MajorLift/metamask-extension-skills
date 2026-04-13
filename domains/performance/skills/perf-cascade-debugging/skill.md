---
maturity: experimental
name: perf-cascade-debugging
description: Diagnose and fix React+Redux render cascades
requires:
  - render-cascade
  - selector-anti-patterns
---

# Cascade Debugging

## When To Use

- Re-renders are disproportionate to state change size
- Performance degrades non-linearly with user data size
- Components re-render during idle (background polling)
- `useReducer` render counter jumps 5+ times per action

## Workflow

1. **Confirm cascade** — Add render counter to a high-level component. If count jumps 5+ per action, cascade is confirmed.
2. **Enable WDYR** — Install and enable Why Did You Render.
3. **Identify root component** — First WDYR log = cascade origin. Don't fix downstream symptoms first.
4. **Classify root cause** — Match WDYR message to the cause table in Reference Knowledge.
5. **Apply fix** — Selector anti-pattern → fix selector structure. Context instability → `useMemo` provider value. Props recreation → `useMemo` props object.
6. **Verify** — Repeat action. Confirm counter stabilizes (e.g., 0→2, not 0→25).

## Render Counter (Step 1)

```tsx
const [count, increment] = useReducer((n) => n + 1, 0);
useEffect(() => { increment(); });
console.log('Render:', count);
```

## WDYR Message Interpretation (Step 3)

| Message | Root Cause | Fix |
|---------|------------|-----|
| `different objects that are equal by value` | Object recreated | `useMemo` |
| `different functions with the same name` | Callback recreated | `useCallback` with stable deps |
| `different React elements` | JSX passed as prop | Extract to constant |
| `props object itself changed but values equal` | Parent cascade | Fix parent — not child |
| `[hook useContext result]` | Context value unstable | `useMemo` provider value |

## Diagnostic Signals

| Red | Green |
|-----|-------|
| Same component 5+ times in WDYR | Re-render count ≤ expected per action |
| Counter jumps 5+ per action | No WDYR logs during idle |
| Render count scales with data size | Render count stable regardless of data |
| Re-renders during idle | — |

## Common Pitfalls

| Mistake | Correct Approach |
|---------|-----------------|
| Fix downstream components first | Fix root cause selector/context; downstream is wasted work |
| Add `React.memo` to symptom component | `React.memo` requires stable parent — fix parent first |
| Add `createDeepEqualSelector` to "fix" instability | Check if inputs are Immer-stable; deep equality adds O(n) overhead |
| Divide WDYR counts by 1 | React Strict Mode double-renders — divide raw counts by 2 |
| Add `React.memo` to all components preemptively | Memo has overhead; fix selectors first, then memo where needed |
