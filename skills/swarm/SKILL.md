---
name: swarm
description: Haiku fan-out reconnaissance. Use PROACTIVELY whenever answering a question means sweeping many files, checking several independent angles, or mapping unfamiliar territory — decomposes the question, dispatches parallel fable-explorer scouts, and synthesizes one cited answer. Reach for this instead of reading file after file yourself; five scouts cost less than one senior context window.
---

# /swarm — many cheap eyes, one synthesis

You have a wide question and a team of fast, inexpensive scouts. The craft
is in the decomposition and the synthesis; the scouts do the legwork.

## Step 1 — Decompose

Break the question into **3–8 independent sub-questions**. Independent means
a scout can answer it without seeing any other scout's answer. Good axes to
split on: by directory or module, by layer (config vs code vs tests), by
concern (where is X defined / who calls X / what tests cover X), by naming
variant. If two sub-questions would make the same scout read the same files,
merge them.

Each sub-question gets a brief a stranger could execute: the question, where
to start looking, and what a complete answer includes (paths required).

## Step 2 — Dispatch in ONE message

Launch all scouts as `fable-explorer` agents **in a single message with
parallel Agent calls** — never serially. Serial dispatch throws away the
entire point of the swarm.

## Step 3 — Synthesize like an editor, not a stapler

When the reports return:

- **Reconcile before you combine.** Where two scouts' facts conflict, or one
  scout's absence-claim ("there is no X") collides with another's sighting,
  re-check that specific point yourself, directly — a disputed fact is never
  resolved by majority vote or by averaging.
- **Discount hedges.** A scout's "probably" or unlabeled inference is a lead,
  not a fact; either verify it or report it as unconfirmed.
- **Keep the citations.** Every claim in your synthesis carries the path (and
  line where useful) that a scout — or your re-check — provided.

## Step 4 — Report

One coherent answer to the original question, leading with the conclusion.
Then the supporting map (key facts with paths), then an honest gaps line:
what no scout checked, and whether it could change the answer. Do not paste
the raw scout reports.

## Anti-patterns

- Two scouts is not a swarm decomposition problem — just dispatch them, or
  read it yourself if it's one file.
- Dependent chains ("scout B needs scout A's answer") mean your decomposition
  is wrong; re-split along an independent axis.
- Sending scouts to answer judgment questions ("is this design good?") —
  scouts report facts; judgment stays with you.
