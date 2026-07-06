# Changelog

All notable changes to Fableathome. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); dates are ISO 8601.

## [0.4.0] — 2026-07-06 — Pre-deadline hardening sprint

### Security
- **Closed danger-detector bypasses.** The PreToolUse safety gate split
  commands only on `;&|`, so a recursive delete hidden in a newline
  (`echo hi⏎rm -rf /`), a command substitution (`echo $(rm -rf /)`), backticks,
  or a subshell slipped through. Commands are now normalized (parens, backticks,
  newlines → separators) before per-segment anchoring.
- **Added irreversible verbs**: `find -delete`, `find -exec rm`, `xargs rm -rf`,
  `shred`, `truncate -s 0`.

### Fixed
- **Over-blocking of legitimate deletes.** `C:\Users\…` (Windows) and `/home/…`
  (Linux) were treated as catastrophic at any depth, blocking deletes of a
  project's own `node_modules`. Now scoped to the profile root plus one segment;
  deeper paths are allowed.
- **Stop-gate blocked only once per session.** A second batch of unverified
  edits was never gated. Replaced the permanent latch with a per-edit-batch
  timestamp: the same batch never re-blocks (no loop), a newer unverified edit
  re-arms the gate.

### Added
- Four skills: `/debug` (reproduce → isolate → bisect → fix → verify),
  `/refactor` (behavior-preserving, prove equivalence), `/test` (red→green
  regression guards), `/security-review` (trust-boundary audit).
- Orchestrator: `--max-cost` budget cap, run-log persistence to
  `.fable/runs/<timestamp>/`, and a defensive best-of winner-parse fallback.
- Project `LICENSE` (MIT), this `CHANGELOG`, and a `windows-latest` CI workflow
  running the PowerShell suite and the orchestrator typecheck.

## [0.3.0] — 2026-07-02 — Register, grounding, and anti-fabrication

### Added
- **PreToolUse safety gate**: blocks catastrophic commands (recursive deletes of
  critical paths, force-push, `reset --hard`, `dd`, fork bombs, pipe-to-shell,
  shutdown) and points at `fable-warden`. Verified live.
- Core principles: "prove claims, do not guess" and "verify against current
  external sources" (proactive web search/fetch for libraries, APIs, versions,
  UI frameworks, and admin consoles), with a UserPromptSubmit reminder.
- "Clarify requirements before starting" discipline + SessionStart injection.
- Committed test suite (`tests/`) and the first A/B bench results.
- Anti-fabrication pass (core §6/§8, verify-loop Step 0, stop-gate wording) and
  the new `06-tangled-trace` bench task; enforcement-layer A/B proving the
  orchestrator judge catches weak-model fabrication by re-running the code.

### Changed
- All model-facing text (core, skills, agents, hooks) rewritten into a neutral
  technical register.
- Danger detector made segment-scoped and command-anchored (fixed false
  positives on quoted strings / unrelated subcommands and several false
  negatives).

## [0.2.0] — 2026-07-02 — Phase 2 "Every Last Drop"

### Added
- **Model-family routing**: Opus (judgment), Sonnet (workhorse), Haiku (swarm),
  with a dispatch doctrine in the core and seven subagents (planner, critic,
  warden, builder, verifier, explorer, historian).
- **Team skills**: `/swarm`, `/build`, `/postmortem` (+ `.fable/LESSONS.md`).
- **Hooks**: SessionStart memory autoload, Deep-tier prompt hints, the
  edit/verify stop-gate, PreCompact preservation — installed by merging
  `settings.json` safely.
- **Eval bench**: trapped tasks with rubrics and an A/B protocol.
- **Orchestrator** (`orchestrator/`): TypeScript on the Claude Agent SDK —
  run/judge/retry with an evidence-demanding judge, plus `--best-of N` in
  isolated git worktrees.

## [0.1.0] — 2026-07-01 — Phase 1 harness

### Added
- Behavioral core (`core/fable-core.md`) imported into `CLAUDE.md`.
- Skills: `/deepthink`, `/verify-loop`, `/checkpoint`, `/council`.
- Read-only subagents and a verified installer with global/project scopes and
  clean uninstall.
