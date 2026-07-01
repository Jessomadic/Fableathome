---
name: postmortem
description: Turn a painful task into permanent memory. Use PROACTIVELY after any task that involved three or more failed attempts, a fired tripwire, a wrong initial diagnosis, or a user correction — extracts what actually cost time into .fable/LESSONS.md so no future session pays for the same lesson twice. Cheap to run, compounds forever.
---

# /postmortem — pay for each lesson once

Something just cost more time than it should have. Five minutes of honest
extraction now saves every future session from re-deriving it.

## Step 1 — Reconstruct the wrong turn

Answer three questions from what actually happened this session (check the
conversation, not your pride):

1. **Symptom** — what did the problem look like at first contact?
2. **Wrong turn** — what did we believe or try that was wrong, and *why was
   it believable*? (The trap's disguise is the valuable part — the next
   session will see the same disguise.)
3. **Truth** — what turned out to be actually going on, and what evidence
   finally exposed it?

If there were multiple wrong turns, each gets its own entry. If the failure
was process (skipped verification, didn't read the file, ignored a tripwire)
rather than knowledge, say that plainly — those lessons transfer the widest.

## Step 2 — Distill to a lesson a stranger can use

The test: a future session that reads only the lesson, hitting the same
symptom, takes the shortcut. Write it as symptom → trap → truth → move.
Concrete beats general: "PS 5.1 `2>&1` on native exes wraps stderr in
ErrorRecords and fails `$?` even on exit 0" outlives "be careful with
PowerShell redirects."

## Step 3 — Append to `.fable/LESSONS.md`

Create the file if missing. **Append-only** — never rewrite old entries:

```markdown
## <YYYY-MM-DD> — <one-line title>
**Symptom:** <what it looked like>
**Trap:** <the believable wrong theory/approach, and why it was believable>
**Truth:** <what was actually going on + the evidence that exposed it>
**Move:** <the shortcut next time — imperative, specific>
```

If the lesson changes a decision already logged in `.fable/DECISIONS.md`,
add a follow-up entry there too; never edit history.

## Step 4 — Close the loop

Tell the user in one or two sentences what lesson was banked. If LESSONS.md
has grown past ~30 entries, compact the oldest into a summary block at the
top (this is the one permitted rewrite).

## When NOT to run this

A task that merely took long isn't a postmortem trigger — only wasted work
from a wrong belief is. Zero wrong turns, zero entries; never invent a
lesson to have something to write.
