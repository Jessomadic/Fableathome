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

# knobs
npm run fable -- "<task>" --model opus --judge-model opus --max-rounds 3

# best-of N: parallel attempts in isolated git worktrees, judge picks,
# winner's diff is applied (requires a clean working tree)
npm run fable -- "<task>" --best-of 3
```

Exit codes: `0` judge passed the work, `1` failed within max rounds, `2` usage error.

## Design notes

- The judge session is read-only (`Read/Grep/Glob/Bash` allowed,
  `Write/Edit` denied) and is told to *verify rather than trust* — it can run
  the tests itself.
- An unparseable judge verdict counts as RETRY: work never passes by accident.
- `--best-of` runs attempts against detached worktrees of HEAD so they can't
  interfere, then applies only the winning diff.
