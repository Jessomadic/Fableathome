/**
 * fable run — programmatic control flow that prompts cannot enforce.
 *
 * Loop: executor session (does the work) → judge session (independent, must
 * see verification EVIDENCE or it blocks) → retry with the judge's feedback,
 * up to --max-rounds. With --best-of N, N parallel attempts run in isolated
 * git worktrees and the judge picks the winner, whose diff is then applied.
 *
 * Usage:
 *   npm run fable -- "<task>" [--cwd <path>] [--model opus] [--judge-model opus]
 *                            [--max-rounds 3] [--best-of N]
 */
import { query } from "@anthropic-ai/claude-agent-sdk";
import { execFileSync } from "node:child_process";
import { parseArgs } from "node:util";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

// ---------- CLI ----------

const { values: flags, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    cwd: { type: "string", default: process.cwd() },
    model: { type: "string", default: "opus" },
    "judge-model": { type: "string", default: "opus" },
    "max-rounds": { type: "string", default: "3" },
    "best-of": { type: "string" },
  },
});

const task = positionals.join(" ").trim();
if (!task) {
  console.error('usage: fable run "<task>" [--cwd path] [--best-of N] [--max-rounds 3]');
  process.exit(2);
}
const cwd = resolve(flags.cwd!);
const maxRounds = parseInt(flags["max-rounds"]!, 10);
const bestOf = flags["best-of"] ? parseInt(flags["best-of"]!, 10) : 0;

// ---------- git helpers ----------

function git(args: string[], dir: string = cwd): string {
  return execFileSync("git", args, { cwd: dir, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
}

/** Diff of everything since HEAD, including new files (via intent-to-add). */
function captureDiff(dir: string = cwd): string {
  try {
    git(["add", "-N", "."], dir);
    return git(["diff", "HEAD"], dir);
  } catch {
    return "(no git repository or no diff available)";
  }
}

// ---------- sessions ----------

const EXECUTOR_CONTRACT = `

Completion contract (enforced by an independent judge who reviews your work):
- Your final message MUST include verification evidence: the exact commands
  you ran to exercise the changed behavior end-to-end, and their observed
  output. Claims without evidence are rejected.
- Anything you could not verify must be explicitly labeled UNVERIFIED with
  the reason. Honest UNVERIFIED is acceptable; unsupported claims are not.`;

async function runSession(
  prompt: string,
  opts: { model: string; cwd: string; readOnly?: boolean },
): Promise<{ report: string; costUsd: number; turns: number }> {
  let report = "";
  let costUsd = 0;
  let turns = 0;
  for await (const message of query({
    prompt,
    options: {
      model: opts.model,
      cwd: opts.cwd,
      permissionMode: opts.readOnly ? "default" : "acceptEdits",
      // Headless sessions have nobody to click "approve": the executor needs
      // Bash auto-approved or it can never run its own verification, and the
      // judge needs read-only + Bash to verify independently.
      ...(opts.readOnly
        ? {
            allowedTools: ["Read", "Grep", "Glob", "Bash"],
            disallowedTools: ["Write", "Edit", "NotebookEdit"],
          }
        : {
            allowedTools: ["Read", "Grep", "Glob", "Edit", "Write", "NotebookEdit", "Bash"],
          }),
    },
  })) {
    if (message.type === "result") {
      report = typeof message.result === "string" ? message.result : "";
      costUsd = message.total_cost_usd ?? 0;
      turns = message.num_turns ?? 0;
      if (message.is_error) {
        throw new Error(`session failed: ${report || "(no result text)"}`);
      }
    }
  }
  return { report, costUsd, turns };
}

// ---------- judge ----------

interface Verdict {
  verdict: "PASS" | "RETRY";
  feedback: string;
}

function parseVerdict(text: string): Verdict {
  const fenced = text.match(/```json\s*([\s\S]*?)```/);
  const raw = fenced ? fenced[1] : text.slice(text.lastIndexOf("{"));
  try {
    const v = JSON.parse(raw);
    if (v.verdict === "PASS" || v.verdict === "RETRY") {
      return { verdict: v.verdict, feedback: String(v.feedback ?? "") };
    }
  } catch {
    /* fall through */
  }
  // A judge that can't produce a verdict never passes work by accident.
  return { verdict: "RETRY", feedback: `Judge output was unparseable; re-verify and report clearly. Raw: ${text.slice(0, 400)}` };
}

async function judge(taskText: string, report: string, diff: string): Promise<{ v: Verdict; costUsd: number }> {
  const prompt = `You are the completion judge for an autonomous coding run. Decide whether the work is DONE — done means DEMONSTRATED, not merely written.

TASK GIVEN TO THE EXECUTOR:
${taskText}

EXECUTOR'S FINAL REPORT:
${report}

DIFF OF ALL CHANGES (against HEAD):
${diff.length > 60000 ? diff.slice(0, 60000) + "\n...(diff truncated)" : diff}

Judge protocol:
1. Does the diff actually address the task?
2. Does the report contain verification EVIDENCE — commands run and observed output — for every claim? "Should work" or evidence-free claims are an automatic RETRY. Explicit, well-reasoned UNVERIFIED labels for genuinely unverifiable items are acceptable.
3. You may run read-only commands yourself (tests, scripts) to independently verify; prefer verifying over trusting.
4. Be strict. Your RETRY feedback must be specific and actionable.

Respond with ONLY a fenced json block:
\`\`\`json
{"verdict": "PASS", "feedback": "..."}
\`\`\`
or {"verdict": "RETRY", ...} with what is missing and how to fix it.`;

  const { report: out, costUsd } = await runSession(prompt, {
    model: flags["judge-model"]!,
    cwd,
    readOnly: true,
  });
  return { v: parseVerdict(out), costUsd };
}

// ---------- run/judge/retry loop ----------

async function runLoop(): Promise<void> {
  let feedback = "";
  let totalCost = 0;

  for (let round = 1; round <= maxRounds; round++) {
    console.log(`\n=== round ${round}/${maxRounds}: executor (${flags.model}) ===`);
    const prompt =
      task +
      EXECUTOR_CONTRACT +
      (feedback
        ? `\n\nYOUR PREVIOUS ATTEMPT WAS REJECTED BY THE JUDGE. Feedback:\n${feedback}\nAddress it, verify end-to-end, and include the evidence.`
        : "");

    const exec = await runSession(prompt, { model: flags.model!, cwd });
    totalCost += exec.costUsd;
    console.log(`executor done: ${exec.turns} turns, $${exec.costUsd.toFixed(4)}`);

    const diff = captureDiff();
    console.log(`\n=== round ${round}: judge (${flags["judge-model"]}) ===`);
    const { v, costUsd } = await judge(task, exec.report, diff);
    totalCost += costUsd;
    console.log(`judge verdict: ${v.verdict}${v.feedback ? ` — ${v.feedback}` : ""}`);

    if (v.verdict === "PASS") {
      console.log(`\nDONE (verified) in ${round} round(s). Total cost: $${totalCost.toFixed(4)}`);
      console.log(`\nExecutor's final report:\n${exec.report}`);
      return;
    }
    feedback = v.feedback;
  }

  console.error(`\nFAILED: judge did not pass the work within ${maxRounds} rounds. Last feedback: ${feedback}`);
  console.error(`Total cost: $${totalCost.toFixed(4)}`);
  process.exit(1);
}

// ---------- best-of N ----------

async function runBestOf(n: number): Promise<void> {
  const dirty = git(["status", "--porcelain"]).trim();
  if (dirty) {
    console.error("--best-of requires a clean working tree (attempts branch from HEAD).");
    process.exit(2);
  }

  const base = mkdtempSync(join(tmpdir(), "fable-bestof-"));
  const attempts: { dir: string; report: string; diff: string }[] = [];
  let totalCost = 0;

  try {
    console.log(`\n=== best-of ${n}: dispatching parallel attempts (${flags.model}) ===`);
    const dirs = Array.from({ length: n }, (_, i) => join(base, `attempt-${i + 1}`));
    for (const d of dirs) git(["worktree", "add", "--detach", d, "HEAD"]);

    const results = await Promise.all(
      dirs.map((d) => runSession(task + EXECUTOR_CONTRACT, { model: flags.model!, cwd: d })),
    );
    results.forEach((r, i) => {
      totalCost += r.costUsd;
      attempts.push({ dir: dirs[i], report: r.report, diff: captureDiff(dirs[i]) });
      console.log(`attempt ${i + 1}: ${r.turns} turns, $${r.costUsd.toFixed(4)}`);
    });

    console.log(`\n=== best-of ${n}: judge picks the winner ===`);
    const judgePrompt = `You are judging ${n} independent attempts at the same task. Pick the best one — correctness and verification evidence outweigh style.

TASK:
${task}

${attempts
  .map(
    (a, i) => `--- ATTEMPT ${i + 1} REPORT ---\n${a.report}\n--- ATTEMPT ${i + 1} DIFF ---\n${a.diff.slice(0, 30000)}`,
  )
  .join("\n\n")}

Respond with ONLY a fenced json block: \`\`\`json
{"winner": <1-based attempt number>, "reason": "..."}
\`\`\``;
    const { report: out, costUsd } = await runSession(judgePrompt, {
      model: flags["judge-model"]!,
      cwd,
      readOnly: true,
    });
    totalCost += costUsd;

    const fenced = out.match(/```json\s*([\s\S]*?)```/);
    const pick = JSON.parse(fenced ? fenced[1] : out.slice(out.lastIndexOf("{")));
    const winner = attempts[pick.winner - 1];
    if (!winner) throw new Error(`judge picked invalid winner: ${JSON.stringify(pick)}`);
    console.log(`winner: attempt ${pick.winner} — ${pick.reason}`);

    if (winner.diff.trim() && !winner.diff.startsWith("(no git")) {
      execFileSync("git", ["apply", "--whitespace=nowarn"], { cwd, input: winner.diff });
      console.log("winner's diff applied to the working tree.");
    } else {
      console.log("winner made no file changes; nothing to apply.");
    }
    console.log(`\nTotal cost: $${totalCost.toFixed(4)}`);
    console.log(`\nWinning report:\n${winner.report}`);
  } finally {
    for (const a of attempts) {
      try {
        git(["worktree", "remove", "--force", a.dir]);
      } catch {
        /* best effort */
      }
    }
    rmSync(base, { recursive: true, force: true });
  }
}

// ---------- entry ----------

(bestOf > 1 ? runBestOf(bestOf) : runLoop()).catch((err) => {
  console.error(`fable run failed: ${err.message ?? err}`);
  process.exit(1);
});
