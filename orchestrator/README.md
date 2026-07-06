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

# budget cap: stop before starting a round once spend reaches the limit
npm run fable -- "<task>" --max-cost 2.50

# best-of N: parallel attempts in isolated git worktrees, judge picks,
# winner's diff is applied (requires a clean working tree)
npm run fable -- "<task>" --best-of 3
```

For a cheap-executor / cheap-judge run (the value pick per `bench/results.md`),
pass `--model haiku --judge-model haiku`; the judge catches fabrication by
re-running the code, so it does not need to be the strongest model.

Every run writes artifacts to `<cwd>/.fable/runs/<timestamp>/` — per-round
executor report, diff, and judge verdict, plus a `summary.json`. The path is
printed at the start of the run.

Exit codes: `0` judge passed the work, `1` failed within max rounds (or budget
stop), `2` usage error.

## Design notes

- The judge session is read-only (`Read/Grep/Glob/Bash` allowed,
  `Write/Edit` denied) and is told to *verify rather than trust* — it can run
  the tests itself.
- An unparseable judge verdict counts as RETRY: work never passes by accident.
- `--best-of` runs attempts against detached worktrees of HEAD so they can't
  interfere, then applies only the winning diff.
