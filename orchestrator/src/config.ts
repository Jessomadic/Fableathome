/**
 * Cap configuration: file defaults (persistent) overlaid by per-run CLI flags.
 *
 * Precedence, lowest to highest: built-in default < .fable/config.json (or
 * fable.config.json) in the run's cwd < CLI flag. So a project can pin standing
 * limits that hold "until changed," and any single run can override them.
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";

export interface FableConfig {
  maxRounds?: number;
  maxCostUsd?: number;
  maxTokens?: number;
  model?: string;
  judgeModel?: string;
  /** Opt-in caps read from the SDK's experimental account-usage API. */
  experimental?: {
    /** Stop before a round once any plan rate-limit window is >= this percent. */
    subscriptionCapPct?: number;
    /**
     * Stop before a round once extra-usage (credit) consumption reaches this
     * percent of the account's monthly extra-usage limit. Percent, not dollars:
     * the SDK reports used/limit as raw unitless numbers, so a percentage is the
     * only unambiguous cap and it adapts to whatever limit the account sets.
     */
    extraUsageCapPct?: number;
  };
}

/** Read the first config file present in cwd; {} if none or unreadable. */
export function loadFileConfig(cwd: string): FableConfig {
  for (const rel of [".fable/config.json", "fable.config.json"]) {
    try {
      return JSON.parse(readFileSync(join(cwd, rel), "utf8")) as FableConfig;
    } catch {
      /* absent or unparseable — try the next candidate, then fall back to {} */
    }
  }
  return {};
}

/** Raw CLI values (strings from parseArgs), before precedence is applied. */
export interface CliCaps {
  maxRounds?: string;
  maxCost?: string;
  maxTokens?: string;
  model?: string;
  judgeModel?: string;
  experimental?: boolean;
  subscriptionCapPct?: string;
  extraUsageCapPct?: string;
}

export interface ResolvedCaps {
  maxRounds: number;
  maxCostUsd: number; // Infinity when uncapped
  maxTokens: number; // Infinity when uncapped
  model: string;
  judgeModel: string;
  experimental: boolean;
  subscriptionCapPct: number; // Infinity when uncapped
  extraUsageCapPct: number; // Infinity when uncapped
}

function num(v: string | number | undefined): number | undefined {
  if (v === undefined) return undefined;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : undefined;
}

/** Apply precedence: cli ?? file ?? default. */
export function resolveCaps(file: FableConfig, cli: CliCaps): ResolvedCaps {
  return {
    maxRounds: num(cli.maxRounds) ?? num(file.maxRounds) ?? 3,
    maxCostUsd: num(cli.maxCost) ?? num(file.maxCostUsd) ?? Infinity,
    maxTokens: num(cli.maxTokens) ?? num(file.maxTokens) ?? Infinity,
    model: cli.model ?? file.model ?? "opus",
    judgeModel: cli.judgeModel ?? file.judgeModel ?? "opus",
    experimental: cli.experimental ?? false,
    subscriptionCapPct:
      num(cli.subscriptionCapPct) ?? num(file.experimental?.subscriptionCapPct) ?? Infinity,
    extraUsageCapPct:
      num(cli.extraUsageCapPct) ?? num(file.experimental?.extraUsageCapPct) ?? Infinity,
  };
}
