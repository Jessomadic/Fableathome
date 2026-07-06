---
name: verify-loop
description: Verification of a change through demonstration. Defines observable success criteria first, exercises the changed behavior end-to-end (the real execution path, not only tests), corrects failures, and repeats until every criterion is demonstrated or reported as unverifiable. Use before declaring any non-trivial change complete, and before commits that alter runtime behavior.
---

# /verify-loop — completion by demonstration

Compilation and passing type checks do not establish that a change works.
This procedure converts "believed to work" into "observed to work."

## Step 0 — Reproduce the failure first (for bug fixes)

Before editing, execute the failing path and observe the incorrect result:
the wrong total, the error text, the empty output, the premature exit. Record
the broken value. This confirms the reported defect is the real one (not a
misdirection), and it is the "before" half of the proof that the fix had an
effect. Skipping this step is the most common reason a fix is declared done
while the original bug is still present.

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
- Most code is runnable here. On Windows, execute PowerShell through the shell
  tool with `powershell.exe -NoProfile -Command "..."`; do not record a
  criterion as unverifiable merely because there is no interactive shell.
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

Every evidence excerpt must come from an execution that actually ran. Do not
construct a plausible-looking output, transcript, or test result to fill a row;
a row with no real execution is UNVERIFIABLE, not PASS. Fabricated evidence
defeats the entire purpose of the loop and is worse than an honest gap.
