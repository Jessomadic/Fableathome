---
name: debug
description: Systematic defect localization when a bug's cause is not yet known. Reproduces the failure deterministically, narrows it to a single responsible change or component (git bisection via the fable-historian agent when the regression has a "last known good"), fixes the root cause, and verifies. Use PROACTIVELY when a reported bug's origin is unclear, when a test or behavior regressed, or when a "should work" change did not.
---

# /debug — reproduce, isolate, fix, verify

Guessing at a bug's cause and editing hopefully is the slow path. This
procedure finds the responsible code before changing anything.

## Step 1 — Reproduce deterministically

Run the failing path and observe the exact wrong result: the error text, the
wrong value, the crash, the empty output. Record it verbatim. If the failure
is intermittent, find the input, state, or ordering that makes it reliable —
an unreproducible bug cannot be confirmed fixed. Do not proceed until the
failure reproduces on demand.

## Step 2 — Localize before editing

Narrow the failure to a single component or line. Use whichever is cheapest:

- **Read the stack/error** to the originating frame; read that code.
- **Bisect the input**: shrink it until removing one more piece hides the bug.
- **Bisect the state**: log or inspect values along the failing path to find
  where a correct value becomes incorrect.
- **Bisect history**: if the behavior regressed and there is a last-known-good
  point, delegate to the **fable-historian** agent to run `git bisect` /
  `git log -S` and name the introducing commit. That commit's diff is the
  suspect set.

State the single most likely cause with the evidence for it (file:line, the
value that is wrong, the commit). One named cause, not a list of maybes.

## Step 3 — Confirm the cause, then fix the root

Before editing, confirm the hypothesis: predict what the located code does with
the failing input, then check that prediction against reality (read or run).
Fix the cause, not the symptom — prefer the layer where the value first goes
wrong over a downstream patch that masks it. If a downstream guard is the
correct fix, say why the root layer was left as-is.

## Step 4 — Verify with /verify-loop

Hand off to `/verify-loop`: the reproduction from Step 1 is the "before" proof;
re-run it and observe the correct result, then run the surrounding tests to
catch regressions. A fix is done only when the original reproduction now passes
from a real run — not from reasoning about the change.
