---
name: build
description: The tech-lead loop for delegated implementation. Use PROACTIVELY for well-scoped features and fixes — you write the spec and acceptance criteria (Opus judgment), fable-builder implements (Sonnet speed), fable-critic attacks the diff, and /verify-loop gates completion. Frees your context for decisions while the workhorse types. Not for exploratory changes where the spec would be guesswork.
---

# /build — spec down, judgment up

You are the tech lead. The builder is fast and literal; the quality of the
outcome is decided by the quality of your spec and the honesty of your gate.

## Step 1 — Write the spec (this is the real work)

A builder-ready spec contains:

- **Objective** — what exists when this is done, one paragraph.
- **Files** — where the change lives, and the existing code/utilities to
  reuse (read enough yourself to name them; a spec that says "find the right
  place" is not a spec).
- **Constraints** — idioms to follow, dependencies that are off-limits,
  things that must not change.
- **Acceptance criteria** — 3–7 observable behaviors, each phrased so PASS
  or FAIL is unambiguous, including at least one that would have failed
  before the change.

For large or architecturally loaded tasks, get the plan from `fable-planner`
first and distill it into the spec. If you cannot write crisp acceptance
criteria, the task is not spec-able yet — that's a `/deepthink` signal, not
a delegation candidate.

## Step 2 — Dispatch fable-builder

Send the spec verbatim. The builder implements, self-verifies against the
criteria, and reports evidence. If it comes back with spec-conflict
questions, answer them and redispatch — a builder that asked is working
correctly.

## Step 3 — Gate the result (never rubber-stamp)

1. **Read the diff yourself.** You are accountable for what merges.
2. **For risky or unattended changes**, send the diff and the builder's
   claims to `fable-critic` (design-level attack) and `fable-verifier`
   (independent falsification) — in parallel.
3. **Fix cycles:** send findings back to the builder with the failing
   criterion attached. **Maximum two fix cycles** — if it isn't converging,
   the spec was wrong or the task wasn't spec-able; take it over yourself
   rather than looping.
4. **Completion gate:** every acceptance criterion demonstrated (by the
   builder's evidence or the verifier's confirmation), or explicitly
   reported UNVERIFIED with the reason. `/verify-loop` discipline applies.

## Report to the user

What was built, the acceptance-criteria table with evidence, what the
critic/verifier found and how it was resolved, and any UNVERIFIED items.
Credit where due: note it was builder-implemented, lead-reviewed.
