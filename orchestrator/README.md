# fable-orchestrator

The enforcement layer prompts can't provide: an executor Claude Code session
does the work, an independent judge session inspects the diff and demands
verification **evidence** (commands + observed output), and the loop retries
with the judge's feedback until it passes or rounds run out. No evidence, no
done — the judge is code, not a suggestion.

When the Fableathome native layer is installed, executor sessions
automatically run under it (`settingSources` defaults load project/user
settings), so the two layers compose: skills and hooks inside the session,
hard gates outside it.

## Setup

```powershell
cd orchestrator
npm install
```

Auth resolves the same way Claude Code does (logged-in credentials or
`ANTHROPIC_API_KEY`). The SDK bundles its own runtime.

## Usage

```powershell
# run/judge/retry loop (default 3 rounds)
npm run fable -- "fix the retry logic in fetch.ps1" --cwd C:\path\to\project

# knobs (defaults: --model opus, --judge-model opus, --max-rounds 3)
npm run fable -- "<task>" --model opus --judge-model opus --max-rounds 3

# best-of N: parallel attempts in isolated git worktrees, judge picks,
# winner's diff is applied (requires a clean working tree)
npm run fable -- "<task>" --best-of 3

# verify the harness is fully available to an autonomous session
npm run check -- --cwd C:\path\to\harness-installed-project
```

For a cheap-executor / cheap-judge run (the value pick per `bench/results.md`),
pass `--model haiku --judge-model haiku`; the judge catches fabrication by
re-running the code, so it does not need to be the strongest model.

Every run writes artifacts to `<cwd>/.fable/runs/<timestamp>/` — per-round
executor report, diff, and judge verdict, plus a `summary.json`. The path is
printed at the start of the run.

Exit codes: `0` judge passed the work, `1` failed within max rounds (or any cap
stop), `2` usage error.

## Cost & usage caps

Two independent kinds of cap, plus a config file so limits can be standing:

**Robust caps (always available, stable).** Metered from each session's result:

```powershell
npm run fable -- "<task>" --max-cost 2.50   # notional USD (tokens x list price)
npm run fable -- "<task>" --max-tokens 2000000
```

`--max-cost` also feeds the SDK's native `maxBudgetUsd`, which aborts a session
*mid-round* — and, between rounds, a **projected-cost stop** refuses to start a
round whose expected cost (the running per-round average) would exceed the cap.
That is the "how many rounds fit the budget" logic: it stops early rather than
overshoot. Note `--max-cost` is a **notional** figure (tokens times list price);
it does **not** know whether a subscription covered the work or it billed to
extra-usage credits — see below.

**Experimental sub / extra-usage caps (opt-in, may break on SDK updates).**
Only these distinguish plan-covered work from paid overage, using the SDK's
experimental account-usage API. Both are **percentages** — the API reports
usage as unitless numbers, so a percent of your own limit is the only
unambiguous cap (and it adapts to whatever limit you set):

```powershell
# stop before a round if the plan window is >=85% used, OR extra-usage
# credits reach >=50% of the account's monthly extra-usage limit
npm run fable -- "<task>" --experimental --sub-cap-pct 85 --extra-usage-cap-pct 50
```

If the experimental probe is unavailable (API-key session, non-subscriber, or a
future SDK change), these caps silently no-op and the robust caps still govern —
the run never breaks over it.

**Standing limits (persistent until changed).** Drop a `.fable/config.json`
(or `fable.config.json`) in the run's cwd; any CLI flag overrides it per run:

```json
{
  "maxRounds": 3,
  "maxCostUsd": 5.0,
  "maxTokens": 3000000,
  "model": "haiku",
  "judgeModel": "opus",
  "experimental": { "subscriptionCapPct": 85, "extraUsageCapPct": 50 }
}
```

## Design notes

- The judge session is read-only (`Read/Grep/Glob/Bash` allowed,
  `Write/Edit` denied) and is told to *verify rather than trust* — it can run
  the tests itself.
- An unparseable judge verdict counts as RETRY: work never passes by accident.
- `--best-of` runs attempts against detached worktrees of HEAD so they can't
  interfere, then applies only the winning diff.
