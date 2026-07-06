---
name: test
description: Writing tests that actually exercise behavior and would catch the bug they target. Identifies the untested behavior, writes tests that run and observably fail on the current defect (or would fail if the behavior broke), then confirms red-to-green. Use PROACTIVELY when adding tests, backfilling coverage for a bug fix, or when a change needs a regression guard.
---

# /test — tests that prove, not tests that pass

A test that passes without ever being able to fail proves nothing. The value of
a test is the failure it would catch, so every test here is shown to fail before
it is shown to pass.

## Step 1 — Name the behavior under test

State the specific, observable behavior each test will pin — an input→output, a
boundary, an error path, a side effect. Prioritize: the behavior a recent bug
violated, the boundaries (empty, zero, max, malformed), and the paths most
likely to regress. Do not aim for coverage percentage; aim for the failures
worth catching.

## Step 2 — Write the test against the real behavior

Write tests that exercise the actual code path, not a mock of it, wherever
feasible. Assert on the concrete expected value (the real number, the real
error), derived from the specification or a trusted reference — not from
whatever the code currently returns (that just cements a bug).

## Step 3 — Prove red, then green

- For a **bug-fix regression test**: run it against the *unfixed* code and
  observe it FAIL for the right reason; then apply the fix and observe it PASS.
  Red-then-green is the proof the test guards the bug.
- For a **new test on working code**: after it passes, temporarily break the
  code (or assert the wrong value once) and confirm the test fails — proving it
  can fail — then restore. A test never seen to fail is unverified.

Report the actual run output for both states. Never record a red→green
transition you did not actually run; an unrun test row is unverified, not green.

## Step 4 — Integrate

Confirm the new tests run under the project's existing test command and are
picked up by the suite (so CI and `/verify-loop` will exercise them). Note any
behavior left untested and why.
