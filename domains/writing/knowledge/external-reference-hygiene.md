---
name: external-reference-hygiene
domain: writing
description: Every reference in externally posted text must be self-contained and resolvable by a reader who has never seen your working document.
---

# External Reference Hygiene

References in posted text must be self-contained. The reader does not share your working context.

## Rule

Every reference in externally consumed text must be interpretable at the point of consumption — full URLs with descriptive link text, not shorthand labels or internal anchors.

## Failure Modes

| Anti-pattern | Problem |
|---|---|
| Bare issue/PR numbers (`#42`) without URLs | Meaningless outside the repo context |
| Internal labels (`#27`, `comment #30`) from working docs | Only make sense in your own document |
| Non-resolving anchors (`#section-id`) in PR comments | Resolve within an ADR but not on the PR feed |
| Section anchors that assume reader's document context | Reader's feed may not include the document being referenced |
| Implicit ordinals ("the previous comment", "above") | Reader's feed may render comments in a different order |

## Detection

Before posting any text: does every reference resolve for a reader who has never seen your working document? If not, expand to full URL with descriptive link text, or rephrase to be self-contained.

## Root Cause

Treating internal working-doc shorthand as reader-facing text. The gap between "I know what this means" and "the reader knows what this means" is where context leaks.
