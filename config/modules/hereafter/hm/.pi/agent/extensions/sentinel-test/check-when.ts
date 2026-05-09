import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";
import { calcHeuristicScore, extractThinkingBlocks, countConsecutiveAssistant, extractToolCalls, sumInputTokens } from "../sentinel-core";

const __filename = fileURLToPath(import.meta.url);
const entries = JSON.parse(fs.readFileSync(path.join(path.dirname(__filename), "loop-session.json"), "utf8")) as unknown[];

console.log("Score progression as session unfolds:\n");

for (let i = 5; i <= entries.length; i += 5) {
  const slice = entries.slice(0, i);
  const tb = extractThinkingBlocks(slice);
  const ca = countConsecutiveAssistant(slice);
  const tc = extractToolCalls(slice);
  const breakdown = calcHeuristicScore(tb, ca, tc, slice);
  const hitsSentinel = breakdown.total >= 0.15;
  const hitsNormal = breakdown.total >= 0.55;
  const flags = [];
  if (hitsSentinel) flags.push("🔍sentinel");
  if (hitsNormal) flags.push("🚨auto-abort");
  console.log(
    `[${String(i).padStart(2)} entries] score=${breakdown.total.toFixed(3)} ` +
    `turns=${ca} tokens=${(sumInputTokens(slice)/1000).toFixed(0)}K ` +
    `${flags.join(" ")}`
  );
}
