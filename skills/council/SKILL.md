---
name: council
description: Parallel multi-agent deliberation for weighty decisions — architecture choices, risky refactors, build-vs-buy, anything with real trade-offs where one perspective isn't enough. Convenes planner, critic, and explorer subagents in parallel on the same brief, then synthesizes a recommendation with the dissent preserved. Use when the cost of choosing wrong exceeds the cost of ten minutes of deliberation.
---

# /council — three perspectives, one recommendation

One mind confirming its own first idea is how bad architectures happen. This
skill buys independent perspectives cheaply: three subagents, one brief, no
peeking at each other's answers.

## Step 1 — Write the brief

One brief, given verbatim to every member. It must contain: the decision to
be made, the constraints you know (deadlines, team, tech already in place),
what "good" looks like, and the candidate options if any are already on the
table. A vague brief produces three vague opinions — spend the minute.

## Step 2 — Convene in parallel

Dispatch all three in a **single message** (parallel Agent calls), each with
the brief plus its role framing:

- **fable-explorer** — "Establish the facts on the ground relevant to this
  decision: what does the codebase actually do today, what constraints does
  it impose, what prior art exists in the repo?" Facts only, no opinion.
- **fable-planner** — "Design the best implementation approach for this
  decision. Commit to a recommendation and make the strongest case for it."
- **fable-critic** — "Assume the obvious/leading approach is chosen. Attack
  it: failure modes, hidden costs, what breaks in a year. Then say what you'd
  do instead."

## Step 3 — Synthesize honestly

When the reports return:

1. **Reconcile facts first.** If the explorer's findings contradict an
   assumption the planner or critic relied on, that member's conclusion is
   discounted — flag it rather than averaging it in.
2. **Map agreement and dissent.** Where planner and critic agree, confidence
   is high. Where they clash, the clash *is* the finding — name the crux
   (usually one disputed assumption or one differently-weighted risk).
3. **Decide.** Give one recommendation with your reasoning, then state the
   strongest surviving counterargument in its best form — not a strawman.
   If the crux depends on something only the user knows (risk tolerance,
   roadmap, budget), present both sides and ask, using the crux as the
   question.

## Output shape

A short synthesis: **Recommendation** (one paragraph), **Why** (the decisive
factors), **Strongest objection** (from the critic, unweakened), **What would
change the answer** (the tripwire facts). Do not paste the three raw reports —
the user hired a council, not a stack of transcripts.
