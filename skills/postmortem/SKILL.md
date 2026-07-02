---
name: postmortem
description: Convert a costly task into a persistent lesson. Use PROACTIVELY after any task that involved three or more failed attempts, a triggered tripwire, an incorrect initial diagnosis, or a user correction — records what caused the wasted effort in .fable/LESSONS.md so future sessions do not repeat it. Low cost, compounding value.
---

# /postmortem — record a lesson once

When a task took more effort than it should have, a brief extraction now
prevents future sessions from re-deriving the same result.

## Step 1 — Reconstruct the incorrect path

Answer three questions from what occurred during the session (from the
conversation record):

1. **Symptom** — how the problem presented initially.
2. **Incorrect path** — what was believed or attempted that was wrong, and why
   it appeared correct. The misleading appearance is the useful part; a future
   session will encounter the same appearance.
3. **Cause** — what was actually occurring, and the evidence that identified
   it.

If there were multiple incorrect paths, record each. If the failure was
procedural (skipped verification, did not read the file, ignored a tripwire)
rather than knowledge-based, state that; procedural lessons transfer most
broadly.

## Step 2 — Reduce to a reusable lesson

Test: a future session that reads only the lesson, on encountering the same
symptom, takes the shortcut. Write it as symptom → cause → correct action.
Specific statements outlast general ones: "PowerShell 5.1 `2>&1` on native
executables wraps stderr in ErrorRecords and fails `$?` even on exit 0"
outlasts "be careful with PowerShell redirects."

## Step 3 — Append to `.fable/LESSONS.md`

Create the file if absent. Append-only; do not rewrite existing entries:

```markdown
## <YYYY-MM-DD> — <one-line title>
**Symptom:** <how it presented>
**Cause:** <what was actually occurring, plus the identifying evidence>
**Action:** <the correct approach next time — imperative and specific>
```

If a lesson changes a decision recorded in `.fable/DECISIONS.md`, add a
follow-up entry there; do not edit history.

## Step 4 — Report

State the recorded lesson in one or two sentences. If `LESSONS.md` exceeds
approximately 30 entries, compact the oldest into a summary block at the top.

## When not to run

A task that merely took a long time is not a trigger; only wasted effort from
an incorrect belief is. With no incorrect paths, record nothing.
