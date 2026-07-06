/**
 * Config precedence tests — pure, no API. Run: npm test
 */
import { resolveCaps, type FableConfig, type CliCaps } from "./config.js";

let fails = 0;
function assert(cond: boolean, name: string): void {
  if (cond) console.log(`PASS  ${name}`);
  else {
    console.error(`FAIL  ${name}`);
    fails++;
  }
}

// Defaults when nothing is set.
{
  const c = resolveCaps({}, {});
  assert(c.maxRounds === 3, "default maxRounds is 3");
  assert(c.maxCostUsd === Infinity, "default maxCost is uncapped");
  assert(c.maxTokens === Infinity, "default maxTokens is uncapped");
  assert(c.model === "opus" && c.judgeModel === "opus", "default models are opus");
  assert(c.experimental === false, "experimental off by default");
  assert(c.subscriptionCapPct === Infinity && c.extraUsageCapPct === Infinity, "experimental caps uncapped by default");
}

// File config is used when no CLI flag overrides it (the "persistent" layer).
{
  const file: FableConfig = {
    maxRounds: 5,
    maxCostUsd: 4,
    maxTokens: 1_000_000,
    model: "haiku",
    judgeModel: "sonnet",
    experimental: { subscriptionCapPct: 80, extraUsageCapPct: 50 },
  };
  const c = resolveCaps(file, {});
  assert(c.maxRounds === 5, "file maxRounds applied");
  assert(c.maxCostUsd === 4, "file maxCost applied");
  assert(c.maxTokens === 1_000_000, "file maxTokens applied");
  assert(c.model === "haiku" && c.judgeModel === "sonnet", "file models applied");
  assert(c.subscriptionCapPct === 80 && c.extraUsageCapPct === 50, "file experimental caps applied");
}

// CLI overrides file (per-task override wins).
{
  const file: FableConfig = { maxRounds: 5, maxCostUsd: 4, model: "haiku" };
  const cli: CliCaps = { maxRounds: "2", maxCost: "1.5", model: "opus", experimental: true, subscriptionCapPct: "90" };
  const c = resolveCaps(file, cli);
  assert(c.maxRounds === 2, "CLI maxRounds overrides file");
  assert(c.maxCostUsd === 1.5, "CLI maxCost overrides file");
  assert(c.model === "opus", "CLI model overrides file");
  assert(c.experimental === true, "CLI experimental flag applied");
  assert(c.subscriptionCapPct === 90, "CLI sub-cap overrides file");
}

// Garbage numeric values fall through to the next layer rather than NaN.
{
  const c = resolveCaps({ maxRounds: 7 }, { maxRounds: "not-a-number" });
  assert(c.maxRounds === 7, "non-numeric CLI value falls back to file, not NaN");
}

console.log("");
if (fails === 0) console.log("CONFIG: ALL PASSED");
else {
  console.error(`CONFIG: ${fails} FAILED`);
  process.exit(1);
}
