# Fableathome

*"We have Fable at home."*

A drop-in harness for [Claude Code](https://claude.com/claude-code) that gives
Claude Opus (or any Claude model) as much of a frontier model's effective
capability as scaffolding can provide: enforced discipline around requirement
clarification, effort calibration, evidence-based grounding, verification
against current sources, demonstrated completion, safety, persistence, and
cross-session memory.

## The honest pitch

No harness changes model weights — nothing here turns Opus into Fable at the
level of raw intelligence. But a large share of what makes a stronger model
*feel* stronger is behavior, not knowledge:

- it asks clarifying questions up front instead of guessing at requirements;
- it sizes up a task before diving in, and thinks hard only when it should;
- it reads the code instead of guessing from file names;
- it proves claims with evidence rather than asserting them from memory;
- it checks current documentation instead of trusting a stale training cutoff;
- it proves changes work by running them, and reports honestly when it can't;
- it retries failures intelligently and never quietly drops a subtask;
- it remembers what happened last session.

All of that is enforceable with prompts, skills, subagents, and hooks. The
enforcement layers change behavior you can watch happen — the orchestrator's
judge re-runs the tests before accepting a result, the safety gate blocks
catastrophic commands, the session refuses to stop on unverified edits.
Benchmarking of the passive layer alone is still preliminary and honest about
its limits (see `bench/results.md`). That is what this repo does.

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

Imported into CLAUDE.md, so it shapes **every** turn of every session. Its
central principle: above trivial complexity, prove claims — do not guess.
Eleven sections: calibrate effort (Trivial / Standard / Deep triage);
**clarify requirements before starting** (front-load a batched set of
clarifying questions on any underspecified task); **prove claims, do not
guess** (above Trivial, every claim needs evidence — read it, run it, or
cite a source); **verify against current external sources** (use web search
and fetch proactively for libraries, APIs, versions, UI frameworks, and
admin consoles such as Entra, Intune, and Google Workspace — anything that
changes since the training cutoff or gets rebranded); plan proportionally;
completion requires
demonstration; handle failures methodically (retry with a change, three
strikes → re-diagnose); report accurately (verified vs. sourced vs.
inferred); use a neutral technical communication register; delegate by
capability; persist state across sessions.

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
| UserPromptSubmit | Injects a `/deepthink` hint on Deep-tier prompts, and a current-sources reminder on prompts about libraries, APIs, versions, UI frameworks, or admin consoles (Entra, Intune, Google Workspace, …) |
| **PreToolUse (safety)** | **Blocks catastrophic commands** — `rm -rf` of a critical path, `git push --force`, `reset --hard`, `dd`, fork bombs, pipe-to-shell, shutdown — and points at `fable-warden`. Segment-scoped, so scoped deletes (`rm -rf node_modules`) and dangerous patterns quoted inside a commit message or unrelated subcommand still pass. |
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
- Broaden the bench beyond n=1: the three-model matrix (Haiku/Sonnet/Opus) and a
  harder multi-file task (`06-tangled-trace`) are in, but per-cell runs are still
  n=1–4; raise n on the discriminating tasks and add variants that aren't
  ceiling'd at the Opus tier (see `bench/results.md`).
- ~~A/B the orchestrator judge against a bare session on the fabrication case.~~
  **Done (2026-07-06, see `bench/results.md`):** on task 02, bare single-shot Haiku
  shipped an unverified, fragile fix (~1/10); the orchestrator loop — even with a
  *Haiku* judge — caught the fabrication (the judge re-runs the script, observes 2
  attempts not the claimed 10) and drove a verified robust `[int]` fix (8/10). The
  judge doesn't need to be smart, only to run the code. Hardening the executor
  contract cut it from 3 rounds to 1 at ⅓ the cost. This is the durable fix for
  weak-model fabrication; prompt hardening only removes the incentive.
- Raise n on the enforcement A/B and regression-test the hardened executor contract
  on Sonnet/Opus executors (expected no downside — they already run the code).
