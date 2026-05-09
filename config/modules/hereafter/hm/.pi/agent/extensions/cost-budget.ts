/**
 * Cost Budget Extension
 *
 * Prevents runaway sessions by aborting the agent when cumulative session cost
 * exceeds a configurable per-session budget.
 *
 * Usage:
 *   /budget        — show current budget and cost
 *   /budget 5      — set limit to $5
 *   /budget off    — disable
 *
 * Default: $1 per session.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// =============================================================================
// State
// =============================================================================

interface SessionBudget {
  limit: number;
  warned: boolean;
  aborted: boolean;
}

const sessionBudgets = new Map<string, SessionBudget>();
const DEFAULT_BUDGET = 1.0; // $1 per session

function getBudget(sessionFile: string | undefined): SessionBudget {
  const key = sessionFile ?? "__ephemeral__";
  if (!sessionBudgets.has(key)) {
    sessionBudgets.set(key, { limit: DEFAULT_BUDGET, warned: false, aborted: false });
  }
  return sessionBudgets.get(key)!;
}

function calcSessionCost(ctx: { sessionManager: { getEntries: () => Array<{ type: string; message?: { role: string; usage?: { cost?: { total: number } } } }> } }): number {
  let total = 0;
  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type === "message" && entry.message?.role === "assistant") {
      total += entry.message.usage?.cost?.total ?? 0;
    }
  }
  return total;
}

// Exposed so other extensions (e.g. kilo footer) can read it
export function getBudgetForFooter(sessionFile: string | undefined) {
  return getBudget(sessionFile);
}

export function budgetStatusStr(cost: number, limit: number): string {
  const pct = Math.min((cost / limit) * 100, 100);
  return `$${cost.toFixed(2)}/$${limit.toFixed(0)} (${pct.toFixed(0)}%)`;
}

// =============================================================================
// Extension
// =============================================================================

export default function (pi: ExtensionAPI) {
  // Abort agent when budget is exceeded
  pi.on("before_agent_start", async (_event, ctx) => {
    const budget = getBudget(ctx.sessionManager.getSessionFile());
    const cost = calcSessionCost(ctx);

    if (cost >= budget.limit) {
      if (!budget.aborted) {
        budget.aborted = true;
        ctx.ui.notify(
          `⛔ Budget exceeded! Session cost: $${cost.toFixed(2)} (limit: $${budget.limit.toFixed(2)})\nRun /budget to raise the limit or /new to start fresh.`,
          "error",
        );
      }
      ctx.abort();
      return;
    }

    // Warn at 80%
    if (cost >= budget.limit * 0.8 && !budget.warned) {
      budget.warned = true;
      ctx.ui.notify(
        `⚠️ Session cost $${cost.toFixed(2)} is approaching the $${budget.limit.toFixed(2)} budget.`,
        "warning",
      );
    }
  });

  // Update budget status in footer after each turn
  pi.on("turn_end", async (_event, ctx) => {
    if (!ctx.hasUI) return;
    const budget = getBudget(ctx.sessionManager.getSessionFile());
    if (!isFinite(budget.limit)) {
      ctx.ui.setStatus("budget", undefined);
      return;
    }
    const cost = calcSessionCost(ctx);
    const bStr = budgetStatusStr(cost, budget.limit);
    const bPct = (cost / budget.limit) * 100;
    let display: string;
    if (bPct > 90) {
      display = ctx.ui.theme.fg("error", `💲 ${bStr}`);
    } else if (bPct > 70) {
      display = ctx.ui.theme.fg("warning", `💲 ${bStr}`);
    } else {
      display = ctx.ui.theme.fg("dim", `💲 ${bStr}`);
    }
    ctx.ui.setStatus("budget", display);
  });

  // Reset flags on session switch
  pi.on("session_start", async (_event, ctx) => {
    const key = ctx.sessionManager.getSessionFile() ?? "__ephemeral__";
    const existing = sessionBudgets.get(key);
    if (!existing) {
      sessionBudgets.set(key, { limit: DEFAULT_BUDGET, warned: false, aborted: false });
    } else {
      existing.warned = false;
      existing.aborted = false;
    }
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    const key = ctx.sessionManager.getSessionFile() ?? "__ephemeral__";
    sessionBudgets.delete(key);
  });

  // /budget command
  pi.registerCommand("budget", {
    description: "Set or show the per-session cost budget limit",
    handler: async (args, ctx) => {
      const budget = getBudget(ctx.sessionManager.getSessionFile());
      const cost = calcSessionCost(ctx);

      if (!args || args.trim() === "") {
        ctx.ui.notify(
          `Session budget: $${budget.limit === Infinity ? "∞ (disabled)" : budget.limit.toFixed(2)}\nCurrent cost: $${cost.toFixed(2)}${isFinite(budget.limit) ? `\n${budgetStatusStr(cost, budget.limit)}` : ""}`,
          "info",
        );
        return;
      }

      const input = args.trim().toLowerCase();
      if (input === "off" || input === "disable" || input === "none" || input === "∞") {
        budget.limit = Infinity;
        budget.warned = false;
        budget.aborted = false;
        ctx.ui.notify("Budget disabled — no cost limit.", "info");
        return;
      }

      const newLimit = parseFloat(input.replace(/[\$\s]/g, ""));
      if (isNaN(newLimit) || newLimit <= 0) {
        ctx.ui.notify(`Invalid budget: "${args}". Use a positive number (e.g., /budget 10) or 'off'.`, "error");
        return;
      }

      budget.limit = newLimit;
      budget.warned = false;
      budget.aborted = false;
      ctx.ui.notify(
        `Budget set to $${newLimit.toFixed(2)} per session.\nCurrent cost: $${cost.toFixed(2)}`,
        "success",
      );
    },
  });
}
