/**
 * Sentinel Extension
 *
 * Detects agent loops by analyzing thinking patterns, tool call behavior,
 * and turn counts. Uses a three-tier approach:
 *
 * 1. Heuristic analysis (free, instant) — flags suspicious sessions
 * 2. Qwen3.5-flash filter (cheap) — quick scan, prone to false positives
 * 3. MiniMax M2.7 judge (more expensive) — final call before aborting
 *
 * Detection runs on `turn_end` (every assistant turn), so it catches
 * mid-run loops where the agent keeps calling tools in a cycle.
 * `ctx.abort()` during turn_end stops the NEXT API call immediately.
 *
 * Commands:
 *   /sentinel          — show status
 *   /sentinel on|off   — enable/disable
 *   /sentinel strict   — lower threshold (more sensitive)
 *   /sentinel relaxed  — raise threshold (less sensitive)
 *   /sentinel reset    — clear detection state for this session
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
  extractThinkingBlocks,
  countConsecutiveAssistant,
  extractToolCalls,
  calcHeuristicScore,
  sumInputTokens,
  SENTINEL_TRIGGER,
  AUTO_ABORT_THRESHOLD,
  STRICT_SENTINEL_TRIGGER,
  STRICT_AUTO_ABORT_THRESHOLD,
} from "./sentinel-core";

// =============================================================================
// Constants
// =============================================================================

const KILO_API_BASE = process.env.KILO_API_URL || "https://api.kilo.ai";
const KILO_GATEWAY_BASE = `${KILO_API_BASE}/api/gateway`;

// Tier 2 — cheap filter, fast but prone to false positives
const SENTINEL_MODEL = "qwen/qwen3.5-flash-02-23";
// Tier 3 — final judge, slower but more reliable
const JUDGE_MODEL = "kilo/minimax/minimax-m2.7";

const MAX_THINKING_HISTORY = 7;
const SENTINEL_TIMEOUT_MS = 8000;
const JUDGE_TIMEOUT_MS = 12000;

// Skip checks for early turns (need some data first)
const MIN_TURNS_BEFORE_CHECK = 3;

// =============================================================================
// State Management
// =============================================================================

interface SentinelState {
  enabled: boolean;
  strict: boolean;
  loopDetected: boolean;
  checkCount: number;
  sentinelCalls: number;
  judgeCalls: number;
  judgeDenials: number;
  /** Heuristic penalty added to the sentinel trigger after each judge denial.
   *  Increases by 0.1 per denial so the score must grow before re-escalating. */
  heuristicPenalty: number;
}

const sessionStates = new Map<string, SentinelState>();

function getState(sessionFile: string | undefined): SentinelState {
  const key = sessionFile ?? "__ephemeral__";
  if (!sessionStates.has(key)) {
    sessionStates.set(key, {
      enabled: true,
      strict: false,
      loopDetected: false,
      checkCount: 0,
      sentinelCalls: 0,
      judgeCalls: 0,
      judgeDenials: 0,
      heuristicPenalty: 0,
    });
  }
  return sessionStates.get(key)!;
}

// =============================================================================
// LLM Sentinel
// =============================================================================

const SENTINEL_SYSTEM_PROMPT = `You are a loop detector for an AI coding assistant.

Analyze the agent's recent thinking process and determine if it's stuck in a loop.

Signs of looping:
- Re-reading the same documentation or files repeatedly
- Asking itself the same questions without reaching conclusions
- Re-evaluating approaches without committing to one
- Starting new analysis instead of continuing previous work
- Circular reasoning or second-guessing without progress
- "Let me think about..." or "Let me look at..." patterns repeating

Respond with a JSON object containing:
- "looping": boolean — true if the agent appears stuck in a loop
- "confidence": number between 0 and 1 — how sure you are
- "reason": string — brief explanation of what you observed

Output ONLY the JSON. No markdown, no code fences, no explanation.`;

const JUDGE_SYSTEM_PROMPT = `You are an appellate judge for an AI loop-detection system.

A cheaper model flagged the following thinking blocks as a potential loop.
Your job is to make the final call: is this genuinely a loop, or just
productive deliberation?

Signs of a real loop:
- The agent is literally repeating the same steps with no progress
- It reads the same file or runs the same command multiple times without learning anything new
- It asks itself the same question over and over
- Each thinking block is substantively identical to the previous one

Signs this is NOT a loop (let it continue):
- The agent is exploring different approaches and making progress
- It's reading new files to gather new information
- Self-questioning that leads to new conclusions or decisions
- Normal deliberation before committing to a plan
- The agent learns from tool results and changes its approach

Respond with a JSON object containing:
- "looping": boolean — true only if this is clearly a loop
- "confidence": number between 0 and 1 — how sure you are
- "reason": string — brief explanation of your ruling

Output ONLY the JSON. No markdown, no code fences, no explanation.`;

type LoopVerdict = { looping: boolean; confidence: number; reason: string };

interface ModelCallConfig {
  label: string;
  model: string;
  systemPrompt: string;
  userContent: string;
  maxTokens: number;
  timeoutMs: number;
}

/** Generic LLM call — used by both the filter (Qwen) and judge (MiniMax). */
async function callModel(cfg: ModelCallConfig, token: string): Promise<LoopVerdict | null> {
  const tStart = Date.now();
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), cfg.timeoutMs);

    const tFetch = Date.now();
    const response = await fetch(`${KILO_GATEWAY_BASE}/v1/chat/completions`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: cfg.model,
        messages: [
          { role: "system", content: cfg.systemPrompt },
          { role: "user", content: cfg.userContent },
        ],
        max_tokens: cfg.maxTokens,
        temperature: 0,
        response_format: { type: "json_object" },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);
    const tDone = Date.now();
    console.log(`[sentinel] ${cfg.label}: fetch=${tFetch - tStart}ms total=${tDone - tStart}ms status=${response.status}`);

    if (!response.ok) return null;

    const data = (await response.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const text = data.choices?.[0]?.message?.content ?? "";

    const result = extractJsonObject(text);
    if (!result) return null;

    return JSON.parse(result) as LoopVerdict;
  } catch (err) {
    const tDone = Date.now();
    console.log(`[sentinel] ${cfg.label}: ERROR after ${tDone - tStart}ms: ${err}`);
    return null;
  }
}

function formatThinkingBlocks(blocks: string[]): string {
  return blocks.map((b, i) => `--- Thinking block ${i + 1} ---\n${b}`).join("\n\n");
}

function callSentinelModel(
  token: string,
  thinkingBlocks: string[],
): Promise<LoopVerdict | null> {
  return callModel(
    {
      label: "filter",
      model: SENTINEL_MODEL,
      systemPrompt: SENTINEL_SYSTEM_PROMPT,
      userContent: formatThinkingBlocks(thinkingBlocks),
      maxTokens: 120,
      timeoutMs: SENTINEL_TIMEOUT_MS,
    },
    token,
  );
}

function callJudgeModel(
  token: string,
  thinkingBlocks: string[],
  sentinelResult: LoopVerdict,
): Promise<LoopVerdict | null> {
  return callModel(
    {
      label: "judge",
      model: JUDGE_MODEL,
      systemPrompt: JUDGE_SYSTEM_PROMPT,
      userContent:
        `The filter model flagged this as a loop. Its analysis:\n\n` +
        `${sentinelResult.reason}\n\n` +
        `--- Agent thinking blocks ---\n` +
        formatThinkingBlocks(thinkingBlocks),
      maxTokens: 150,
      timeoutMs: JUDGE_TIMEOUT_MS,
    },
    token,
  );
}

/**
 * Extract the first top-level JSON object from a string that may contain
 * markdown code fences, prose, or malformed output.
 */
function extractJsonObject(text: string): string | null {
  const braceResult = extractBraceDelimited(text);
  if (braceResult !== null) return braceResult;

  const stripped = text
    .replace(/^```(?:json)?\s*/m, "")
    .replace(/\s*```$/m, "");
  const braceResult2 = extractBraceDelimited(stripped);
  if (braceResult2 !== null) return braceResult2;

  return extractFieldsViaRegex(text);
}

/** Find the first `{` and count braces (respecting strings) to its `}` */
function extractBraceDelimited(text: string): string | null {
  const start = text.indexOf("{");
  if (start === -1) return null;

  let depth = 0;
  let inString = false;
  let escape = false;

  for (let i = start; i < text.length; i++) {
    const ch = text[i];

    if (escape) {
      escape = false;
      continue;
    }

    if (ch === "\\" && inString) {
      escape = true;
      continue;
    }

    if (ch === '"' && !escape) {
      inString = !inString;
      continue;
    }

    if (!inString) {
      if (ch === "{") depth++;
      else if (ch === "}") depth--;

      if (depth === 0) {
        return text.slice(start, i + 1);
      }
    }
  }
  return null;
}

/** Last-ditch: extract individual fields via regex */
function extractFieldsViaRegex(text: string): string | null {
  const loopingMatch = text.match(/"looping"\s*:\s*(true|false)/);
  const confidenceMatch = text.match(/"confidence"\s*:\s*([\d.]+)/);
  const reasonMatch = text.match(/"reason"\s*:\s*"((?:[^"\\]|\\.)*)"/);

  if (!loopingMatch && !confidenceMatch && !reasonMatch) return null;

  const parts = [];
  if (loopingMatch) parts.push(`"looping": ${loopingMatch[1]}`);
  if (confidenceMatch) parts.push(`"confidence": ${confidenceMatch[1]}`);
  if (reasonMatch) parts.push(`"reason": "${reasonMatch[1]}"`);

  return `{${parts.join(", ")}}`;
}

// =============================================================================
// Core Loop Detection Logic
// =============================================================================

async function checkForLoop(ctx: ExtensionContext) {
  const state = getState(ctx.sessionManager.getSessionFile());
  if (!state.enabled || state.loopDetected) return;

  const entries = ctx.sessionManager.getEntries();
  const consecutiveAssistant = countConsecutiveAssistant(entries);
  const thinkingBlocks = extractThinkingBlocks(entries).slice(-MAX_THINKING_HISTORY);
  const toolCalls = extractToolCalls(entries);

  const t0 = Date.now();
  ctx.ui.setStatus(
    "sentinel",
    ctx.ui.theme.fg("dim", `🛡️ check start turn=${consecutiveAssistant} tb=${thinkingBlocks.length} tc=${toolCalls.length}`),
  );

  // Skip early turns — not enough data yet
  if (consecutiveAssistant < MIN_TURNS_BEFORE_CHECK) return;
  if (thinkingBlocks.length < 2 && consecutiveAssistant < MIN_TURNS_BEFORE_CHECK) return;

  state.checkCount++;

  const abortThreshold = state.strict ? STRICT_AUTO_ABORT_THRESHOLD : AUTO_ABORT_THRESHOLD;
  const sentinelThreshold = state.strict ? STRICT_SENTINEL_TRIGGER : SENTINEL_TRIGGER;
  const breakdown = calcHeuristicScore(thinkingBlocks, consecutiveAssistant, toolCalls, entries);

  const t1 = Date.now();
  ctx.ui.setStatus(
    "sentinel",
    ctx.ui.theme.fg("dim", `🛡️ heuristic=${breakdown.total.toFixed(2)} (${t1 - t0}ms)`),
  );

  // Auto-abort: heuristic is obvious, no LLM needed
  if (breakdown.total >= abortThreshold) {
    state.loopDetected = true;
    ctx.ui.notify(
      `🚨 Sentinel aborted: loop detected (heuristic score: ${breakdown.total.toFixed(2)}).\n` +
        `Consecutive responses: ${consecutiveAssistant} | ` +
        `Input tokens: ${sumInputTokens(entries).toLocaleString()}\n\n` +
        `Run /sentinel reset to re-enable.`,
      "error",
    );
    ctx.abort();
    return;
  }

  // Below sentinel trigger (plus any penalty from prior judge denials) — nothing to do
  const effectiveThreshold = sentinelThreshold + state.heuristicPenalty;
  if (breakdown.total < effectiveThreshold) {
    const tEnd = Date.now();
    ctx.ui.setStatus(
      "sentinel",
      ctx.ui.theme.fg("dim", `🛡️ ${breakdown.total.toFixed(2)} < ${effectiveThreshold.toFixed(2)} (${tEnd - t0}ms)`),
    );
    return;
  }

  // Between sentinel and abort threshold — ask the cheap filter LLM
  const cred = ctx.modelRegistry.authStorage.get("kilo");
  if (cred?.type !== "oauth") return;

  const tPreSentinel = Date.now();
  ctx.ui.setStatus(
    "sentinel",
    ctx.ui.theme.fg("yellow", `🛡️ calling filter… (${tPreSentinel - t0}ms)`),
  );

  state.sentinelCalls++;
  const sentinelResult = await callSentinelModel(
    cred.access,
    thinkingBlocks.slice(-5),
  );
  const tPostSentinel = Date.now();

  // Filter model says no loop — we're clear
  if (!sentinelResult?.looping || sentinelResult.confidence < 0.55) {
    ctx.ui.setStatus(
      "sentinel",
      ctx.ui.theme.fg("dim", `🛡️ ${breakdown.total.toFixed(2)} filter=${tPostSentinel - tPreSentinel}ms`),
    );
    return;
  }

  // Filter model says yes — escalate to the judge for a final ruling
  const tPreJudge = Date.now();
  ctx.ui.setStatus(
    "sentinel",
    ctx.ui.theme.fg("red", `🛡️ calling judge… (${tPreJudge - t0}ms)`),
  );

  state.judgeCalls++;
  const judgeResult = await callJudgeModel(
    cred.access,
    thinkingBlocks.slice(-5),
    sentinelResult,
  );
  const tPostJudge = Date.now();

  if (judgeResult?.looping && judgeResult.confidence >= 0.55) {
    state.loopDetected = true;
    ctx.ui.notify(
      `🚨 Sentinel confirmed a loop!\n\n` +
        `Filter (Qwen): ${sentinelResult.reason}\n` +
        `Judge (M2.7): ${judgeResult.reason}\n` +
        `Heuristic score: ${breakdown.total.toFixed(2)} | ` +
        `Judge confidence: ${(judgeResult.confidence * 100).toFixed(0)}%\n` +
        `Judge took: ${tPostJudge - tPreJudge}ms\n` +
        `Sentinel calls: ${state.sentinelCalls} | Judge calls: ${state.judgeCalls}\n\n` +
        `Aborting to prevent runaway costs. Run /sentinel reset to re-enable.`,
      "error",
    );
    ctx.abort();
    return;
  }

  // Judge said "not a loop" — raise the heuristic bar before re-escalating
  state.judgeDenials++;
  state.heuristicPenalty += 0.1;
  ctx.ui.setStatus(
    "sentinel",
    ctx.ui.theme.fg("dim", `🛡️ ${breakdown.total.toFixed(2)} judge=${tPostJudge - tPreJudge}ms cleared, penalty +${state.heuristicPenalty.toFixed(1)}`),
  );
}

// =============================================================================
// Extension Entry Point
// =============================================================================

export default function (pi: ExtensionAPI) {
  // Primary detection: runs on EVERY turn (including mid-loop tool call cycles).
  // ctx.abort() works here because the agent loop's AbortController is active.
  pi.on("turn_end", async (_event, ctx) => {
    if (!ctx.hasUI) return;
    const state = getState(ctx.sessionManager.getSessionFile());
    if (!state.enabled) {
      ctx.ui.setStatus("sentinel", undefined);
      return;
    }
    if (state.loopDetected) {
      ctx.ui.setStatus("sentinel", ctx.ui.theme.fg("error", `🛡️ loop detected`));
      return;
    }

    await checkForLoop(ctx);
  });

  // Lifecycle
  pi.on("session_start", async (_event, ctx) => {
    const key = ctx.sessionManager.getSessionFile() ?? "__ephemeral__";
    sessionStates.set(key, {
      enabled: true,
      strict: false,
      loopDetected: false,
      checkCount: 0,
      sentinelCalls: 0,
      judgeCalls: 0,
      judgeDenials: 0,
      heuristicPenalty: 0,
    });
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    const key = ctx.sessionManager.getSessionFile() ?? "__ephemeral__";
    sessionStates.delete(key);
  });

  // === /sentinel command ===
  pi.registerCommand("sentinel", {
    description: "Manage the loop detection sentinel",
    handler: async (args, ctx) => {
      const state = getState(ctx.sessionManager.getSessionFile());
      const input = args?.trim().toLowerCase() ?? "";

      if (!input || input === "status") {
        ctx.ui.notify(
          `🛡️ Sentinel Status\n` +
            `──────────────────\n` +
            `Enabled:   ${state.enabled ? "✅ Yes" : "❌ No"}\n` +
            `Mode:      ${state.strict ? "🔴 Strict (sentinel ≥0.10, abort ≥0.40)" : "🟡 Normal (sentinel ≥0.15, abort ≥0.55)"}\n` +
            `Loop detected: ${state.loopDetected ? "⛔ Yes (use /sentinel reset)" : "No"}\n` +
            `Checks:    ${state.checkCount}\n` +
            `Filter calls: ${state.sentinelCalls} | Judge calls: ${state.judgeCalls}\n` +
            `Judge denials: ${state.judgeDenials} | Heuristic penalty: +${state.heuristicPenalty.toFixed(1)}`,
          "info",
        );
        return;
      }

      if (input === "on" || input === "enable") {
        state.enabled = true;
        state.loopDetected = false;
        ctx.ui.notify("✅ Sentinel enabled — loop detection is active.", "success");
        return;
      }

      if (input === "off" || input === "disable") {
        state.enabled = false;
        ctx.ui.setStatus("sentinel", undefined);
        ctx.ui.notify("Sentinel disabled.", "info");
        return;
      }

      if (input === "strict") {
        state.strict = true;
        ctx.ui.notify(
          "🔴 Sentinel set to strict mode — more sensitive to potential loops.",
          "success",
        );
        return;
      }

      if (input === "relaxed" || input === "normal") {
        state.strict = false;
        ctx.ui.notify("🟡 Sentinel set to normal mode.", "success");
        return;
      }

      if (input === "reset") {
        state.loopDetected = false;
        state.checkCount = 0;
        state.sentinelCalls = 0;
        state.judgeCalls = 0;
        state.judgeDenials = 0;
        state.heuristicPenalty = 0;
        ctx.ui.notify("Sentinel state reset — detection re-enabled for this session.", "success");
        return;
      }

      ctx.ui.notify(
        `Usage: /sentinel [on|off|strict|relaxed|status|reset]`,
        "info",
      );
    },
  });
}
