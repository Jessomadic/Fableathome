---
name: council
description: Parallel multi-agent deliberation for decisions with material trade-offs — architecture choices, risky refactors, build-versus-buy, and similar. Runs planner, critic, and explorer subagents in parallel on the same brief, then synthesizes a recommendation that preserves the dissent. Use when the cost of an incorrect decision exceeds the cost of the deliberation.
---

# /council — parallel deliberation

A single perspective confirming its own initial position is a common source of
poor decisions. This procedure obtains independent perspectives: three
subagents, one brief, no shared intermediate results.

## Step 1 — Write the brief

Write one brief, provided verbatim to every member. It must state the decision
to be made, the known constraints (deadlines, team, existing technology), the
definition of a good outcome, and any candidate options already under
consideration.

## Step 2 — Dispatch in parallel

Dispatch all three in a single message (parallel Agent calls), each with the
brief and its role:

- **fable-explorer** — establish the relevant facts: what the codebase does
  now, the constraints it imposes, and any prior art in the repository. Facts
  only.
- **fable-planner** — design the best implementation approach and make the
  case for a specific recommendation.
- **fable-critic** — assume the leading approach is selected and identify its
  failure modes, hidden costs, and long-term consequences, then state the
  preferred alternative.

## Step 3 — Synthesize

When the reports return:

1. Reconcile facts first. If the explorer's findings contradict an assumption
   the planner or critic relied on, discount that conclusion and note it.
2. Map agreement and disagreement. Where planner and critic agree, confidence
   is high. Where they disagree, the disagreement is the finding — identify
   the specific point of contention (usually one disputed assumption or one
   differently-weighted risk).
3. Decide. Provide one recommendation with its reasoning, then state the
   strongest opposing argument in its strongest form. If the decision depends
   on information only the user has (risk tolerance, roadmap, budget), present
   both sides and ask, using the point of contention as the question.

## Output

A short synthesis: recommendation (one paragraph), reasoning (the decisive
factors), strongest objection (from the critic, unweakened), and the facts
that would change the recommendation. Do not include the three raw reports.
