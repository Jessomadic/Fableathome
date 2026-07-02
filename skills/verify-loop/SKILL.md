---
name: verify-loop
description: Verification of a change through demonstration. Defines observable success criteria first, exercises the changed behavior end-to-end (the real execution path, not only tests), corrects failures, and repeats until every criterion is demonstrated or reported as unverifiable. Use before declaring any non-trivial change complete, and before commits that alter runtime behavior.
---

# /verify-loop — completion by demonstration

Compilation and passing type checks do not establish that a change works.
This procedure converts "believed to work" into "observed to work."

## Step 1 — Define success criteria first

Before running anything, list every claim the change makes, phrased as an
observable behavior — for example, "GET /users/42 returns 403 for a non-admin
token," not "the fix is applied." Include at least one criterion that would
have failed before the change; it establishes that the change had an effect.

## Step 2 — Build the verification matrix

For each criterion, define how it will be exercised and record it as a row:

| # | Claim | Method | Result | Evidence |

Rules for the method:

- Prefer the real execution path: run the application, call the endpoint,
  invoke the CLI, render the output. Unit tests are supporting evidence.
- Existing test suites count, but run them and read the output.
- If a criterion cannot be exercised in the current environment (missing
  credentials, no hardware), mark it UNVERIFIABLE with the reason.

## Step 3 — Run the loop

Execute the matrix. For each failure:

1. Read the complete failure output.
2. Diagnose and correct. Retry with a modified approach, not an identical one.
3. Re-run the full matrix, not only the corrected row; corrections can
   introduce regressions.

Cap iterations at approximately five. If the matrix has not converged by then,
the approach is likely incorrect at a level verification cannot resolve;
report which criteria pass and which do not, and recommend `/deepthink` on the
remainder.

## Step 4 — Report the evidence

The output is the completed matrix plus a one-line result. Each row is PASS
(with observed evidence: command and output excerpt), FAIL, or UNVERIFIABLE
(with reason). Preserve the distinction between verified and inferred in the
summary.
