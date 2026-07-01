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

Imported into CLAUDE.md, so it shapes **every** turn of every session. Nine
rules: calibrate effort before starting (Trivial / Standard / Deep triage);
ground truth or it didn't happen; plan when it matters; done means
demonstrated; persist with a brain (retry with a change, three strikes →
re-diagnose); keep an honest ledger (verified vs. believed); communicate like
a colleague; fan out when the search space is wide; remember across sessions.

### Four skills — invoked with `/name`, or by Claude itself when a task matches

| Skill | What it forces | Reach for it when |
|---|---|---|
| `/deepthink` | Evidence sweep → ≥3 competing hypotheses → adversarial pass → plan with tripwires | Root cause unclear, design decision, a "should work" fix that didn't |
| `/verify-loop` | Proof criteria defined *first*, then an exercise-fix-repeat loop over a verification matrix | Before declaring any non-trivial change done |
| `/checkpoint` | Session state saved to `.fable/` in the project; `/checkpoint load` restores it | Milestones, end of long sessions, before context compaction |
| `/council` | Planner, critic, and explorer subagents deliberate in parallel; synthesis preserves dissent | Decisions where being wrong is expensive |

### Three subagents — dispatched by the skills or on demand

- **fable-planner** — read-only architect; returns file-specific plans grounded
  in code it actually read, with risks and a verification strategy.
- **fable-critic** — adversarial reviewer; concrete failure scenarios with
  file:line evidence, and the integrity to say "no significant issues."
- **fable-explorer** — parallel recon; returns cited conclusions, never file
  dumps. Dispatch several at once when the search space is wide.

All three inherit the session's model — the harness upgrades whatever runs
under it.

### Cross-session memory — `.fable/`

`/checkpoint` maintains two small files in each project: `CHECKPOINT.md`, a
snapshot of goal/progress/gotchas that the next session loads to skip the
amnesia, and `DECISIONS.md`, an append-only journal of *why* choices were made
— the thing git history can't tell you. Commit them so the memory travels with
the repo.

## How the pieces reinforce each other

The core's triage rule routes Deep tasks into `/deepthink`; `/deepthink`'s
adversarial phase and `/council`'s skeptic seat are both `fable-critic`; every
path ends at `/verify-loop`'s done-means-demonstrated gate; and `/checkpoint`
carries what was learned into the next session. Discipline in, capability out.

## Roadmap

- **Phase 2 (maybe):** an Agent SDK orchestrator for control flow prompts
  can't enforce — hard verification gates that block completion, best-of-N
  sampling with a judge. Out of scope for v1 on purpose: the native layer is
  zero-maintenance and already captures most of the win.
- Hooks-based enforcement (e.g., post-edit verification triggers) — deferred
  until the installer can merge `settings.json` safely.
