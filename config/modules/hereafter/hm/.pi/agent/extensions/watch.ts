/**
 * Watch Extension — stream agent events in real-time during print mode.
 *
 * Usage:
 *   pi --watch -p "your prompt"
 *
 * Shows the agent thinking, writing files, and running tools as they happen,
 * instead of waiting for the entire run to complete. Only activates when
 * ctx.hasUI is false (print/batch mode) — interactive mode already shows
 * everything.
 */

import * as fs from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Direct sync write to fd 1 (stdout). Bypasses Node's buffering when stdout
// is piped, so output appears immediately in the terminal.
function out(text: string): void {
  fs.writeSync(1, text);
}

// Extract a readable one-liner from tool arguments.
function toolArg(name: string, args: Record<string, unknown>): string {
  switch (name) {
    case "edit":
    case "write":
    case "read":
      return args.path ? String(args.path) : "?";
    case "bash":
      return args.command ? String(args.command).slice(0, 120) : "?";
    default: {
      const s = JSON.stringify(args);
      return s.length > 120 ? s.slice(0, 120) + "…" : s;
    }
  }
}

export default function (pi: ExtensionAPI) {
  pi.registerFlag("watch", {
    description: "Stream agent events to stdout in real-time",
    type: "boolean",
    default: false,
  });

  let active = false;
  let turnIdx = 0;

  pi.on("session_start", async (_event, ctx) => {
    active = !!pi.getFlag("watch") && !ctx.hasUI;
    turnIdx = 0;
  });

  pi.on("agent_start", async () => {
    if (!active) return;
    out("\n━━━ agent starting ━━━\n\n");
  });

  pi.on("turn_start", async (event) => {
    if (!active) return;
    turnIdx = event.turnIndex;
    out(`\n── turn ${turnIdx} ──\n`);
  });

  pi.on("message_update", async (event) => {
    if (!active) return;
    const d = event.assistantMessageEvent;
    if (d.type === "text_delta") out(d.delta);
    if (d.type === "thinking_delta") out(`💭 ${d.delta}`);
  });

  pi.on("tool_execution_start", async (event) => {
    if (!active) return;
    out(`\n  🔧 ${event.toolName}: ${toolArg(event.toolName, event.args)}\n`);
  });

  pi.on("tool_execution_end", async (event) => {
    if (!active) return;
    const mark = event.isError ? "✗" : "✓";
    out(`  ${mark} ${event.toolName} finished\n`);
  });

  pi.on("agent_end", async (event) => {
    if (!active) return;
    out(`\n━━━ agent done (${event.messages.length} msgs) ━━━\n`);
  });
}
