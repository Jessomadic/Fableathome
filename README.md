# Fableathome

*"We have Fable at home."*

A drop-in harness for [Claude Code](https://claude.com/claude-code) that gives
Claude Opus (or any Claude model) as much of a frontier model's effective
capability as scaffolding can provide: enforced discipline around calibration,
grounding, verification, persistence, and memory.

## The honest pitch

No harness changes model weights — nothing here turns Opus into Fable at the
level of raw intelligence. But a large share of what makes a stronger model
*feel* stronger is behavior, not knowledge:

- it sizes up a task before diving in, and thinks hard only when it should;
- it reads the code instead of guessing from file names;
- it considers competing hypotheses instead of marrying the first one;
- it proves changes work by running them, and reports honestly when it can't;
- it retries failures intelligently and never quietly drops a subtask;
- it remembers what happened last session.

All of that is enforceable with prompts, skills, and subagents — and enforcing
it measurably improves any model running underneath. That is what this repo
does.

## Install

```powershell
# Everywhere on this machine (~/.claude — every project benefits):
.\install.ps1

# One project only:
.\install.ps1 -Scope project -Target C:\path\to\repo

# Remove (same scopes):
.\install.ps1 -Uninstall
```

The installer copies files and adds one clearly-marked import block to
CLAUDE.md. It never overwrites your existing CLAUDE.md content, re-running it
is safe (upgrade-in-place), and uninstall removes exactly what install added.
New Claude Code sessions pick everything up automatically.

## What's inside

### The behavioral core — `core/fable-core.md`

Imported into CLAUDE.md, so it shapes **every** turn of every session. Ten
sections: calibrate effort (Trivial / Standard / Deep triage); **clarify
requirements before starting** (front-load a batched set of clarifying
questions on any underspecified task); ground claims in evidence; plan
proportionally; completion requires demonstration; handle failures
methodically (retry with a change, three strikes → re-diagnose); report
accurately (verified vs. inferred); use a neutral technical communication
register; delegate by capability; persist state across sessions.

### Seven skills — invoked with `/name`, or by Claude itself when a task matches

| Skill | What it forces | Reach for it when |
|---|---|---|
| `/deepthink` | Evidence sweep → ≥3 competing hypotheses → adversarial pass → plan with tripwires | Root cause unclear, design decision, a "should work" fix that didn't |
| `/verify-loop` | Proof criteria defined *first*, then an exercise-fix-repeat loop over a verification matrix | Before declaring any non-trivial change done |
| `/checkpoint` | Session state saved to `.fable/` in the project; `/checkpoint load` restores it | Milestones, end of long sessions, before context compaction |
| `/council` | Planner, critic, and explorer subagents deliberate in parallel; synthesis preserves dissent | Decisions where being wrong is expensive |

Three more skills exploit the model-routed team below: `/swarm` (Haiku
fan-out recon), `/build` (Opus spec → Sonnet build → Opus critique), and
`/postmortem` (wrong turns become permanent lessons in `.fable/LESSONS.md`).

### Seven subagents, routed across the model family

Opus = judgment, Sonnet = workhorse, Haiku = swarm. The core's dispatch
doctrine routes each job automatically:

- **fable-planner** (Opus) — read-only architect; file-specific plans grounded
  in code it actually read.
- **fable-critic** (Opus) — adversarial reviewer; concrete failure scenarios
  with file:line evidence, and the integrity to say "no significant issues."
- **fable-warden** (Opus) — blast-radius reviewer consulted before irreversible
  actions when running unattended.
- **fable-builder** (Sonnet) — implements a tight spec and self-verifies.
- **fable-verifier** (Sonnet) — independently tries to *falsify* a change's
  claims; the author never grades their own homework.
- **fable-explorer** (Haiku) — parallel recon; cited conclusions, never dumps.
- **fable-historian** (Haiku) — git archaeology: which commit introduced X.

### Hooks — deterministic enforcement (built for approve-all + walk away)

Installed into `settings.json`, these run whether or not the model cooperates:

| Hook | Does |
|---|---|
| SessionStart | Auto-loads `.fable/` memory into context |
| UserPromptSubmit | Injects a `/deepthink` hint on Deep-tier prompts |
| **PreToolUse (safety)** | **Blocks catastrophic commands** — `rm -rf` of a critical path, `git push --force`, `reset --hard`, `dd`, fork bombs, pipe-to-shell, shutdown — and points at `fable-warden`. Scoped deletes (`rm -rf node_modules`) still pass. |
| PostToolUse | Tracks edits vs. real verification runs (read-only commands don't count) |
| Stop | Blocks once if you edited code but never exercised it |
| PreCompact | Preserves goal/decisions/gotchas through compaction |

### Cross-session memory — `.fable/`

`/checkpoint` maintains `CHECKPOINT.md` (a snapshot the next session loads to
skip the amnesia) and `DECISIONS.md` / `LESSONS.md` (append-only journals of
*why* choices were made and what traps cost time — the things git history
can't tell you). Commit them so the memory travels with the repo.

## The orchestrator — enforcement prompts can't provide

`orchestrator/` wraps sessions in control flow: an executor does the work, an
independent judge inspects the diff and **demands verification evidence** (and
may run the tests itself), and the loop retries until it passes. `--best-of N`
runs parallel attempts in git worktrees and applies the judge-picked winner.
No evidence, no done — the judge is code, not a suggestion. See
`orchestrator/README.md`.

## Tests

`tests/Run-Tests.ps1` runs the whole suite — the dangerous-command detector
(block vs. allow matrix), the hook I/O contracts, and the installer's
settings.json merge/idempotence/uninstall. The safety intercept is also
verified live: a real session's `git reset --hard` was blocked end-to-end.
Preliminary bench numbers are in `bench/results.md`.

## How the pieces reinforce each other

The core's triage routes Deep tasks into `/deepthink`; its adversarial phase
and `/council`'s skeptic seat are both `fable-critic`; every path ends at
`/verify-loop`'s done-means-demonstrated gate, backstopped by the Stop hook;
`/checkpoint` carries lessons forward; and the orchestrator's judge enforces
from outside what the prompts ask for from within. Discipline in, capability
out.

## Roadmap

- Cross-platform hooks (bash + `install.sh`) — today the hooks and installer
  are Windows/PowerShell only.
- Broaden the bench beyond n=1: more tasks, stronger models, interactive and
  orchestrator-loop A/B runs.
