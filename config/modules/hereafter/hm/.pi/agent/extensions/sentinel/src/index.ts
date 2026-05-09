/**
 * Sentinel Extension — Heuristic-Only Loop Detection
 *
 * Detects agent loops using a heuristic score (0–1) based on:
 * - Thinking block repetition
 * - Consecutive assistant turns
 * - Token volume
 * - Self-questioning patterns
 * - Repeated tool calls
 *
 * Tiers:
 *   ≥ 0.35  →  warning in statusline
 *   ≥ 0.55  →  auto-abort
 *   (strict mode lowers both by ~0.15)
 *
 * Detection runs on `turn_end` (every assistant turn).
 *
 * Commands:
 *   /sentinel          — show status
 *   /sentinel on|off   — enable/disable
 *   /sentinel strict   — lower threshold (more sensitive)
 *   /sentinel normal   — raise threshold (less sensitive)
 *   /sentinel reset    — clear detection state for this session
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
  extractThinkingBlocks,
  countConsecutiveAssistant,
  extractToolCalls,
  calcHeuristicScore,
  sumInputTokens,
  AUTO_ABORT_THRESHOLD,
  STRICT_AUTO_ABORT_THRESHOLD,
} from "./sentinel-core";

// =============================================================================
// Thresholds
// =============================================================================

const WARNING_THRESHOLD = 0.35;
const STRICT_WARNING_THRESHOLD = 0.25;

// =============================================================================
// State Management
// =============================================================================

interface SentinelState {
  enabled: boolean;
  strict: boolean;
  loopDetected: boolean;
  checkCount: number;
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
    });
  }
  return sessionStates.get(key)!;
}

// =============================================================================
// Core Loop Detection Logic
// =============================================================================

function checkForLoop(ctx: ExtensionContext) {
  const state = getState(ctx.sessionManager.getSessionFile());
  if (!state.enabled || state.loopDetected) return;

  const entries = ctx.sessionManager.getEntries();
  const consecutiveAssistant = countConsecutiveAssistant(entries);

  // Skip early turns — not enough data yet
  if (consecutiveAssistant < 3) return;

  const thinkingBlocks = extractThinkingBlocks(entries).slice(-7);
  const toolCalls = extractToolCalls(entries);

  if (thinkingBlocks.length < 2 && consecutiveAssistant < 3) return;

  state.checkCount++;

  const abortThreshold = state.strict ? STRICT_AUTO_ABORT_THRESHOLD : AUTO_ABORT_THRESHOLD;
  const warnThreshold = state.strict ? STRICT_WARNING_THRESHOLD : WARNING_THRESHOLD;

  const breakdown = calcHeuristicScore(thinkingBlocks, consecutiveAssistant, toolCalls, entries);
  const score = breakdown.total;

  // Auto-abort
  if (score >= abortThreshold) {
    state.loopDetected = true;
    ctx.ui.notify(
      `🚨 Sentinel aborted: loop detected (heuristic score: ${score.toFixed(2)}).\n` +
        `Consecutive responses: ${consecutiveAssistant} | ` +
        `Input tokens: ${sumInputTokens(entries).toLocaleString()}\n\n` +
        `Run /sentinel reset to re-enable.`,
      "error",
    );
    ctx.abort();
    return;
  }

  // Warning
  if (score >= warnThreshold) {
    ctx.ui.setStatus(
      "sentinel",
      ctx.ui.theme.fg("warning", `🛡️ ${score.toFixed(2)} — approaching loop`),
    );
    return;
  }

  // Normal — just show the score
  ctx.ui.setStatus(
    "sentinel",
    ctx.ui.theme.fg("dim", `🛡️ ${score.toFixed(2)}`),
  );
}

// =============================================================================
// Extension Entry Point
// =============================================================================

export default function (pi: ExtensionAPI) {
  // Detection: runs on every assistant turn
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
    checkForLoop(ctx);
  });

  pi.on("session_start", async (_event, ctx) => {
    const key = ctx.sessionManager.getSessionFile() ?? "__ephemeral__";
    sessionStates.set(key, {
      enabled: true,
      strict: false,
      loopDetected: false,
      checkCount: 0,
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
            `Enabled:        ${state.enabled ? "✅ Yes" : "❌ No"}\n` +
            `Mode:           ${state.strict ? "🔴 Strict (warn ≥0.25, abort ≥0.40)" : "🟡 Normal (warn ≥0.35, abort ≥0.55)"}\n` +
            `Loop detected:  ${state.loopDetected ? "⛔ Yes (use /sentinel reset)" : "No"}\n` +
            `Checks:         ${state.checkCount}`,
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
        ctx.ui.notify("Sentinel state reset — detection re-enabled for this session.", "success");
        return;
      }

      ctx.ui.notify(
        `Usage: /sentinel [on|off|strict|normal|status|reset]`,
        "info",
      );
    },
  });
}
