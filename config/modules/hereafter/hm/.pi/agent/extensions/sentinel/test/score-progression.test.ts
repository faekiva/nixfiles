/**
 * Score progression test
 *
 * Shows how the heuristic score evolves as the loop session grows,
 * verifying that the sentinel triggers at the right point.
 *
 * Run: npm test -- --testNamePattern "score progression"
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import { describe, it, expect } from "vitest";
import {
  extractThinkingBlocks,
  countConsecutiveAssistant,
  extractToolCalls,
  calcHeuristicScore,
  sumInputTokens,
} from "../src/sentinel-core";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function loadLoopSession(): unknown[] {
  const raw = fs.readFileSync(path.join(__dirname, "fixtures", "loop-session.json"), "utf8");
  return JSON.parse(raw) as unknown[];
}

describe("score progression through loop session", () => {
  const entries = loadLoopSession();

  it("starts low and crosses sentinel threshold", () => {
    const milestones: Array<{ at: number; score: number; tokens: number; turns: number }> = [];
    for (let i = 5; i <= entries.length; i += 5) {
      const slice = entries.slice(0, i);
      const tb = extractThinkingBlocks(slice);
      const ca = countConsecutiveAssistant(slice);
      const tc = extractToolCalls(slice);
      const breakdown = calcHeuristicScore(tb, ca, tc, slice);
      milestones.push({
        at: i,
        score: breakdown.total,
        tokens: sumInputTokens(slice),
        turns: ca,
      });
    }

    // Print table for debugging
    console.log("\n  entries | score  | tokens   | turns | sentinel | auto-abort");
    console.log("  ────────┼────────┼──────────┼───────┼──────────┼───────────");
    for (const m of milestones) {
      const s = m.score >= 0.15 ? "🔍yes" : "no";
      const a = m.score >= 0.55 ? "🚨yes" : "no";
      console.log(
        `  ${String(m.at).padStart(7)} | ${m.score.toFixed(3).padStart(6)} | ${String(m.tokens).padStart(8)} | ${String(m.turns).padStart(5)} | ${s.padStart(8)} | ${a}`,
      );
    }

    // Early session should be below sentinel threshold
    const firstScore = milestones[0]?.score ?? 1;
    expect(firstScore, "early session should score low").toBeLessThan(0.15);

    // Somewhere in the middle it should cross sentinel
    const crossedSentinel = milestones.some((m) => m.score >= 0.15);
    expect(crossedSentinel, "should eventually cross sentinel threshold").toBe(true);

    // Eventually it should cross auto-abort
    const crossedAbort = milestones.some((m) => m.score >= 0.55);
    expect(crossedAbort, "should eventually cross auto-abort threshold").toBe(true);
  });
});
