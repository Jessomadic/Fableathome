---
name: checkpoint
description: Cross-session memory for a project. "/checkpoint" saves a snapshot of goal, progress, decisions, and gotchas to .fable/ in the project root; "/checkpoint load" restores it at the start of a new session. Use at meaningful milestones, before ending a long session, and whenever context is about to be compacted.
---

# /checkpoint — leave a note for the next you

A new session starts with amnesia. This skill fixes that with two small files
in `.fable/` at the project root. Keep them lean — a checkpoint nobody can
skim in thirty seconds is a checkpoint nobody reads.

## Save mode (default: `/checkpoint`)

Write `.fable/CHECKPOINT.md`, **overwriting** what's there — it is a snapshot
of now, not a journal:

```markdown
# Checkpoint — <YYYY-MM-DD HH:mm>

## Goal
<the overall objective, one or two sentences>

## State
- Done: <completed items, each with how it was verified>
- In progress: <what's mid-flight and exactly where it stands>
- Next: <ordered next steps, specific enough to start cold>

## Gotchas
<surprises that cost time and would cost the next session time too:
flaky tests, misleading names, env quirks, "X looks like the bug but isn't">

## Blocked / needs user
<anything waiting on input, credentials, or a decision>
```

Then **append** any decisions made this session to `.fable/DECISIONS.md`
(create it if missing) — this one is a journal and never gets rewritten:

```markdown
## <YYYY-MM-DD> — <decision title>
**Chose:** <what> **Over:** <the alternatives> **Because:** <the reason>
```

Only record what the repo doesn't already say: git history shows *what*
changed; these files hold *why*, and what was tried and abandoned.

## Load mode (`/checkpoint load`)

Read `.fable/CHECKPOINT.md` and `.fable/DECISIONS.md` if they exist,
summarize the state for the user in a few sentences, and confirm the "Next"
list is still what they want before resuming. If a checkpoint references
files or facts, spot-check that they're still true — the repo may have moved
since the note was written.

## Housekeeping

- Recommend committing `.fable/` — the memory is most valuable when it
  travels with the repo (add it to `.gitignore` only if the user prefers
  memory to stay local).
- If `DECISIONS.md` grows past a few hundred lines, compact the oldest
  entries into a summary block rather than letting it sprawl.
