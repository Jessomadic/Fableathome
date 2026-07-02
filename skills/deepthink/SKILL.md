---
name: deepthink
description: Structured multi-pass reasoning for Deep-tier problems — unclear root causes, cross-cutting changes, design decisions, and changes that are expensive to reverse. Enforces evidence-gathering, competing hypotheses, and an adversarial pass before any code is modified. Use when a first hypothesis fails, when an expected fix does not work, or before committing to an architecture.
---

# /deepthink — multi-pass reasoning

This procedure guards against premature convergence: committing to the first
plausible hypothesis and spending the task confirming it. Work through the
phases in order and record the reasoning in the conversation.

## Phase 0 — Restate and define success

In two or three sentences, state what is being asked and the observable
condition that constitutes a solution. If the success condition cannot be
stated as something demonstrable, the task is underspecified — identify what
is missing before proceeding.

## Phase 1 — Gather evidence

Establish ground truth before forming hypotheses. Read the relevant code, run
the failing command, reproduce the defect, check the logs. Record two lists:

- **Facts** — directly observed, each with its source (file:line, command
  output).
- **Assumptions** — believed but not yet verified. Convert load-bearing
  assumptions to facts before Phase 4.

For a wide search space, dispatch `fable-explorer` agents in parallel rather
than reading sequentially.

## Phase 2 — Enumerate before selecting

Generate at least three materially different hypotheses (for a defect) or
options (for a design decision). For each, record the supporting evidence, the
evidence that would refute it, and the cost of being wrong. Rank them.

## Phase 3 — Adversarial pass

Attempt to refute the leading candidate. Identify the edge case, concurrency
condition, or incorrect assumption that would break it, and what it fails to
explain that a competing hypothesis explains. If it survives, proceed; if not,
return to Phase 2 with the new information. For high-impact decisions, delegate
this pass to a `fable-critic` agent so the review is independent of its author.

## Phase 4 — Converge and plan

Select the surviving candidate. Record a short plan: steps, files, order, and
tripwires — explicit conditions of the form "this plan assumes X; if X is
false, stop and return to Phase 2." Tripwires prevent continued execution of a
disproven hypothesis.

## Phase 5 — Execute against the tripwires

Carry out the plan. When a tripwire condition occurs, re-diagnose rather than
working around it. Validate the result against the Phase 0 success condition
(use `/verify-loop` for non-trivial changes), and report which hypotheses were
considered and why the selected one was chosen.
