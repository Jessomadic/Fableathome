---
name: build
description: Delegated implementation loop. Use PROACTIVELY for well-scoped features and fixes — write the specification and acceptance criteria, delegate implementation to fable-builder (Sonnet), review the diff with fable-critic, and gate completion with /verify-loop. Reserves the primary context for decisions while implementation proceeds. Not for exploratory changes where the specification would be guesswork.
---

# /build — delegated implementation

The controlling task acts as the technical lead. The builder is fast and
literal; the outcome is determined by the quality of the specification and the
completion gate.

## Step 1 — Write the specification

A builder-ready specification contains:

- **Objective** — the state that exists when the change is done, one
  paragraph.
- **Files** — where the change is made, and the existing code and utilities to
  reuse (read enough to name them; "find the right place" is not a
  specification).
- **Constraints** — conventions to follow, prohibited dependencies, and code
  that must not change.
- **Acceptance criteria** — three to seven observable behaviors, each phrased
  so that pass or fail is unambiguous, including at least one that would have
  failed before the change.

For large or architecturally significant tasks, obtain a plan from
`fable-planner` first and condense it into the specification. If crisp
acceptance criteria cannot be written, the task is not yet specifiable; that
indicates `/deepthink`, or a requirement-clarification round with the user,
rather than delegation.

## Step 2 — Dispatch fable-builder

Provide the specification verbatim. The builder implements, self-verifies
against the criteria, and reports evidence. If it returns questions about
specification conflicts, resolve them and re-dispatch.

## Step 3 — Gate the result

1. Read the diff. The controlling task is accountable for what is merged.
2. For risky or unattended changes, send the diff and the builder's claims to
   `fable-critic` (design review) and `fable-verifier` (independent
   verification), in parallel.
3. Correction cycles: return findings to the builder with the failing
   criterion attached. Limit to two correction cycles; if it does not
   converge, the specification was insufficient or the task was not
   specifiable — complete it directly.
4. Completion gate: every acceptance criterion demonstrated (by the builder's
   evidence or the verifier's confirmation), or reported as UNVERIFIED with
   the reason. `/verify-loop` discipline applies.

## Report

State what was built, the acceptance-criteria table with evidence, the
critic and verifier findings and their resolution, and any UNVERIFIED items.
Note that the change was builder-implemented and lead-reviewed.
