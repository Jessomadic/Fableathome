---
name: checkpoint
description: Cross-session state for a project. "/checkpoint" writes a snapshot of goal, progress, decisions, and known issues to .fable/ in the project root; "/checkpoint load" restores it at the start of a new session. Use at significant milestones, before ending an extended session, and before context compaction.
---

# /checkpoint — persist project state

A new session starts without prior context. This procedure preserves that
context in two files under `.fable/` at the project root. Keep both concise.

## Save mode (default: `/checkpoint`)

Write `.fable/CHECKPOINT.md`, overwriting the previous contents — it is a
snapshot of the current state, not a log:

```markdown
# Checkpoint — <YYYY-MM-DD HH:mm>

## Goal
<the overall objective, one or two sentences>

## State
- Done: <completed items, each with how it was verified>
- In progress: <current item and its exact status>
- Next: <ordered next steps, specific enough to resume from>

## Known issues
<conditions that cost time and would cost the next session time: flaky
tests, misleading names, environment constraints, hypotheses ruled out>

## Blocked / needs input
<items waiting on input, credentials, or a decision>
```

Then append any decisions made during the session to `.fable/DECISIONS.md`
(create it if absent) — this file is a log and is not overwritten:

```markdown
## <YYYY-MM-DD> — <decision title>
**Chose:** <what> **Over:** <the alternatives> **Because:** <the reason>
```

Record only what is not already captured by the repository: git history
records what changed; these files record why, and what was tried and rejected.

## Load mode (`/checkpoint load`)

Read `.fable/CHECKPOINT.md`, `.fable/DECISIONS.md`, and `.fable/LESSONS.md`
(written by `/postmortem`) if present, summarize the state for the user in a
few sentences, and confirm the "Next" list before resuming. Apply recorded
lessons without being prompted. If a checkpoint references files or facts,
confirm they are still current; the repository may have changed since the note
was written.

## Maintenance

- Recommend committing `.fable/` so the state travels with the repository. Add
  it to `.gitignore` only if local-only state is preferred.
- If `DECISIONS.md` or `LESSONS.md` exceeds a few hundred lines, compact the
  oldest entries into a summary block.
