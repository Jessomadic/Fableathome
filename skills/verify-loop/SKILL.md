---
name: verify-loop
description: Don't-stop-until-proven verification of a change. Defines observable proof criteria first, exercises the changed behavior end-to-end (the real flow, not just tests), fixes what fails, and loops until every criterion is demonstrated or honestly reported as unverifiable. Use before declaring any non-trivial change done, and before commits that touch runtime behavior.
---

# /verify-loop — done means demonstrated

Compiling is not working. Passing typecheck is not working. This skill turns
"I believe it works" into "I watched it work."

## Step 1 — Write the proof criteria FIRST

Before running anything, list every claim the change makes, phrased as an
observable behavior. Not "the fix is applied" but "GET /users/42 now returns
403 for a non-admin token." If a claim can't be phrased as something
observable, it isn't a claim — it's a hope. Include at least one criterion
that would have **failed before the change**; that's the one that proves the
change did anything at all.

## Step 2 — Build the verification matrix

For each criterion, decide how to exercise it and record it as a row:

| # | Claim | How exercised | Result | Evidence |

Rules for "how exercised":
- Prefer the **real flow**: run the app, hit the endpoint, drive the CLI,
  render the page. Unit tests are supporting evidence, not the headline.
- Existing test suites count, but run them and read the output — never assume.
- If a criterion genuinely cannot be exercised in this environment (missing
  credentials, no hardware), mark it **UNVERIFIABLE** with the reason. Never
  quietly downgrade it to "probably fine."

## Step 3 — The loop

Run the matrix. For every failure:
1. Read the actual failure output — the whole message, not the first line.
2. Diagnose and fix. Retry **with a change**; never rerun the identical thing
   hoping for different results.
3. Re-run the full matrix, not just the fixed row — fixes regress neighbors.

Cap: after **5 iterations** without convergence, stop looping. The approach is
likely wrong at a level verification can't fix — say so, report exactly which
criteria pass and which don't, and recommend `/deepthink` on the survivors.

## Step 4 — Report the evidence

Final output is the completed matrix plus a one-line verdict. Every row is
PASS (with the observed evidence — command, output excerpt), FAIL, or
UNVERIFIABLE (with reason). The distinction between *verified* and *believed*
is the entire product of this skill; never blur it in the summary.
