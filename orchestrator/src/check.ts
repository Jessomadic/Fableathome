/**
 * fable check — verify the harness is fully available to an autonomous session.
 *
 * Opens a headless session in --cwd and asks it which skills and subagents it
 * actually exposes (via SDK control requests), then checks all 11 Fable skills
 * and 7 agents are registered. This proves the harness is discoverable and
 * usable with zero human input. Exit 0 if everything is present, 1 otherwise.
 *
 *   npm run check -- --cwd C:\path\to\harness-installed-project
 */
import { resolve } from "node:path";
import { parseArgs } from "node:util";
import { listSkillsAndAgents } from "./control.js";

const { values } = parseArgs({ options: { cwd: { type: "string", default: process.cwd() } } });
const cwd = resolve(values.cwd!);

const EXPECTED_SKILLS = [
  "deepthink", "verify-loop", "checkpoint", "council", "swarm", "build",
  "postmortem", "debug", "refactor", "test", "security-review",
];
const EXPECTED_AGENTS = [
  "fable-planner", "fable-critic", "fable-warden", "fable-builder",
  "fable-verifier", "fable-explorer", "fable-historian",
];

console.log(`fable check: probing available skills/agents in ${cwd}\n`);
const res = await listSkillsAndAgents(cwd);
if (!res) {
  console.error("FAILED: could not open a control session (auth, or the SDK control API changed).");
  process.exit(1);
}

const missingSkills = EXPECTED_SKILLS.filter((s) => !res.skills.includes(s));
const missingAgents = EXPECTED_AGENTS.filter((a) => !res.agents.includes(a));

console.log(`skills available (${res.skills.length}): ${res.skills.join(", ")}`);
console.log(`agents available (${res.agents.length}): ${res.agents.join(", ")}\n`);

for (const s of EXPECTED_SKILLS) console.log(`  ${res.skills.includes(s) ? "OK " : "MISSING"}  /${s}`);
for (const a of EXPECTED_AGENTS) console.log(`  ${res.agents.includes(a) ? "OK " : "MISSING"}  ${a}`);

if (missingSkills.length || missingAgents.length) {
  console.error(
    `\nFAILED: missing ${missingSkills.length} skill(s) [${missingSkills.join(", ")}], ` +
      `${missingAgents.length} agent(s) [${missingAgents.join(", ")}].`,
  );
  process.exit(1);
}
console.log(`\nPASS: all ${EXPECTED_SKILLS.length} skills and ${EXPECTED_AGENTS.length} agents are available to an autonomous session.`);
process.exit(0);
