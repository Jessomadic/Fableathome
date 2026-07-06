/**
 * Streaming-mode control-request helpers.
 *
 * Control requests (supportedCommands, supportedAgents, the experimental usage
 * probe) are only available when a session is started in streaming-input mode.
 * `withControlSession` opens such a session, yields NO user turn (so no model
 * inference runs — it costs ~nothing), lets the caller issue control requests,
 * then closes it. Every call is best-effort: any failure returns null so a
 * caller can degrade gracefully rather than crash.
 */
import {
  query,
  type Query,
  type SDKUserMessage,
  type SDKControlGetUsageResponse,
} from "@anthropic-ai/claude-agent-sdk";

async function withControlSession<T>(cwd: string, fn: (q: Query) => Promise<T>): Promise<T | null> {
  let release!: () => void;
  const gate = new Promise<void>((r) => (release = r));
  // Input that never yields a turn and stays open until we release it, so the
  // session initializes and accepts control requests but does no inference.
  async function* input(): AsyncGenerator<SDKUserMessage> {
    await gate;
  }
  const q = query({
    prompt: input(),
    options: { cwd, permissionMode: "default", allowedTools: [] },
  });
  try {
    return await fn(q);
  } catch {
    return null;
  } finally {
    release();
    try {
      await q.interrupt();
    } catch {
      /* session may already be closing */
    }
    try {
      for await (const _ of q) {
        /* drain to completion so the transport shuts down cleanly */
      }
    } catch {
      /* ignore */
    }
  }
}

/** The skills and subagents a session in `cwd` actually exposes. null on failure. */
export async function listSkillsAndAgents(
  cwd: string,
): Promise<{ skills: string[]; agents: string[] } | null> {
  return withControlSession(cwd, async (q) => {
    const [cmds, agents] = await Promise.all([q.supportedCommands(), q.supportedAgents()]);
    return { skills: cmds.map((c) => c.name), agents: agents.map((a) => a.name) };
  });
}

export interface AccountUsage {
  subscriptionType: string | null;
  /** Highest utilization across available plan windows (5h / 7d / per-model), 0-100. */
  planUtilizationPct: number | null;
  extraUsage: {
    isEnabled: boolean;
    usedCredits: number | null;
    monthlyLimit: number | null;
    utilizationPct: number | null;
  } | null;
}

/**
 * Live account usage from the SDK's EXPERIMENTAL usage API — the only source
 * that distinguishes plan-covered work from extra-usage credits. Returns null
 * for API-key sessions, non-subscribers, or if the (unstable) method is absent
 * or changes shape; callers must treat null as "no experimental gating."
 */
export async function probeAccountUsage(cwd: string): Promise<AccountUsage | null> {
  return withControlSession(cwd, async (q) => {
    const u = (await q.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET()) as SDKControlGetUsageResponse;
    const rl = u.rate_limits;
    const windows = [
      rl?.five_hour?.utilization,
      rl?.seven_day?.utilization,
      rl?.seven_day_opus?.utilization,
      rl?.seven_day_sonnet?.utilization,
      ...(rl?.model_scoped?.map((m) => m.utilization) ?? []),
    ].filter((x): x is number => typeof x === "number");
    const ex = rl?.extra_usage ?? null;
    return {
      subscriptionType: u.subscription_type,
      planUtilizationPct: windows.length ? Math.max(...windows) : null,
      extraUsage: ex
        ? {
            isEnabled: ex.is_enabled,
            usedCredits: ex.used_credits ?? null,
            monthlyLimit: ex.monthly_limit ?? null,
            utilizationPct: ex.utilization ?? null,
          }
        : null,
    };
  });
}
