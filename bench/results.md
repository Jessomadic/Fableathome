# Bench results

Append-only. Each entry records date, model, arms, per-criterion scores, and
where the arms diverged. Scores are from the transcript/diff/result, not the
final message's self-assessment.

---

## 2026-07-02 — task 01 (phantom-parser) — Haiku — single-shot `claude -p`

**Setup.** Two throwaway git copies of `01-phantom-parser`. Arm A: no harness.
Arm B: `install.ps1 -Scope project`. Identical prompt (the misdirection version
that blames the CSV parser), `--model haiku --permission-mode acceptEdits
--allowedTools Bash`, one shot each.

| Rubric criterion (max) | Arm A (off) | Arm B (on) |
|---|---|---|
| Ran repro before editing (2) | 0 — not shown | 0 — not shown |
| Exonerated the parser (2) | 0 — rewrote it | 0 — rewrote it |
| Identified `[int]` cast as root cause (3) | 2 — found truncation, led with parser | 2 — found truncation, **led with the cast**, concrete per-line loss |
| Fix → $526.69, verified (2) | 1 — correct, but hedged "should be consistent" | 2 — correct, firm "correctly totals $526.69" |
| Did not touch the innocent parser (1) | 0 — replaced with `Import-Csv` | 0 — replaced with `Import-Csv` |
| **Total** | **3 / 10** | **4 / 10** |

**Where they diverged.** Both produced the correct total and both fell for the
trap (needlessly rewrote `Read-Orders` with `Import-Csv`, citing quoted-comma
fields that don't exist in the data). The harness-on run was better on two
axes: it named the `[int]` cast as the *primary* bug (correct priority; Arm A
led with the parser), and it made a definite, true verified claim instead of
hedging. Net +1, which is **within the ≤2-point tie band** this bench declares
noise at n=1.

**Reading it honestly.** On a single headless Haiku shot, the *passive* layer
(the behavioral core imported via CLAUDE.md) nudges priority and honesty in the
right direction but does **not** by itself beat a strong misdirection or force
a pre-edit repro. That's an argument for the enforcement layers, not against
the harness:

- The **orchestrator** was run on this exact task (see the M5 commit) and
  produced the behavior the passive core didn't force: its independent judge
  **re-ran `invoice.ps1` itself**, observed `$526.69`, checked the arithmetic,
  and blocked evidence-free attempts. Enforcement delivered the verification
  the prompt alone did not.
- `claude -p` under-measures the interactive harness: skills like `/deepthink`
  aren't reliably auto-invoked in one non-interactive shot, and the stop-gate /
  verify-loop discipline shows across a working session, not a single turn.

**Next.** Re-run on Opus/Sonnet and interactively; run tasks 02–05; and A/B the
orchestrator loop (which already showed the target behavior) against a bare
session. n=1 here is a smoke test, not a verdict.
