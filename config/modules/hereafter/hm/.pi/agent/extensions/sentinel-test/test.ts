/**
 * Sentinel Test Runner
 *
 * Runs the heuristic functions from sentinel-core.ts against real session data
 * to verify loop detection works before deploying.
 *
 * Usage: npx tsx sentinel-test/test.ts
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import {
  extractThinkingBlocks,
  countConsecutiveAssistant,
  extractToolCalls,
  calcHeuristicScore,
  analyzeThinkingRepetition,
  countSelfQuestions,
  ngramJaccard,
  sumInputTokens,
} from "../sentinel-core";

const __filename = fileURLToPath(import.meta.url);
const SESSION_DIR = path.dirname(__filename);

interface TestCase {
  name: string;
  file: string;
}

const TEST_CASES: TestCase[] = [
  { name: "💀 $8.21 loop session", file: "loop-session.json" },
  { name: "✅ Normal session", file: "normal-session.json" },
];

function runTest(tc: TestCase): void {
  const filePath = path.join(SESSION_DIR, tc.file);
  const raw = fs.readFileSync(filePath, "utf8");
  const entries = JSON.parse(raw) as unknown[];

  console.log(`\n${"═".repeat(60)}`);
  console.log(`  ${tc.name}`);
  console.log(`${"═".repeat(60)}`);

  // Basic stats
  const thinkingBlocks = extractThinkingBlocks(entries);
  const consecutiveAssistant = countConsecutiveAssistant(entries);
  const toolCalls = extractToolCalls(entries);

  // Count messages by type
  let userCount = 0;
  let assistantCount = 0;
  for (const entry of entries as Array<{ type?: string; message?: { role?: string } }>) {
    if (entry.type === "message") {
      if (entry.message?.role === "user") userCount++;
      if (entry.message?.role === "assistant") assistantCount++;
    }
  }

  console.log(`\n📊 Session Stats`);
  console.log(`   User messages:        ${userCount}`);
  console.log(`   Assistant turns:      ${assistantCount}`);
  console.log(`   Thinking blocks:      ${thinkingBlocks.length}`);
  console.log(`   Tool calls:           ${toolCalls.length}`);
  console.log(`   Max consecutive asst: ${consecutiveAssistant}`);

  if (toolCalls.length > 0) {
    const toolDist = new Map<string, number>();
    for (const tc of toolCalls) {
      toolDist.set(tc.tool, (toolDist.get(tc.tool) ?? 0) + 1);
    }
    console.log(`   Tool distribution:`);
    for (const [tool, count] of [...toolDist.entries()].sort((a, b) => b[1] - a[1])) {
      console.log(`     ${tool}: ${count}`);
    }
  }

  // Thinking block previews
  if (thinkingBlocks.length > 0) {
    console.log(`\n📝 Thinking Blocks (first ${Math.min(3, thinkingBlocks.length)}):`);
    for (let i = 0; i < Math.min(3, thinkingBlocks.length); i++) {
      const preview = thinkingBlocks[i].replace(/\n/g, " ").slice(0, 120);
      console.log(`   [${i + 1}] ${preview}...`);
    }
  }

  // Heuristic scoring
  const breakdown = calcHeuristicScore(thinkingBlocks, consecutiveAssistant, toolCalls, entries);

  console.log(`\n🎯 Heuristic Breakdown`);
  console.log(`   Thinking repetition:   ${breakdown.thinkingRepetition.toFixed(3)}`);
  console.log(`   Turn pressure:         ${breakdown.turnPressure.toFixed(3)} (${consecutiveAssistant} turns / 12 cap)`);
  console.log(`   Token volume:          ${breakdown.tokenVolume.toFixed(3)} (${sumInputTokens(entries).toLocaleString()} input tokens)`);
  console.log(`   Self-questioning:      ${breakdown.selfQuestioning.toFixed(3)} (${countSelfQuestions(thinkingBlocks)} questions / ${thinkingBlocks.length} blocks)`);
  console.log(`   Tool call repetition:  ${breakdown.toolCallRepetition.toFixed(3)} (${toolCalls.length} tool calls)`);
  console.log(`   ─────────────────────────────────────────`);
  console.log(`   TOTAL SCORE:           ${breakdown.total.toFixed(3)}`);

  const normalThreshold = 0.55;
  const strictThreshold = 0.40;

  console.log(`\n🚦 Detection`);
  console.log(`   Normal threshold (0.55):   ${breakdown.total >= normalThreshold ? "✅ WOULD TRIGGER" : "❌ missed"}`);
  console.log(`   Strict threshold (0.40):   ${breakdown.total >= strictThreshold ? "✅ WOULD TRIGGER" : "❌ missed"}`);

  // Show consecutive assistant pairs with similarity
  if (thinkingBlocks.length >= 2) {
    console.log(`\n🔗 Thinking Block Pairwise Similarity (n-gram Jaccard):`);
    for (let i = 1; i < thinkingBlocks.length; i++) {
      const sim = ngramJaccard(thinkingBlocks[i - 1], thinkingBlocks[i]);
      console.log(`   [${i}] ↔ [${i + 1}]: ${sim.toFixed(3)}`);
    }
  }
}

// Run all tests
console.log("🛡️ Sentinel Heuristic Test Runner");
console.log("══════════════════════════════════");

for (const tc of TEST_CASES) {
  try {
    runTest(tc);
  } catch (err) {
    console.error(`\n❌ ${tc.name} failed:`, err);
  }
}

console.log(`\n${"═".repeat(60)}\n`);
