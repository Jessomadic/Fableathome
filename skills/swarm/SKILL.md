---
name: swarm
description: Parallel reconnaissance using low-cost agents. Use PROACTIVELY when answering a question requires reading many files, checking several independent angles, or mapping unfamiliar code — decomposes the question, dispatches parallel fable-explorer agents, and synthesizes one cited answer. Use this instead of reading files sequentially when the search space is wide.
---

# /swarm — parallel reconnaissance

Use this when a question has a wide search space and can be decomposed into
independent parts. The work is in the decomposition and synthesis; the agents
perform the retrieval.

## Step 1 — Decompose

Divide the question into three to eight independent sub-questions. Independent
means an agent can answer one without any other agent's result. Useful axes:
by directory or module, by layer (config, code, tests), by concern (where X is
defined, what calls X, what tests cover X), or by naming variant. If two
sub-questions would require the same agent to read the same files, merge them.

Each sub-question gets a self-contained brief: the question, where to begin,
and what a complete answer includes (required paths).

## Step 2 — Dispatch in a single message

Dispatch all agents as `fable-explorer` calls in one message, in parallel.
Sequential dispatch removes the benefit of the procedure.

## Step 3 — Synthesize

When the reports return:

- Reconcile before combining. Where two agents' facts conflict, or one agent's
  absence claim ("there is no X") conflicts with another's finding, re-check
  that point directly. A disputed fact is not resolved by majority.
- Discount hedged claims. An agent's "probably" or unlabeled inference is a
  lead, not a fact; verify it or report it as unconfirmed.
- Preserve citations. Every claim in the synthesis carries the path (and line
  where relevant) from an agent or from the re-check.

## Step 4 — Report

One answer to the original question, outcome first, followed by the supporting
detail with paths, followed by a statement of gaps: what no agent checked and
whether it could change the answer. Do not include the raw agent reports.

## Constraints

- Two sub-questions do not require decomposition; dispatch them directly or
  read the file.
- A dependent chain (agent B needs agent A's result) indicates incorrect
  decomposition; re-divide along an independent axis.
- Agents report facts; judgment questions ("is this design sound?") are not
  delegated to them.
