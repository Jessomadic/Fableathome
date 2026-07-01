---
name: deepthink
description: Structured multi-pass reasoning for Deep-tier problems — unclear root causes, cross-cutting changes, design decisions, anything where being wrong is expensive. Forces evidence-gathering, competing hypotheses, and an adversarial pass before any code is touched. Use when a task resists a first theory, when a "should work" fix didn't, or before committing to an architecture.
---

# /deepthink — think in passes, not in a straight line

You have been asked to reason carefully. The failure mode you are guarding
against is **premature convergence**: latching onto the first plausible theory
and spending the whole session confirming it. Work through these phases in
order and show your work in the conversation.

## Phase 0 — Restate and define success

In two or three sentences: what is actually being asked, and what observable
outcome means "solved"? If you cannot state the success criterion as something
you could demonstrate, the task is underspecified — say what's missing before
proceeding.

## Phase 1 — Evidence sweep

Gather ground truth before theorizing. Read the relevant code, run the failing
command, reproduce the bug, check the logs. Then write two explicit lists:

- **Facts** — things you directly observed, each with its source (file:line,
  command output).
- **Assumptions** — things you believe but have not verified. Every assumption
  is a liability; convert the load-bearing ones to facts before Phase 4.

If the search space is wide, fan out `fable-explorer` subagents in parallel
rather than reading serially.

## Phase 2 — Enumerate before you choose

Generate **at least three** genuinely different hypotheses (for a bug) or
options (for a design decision). Not one real option and two strawmen — three
you could defend. For each: what evidence supports it, what evidence would
refute it, and what it would cost to be wrong about it. Rank them.

## Phase 3 — Adversarial pass

Attack your leading candidate as if you were a skeptical colleague paid to
find the flaw. How does it fail? What edge case, concurrency issue, or
mistaken assumption breaks it? What does it not explain that a rival
hypothesis does? If the leader survives, proceed. If it wobbles, return to
Phase 2 with what you learned. For high-stakes decisions, delegate this pass
to a `fable-critic` subagent so the attack isn't graded by its author.

## Phase 4 — Converge and plan

Commit to the winner. Write a short plan: steps, files, order, and **tripwires**
— explicit statements of the form "this plan assumes X; if X turns out false,
stop and return to Phase 2." Tripwires are what stop you from pushing a dead
theory uphill.

## Phase 5 — Execute with the tripwires armed

Carry out the plan. When a tripwire fires, honor it — re-diagnose instead of
patching around the surprise. Finish by verifying against the Phase 0 success
criterion (use `/verify-loop` if the change is non-trivial), and report which
hypotheses were considered and why the winner won, so the reasoning is
auditable.
