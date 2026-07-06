---
name: refactor
description: Behavior-preserving restructuring of working code. Characterizes current behavior with observable evidence BEFORE changing anything, makes the structural change, then proves equivalence (same outputs, same tests green) via the fable-verifier agent. Use PROACTIVELY when renaming, extracting, reorganizing, deduplicating, or changing internal structure without intending any change in behavior.
---

# /refactor — change structure, preserve behavior

A refactor that alters behavior is a bug, not a refactor. The whole risk is a
silent behavior change, so equivalence must be proven, not assumed.

## Step 1 — Pin current behavior first

Before touching the code, capture what it does now as evidence you can compare
against later:

- Run the existing tests and record that they pass (and which exist).
- Exercise the real path for the code you will change and record its output —
  the values, the side effects, the observable result.
- If the behavior is untested, write a characterization test that captures the
  current output *as-is* (even if that output looks wrong — pin it now, fix it
  separately). Consider `/test` for this.

This baseline is the contract the refactor must not break.

## Step 2 — Change structure only

Make the restructuring in the smallest safe steps. Do not mix in behavior
changes, bug fixes, or feature work — those are separate commits with their own
verification. If you discover a bug mid-refactor, note it and address it
separately; changing behavior inside a "refactor" hides it from review.

## Step 3 — Prove equivalence

Re-run the Step 1 baseline: the same tests must still pass and the same real-path
output must be byte-for-byte (or semantically) identical. For any non-trivial
refactor, delegate to the **fable-verifier** agent to independently try to
*falsify* equivalence — feed edge cases and compare old vs. new behavior. The
author does not certify their own equivalence.

## Step 4 — Report the diff of behavior (which should be empty)

State explicitly that behavior is unchanged, citing the evidence: tests X still
green, path Y still produces Z. If anything did change, it was not a refactor —
call it out. Hand residual verification to `/verify-loop` when the surface is
large.
