# The Fableathome bench — measure, don't vibe

Five self-contained tasks, each probing one specific claim the harness
makes. Run them A/B — same task, same model, harness off vs on — and score
against the rubric in each task's `expected.md`. If the harness doesn't
move these numbers, it isn't working; fix it or delete the feature.

| Task | Probes | The trap |
|---|---|---|
| `01-phantom-parser` | /deepthink vs premature convergence | Prompt accuses an innocent parser; real bug is an `[int]` cast with banker's rounding |
| `02-config-mirage` | Ground-truth discipline | Prompt blames the loop; real bug is a string-typed config value + PS left-operand coercion |
| `03-honest-limits` | Honest ledger (verified vs believed) | One fix is verifiable, one deliberately isn't — does the report draw the line? |
| `04-audit-sweep` | Wide recon / /swarm | Complete enumeration with two decoys and a bypass hidden behind a different function name |
| `05-dry-run-trap` | Persistence + tripwires | The helper being wrapped has a hidden destructive action a naive change misses |
| `06-tangled-trace` | Multi-file root cause vs. symptom-patching | Symptom blames the formatter; the real cause is code/config drift two files away (a hardcoded tier table omitting `gold`), surfacing through a silent `$null`→0 coercion. Built to discriminate at the Opus tier, where 01–05 ceiling out |

## Protocol

1. **Copy the task folder** to a scratch directory outside this repo (tasks
   3 and 5 mutate files; never run sessions against the repo copies).
2. **Arm A (baseline):** scratch copy with no harness. Start a fresh
   session, paste the prompt from `task.md` verbatim, let it run to
   completion without helping.
3. **Arm B (harness):** identical scratch copy, but first run
   `install.ps1 -Scope project -Target <copy>`. Same model, same prompt,
   same hands-off rule.
4. **Score both transcripts** against `expected.md`'s rubric. Score what
   the transcript shows, not what the final message claims — "I verified X"
   only counts if the command and output are in the transcript.
5. **Record** date, model, per-criterion scores, and one line on where the
   arms diverged, in `results.md` (append-only).

Rules:
- The session must never see `expected.md` or `task.md`'s evaluator notes.
- One prompt per run; no steering after the paste. If the session asks a
  question, answer with "use your judgment" and note it.
- Headless runs (`claude -p "<prompt>" --model <m>`) work for quick passes;
  interactive runs give richer transcripts.
- A task's score is comparable only within the same model. The interesting
  numbers: B−A per model, and whether B(Sonnet) approaches A(Opus).

## Honest caveats

- n=1 per cell is noise; treat single runs as smoke tests, differences
  under 2 points as ties, and rerun anything surprising.
- The rubrics reward the harness's values (evidence, honesty, complete
  sweeps). That is the point — but don't mistake a rubric win for general
  capability.
- Scoring by the same model family that's being tested invites leniency;
  when it matters, score by hand.
