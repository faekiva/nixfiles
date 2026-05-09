/**
 * Sentinel Core — Pure Heuristic Analysis
 *
 * All the loop-detection logic, extracted into importable functions
 * so the same code can be tested against real session data.
 */

// =============================================================================
// Thresholds
// =============================================================================

/** Above this, escalate to the filter model for review */
export const SENTINEL_TRIGGER = 0.15;
/** Above this, auto-abort without LLM confirmation */
export const AUTO_ABORT_THRESHOLD = 0.55;
/** Strict mode variants */
export const STRICT_SENTINEL_TRIGGER = 0.10;
export const STRICT_AUTO_ABORT_THRESHOLD = 0.40;

// =============================================================================
// Types
// =============================================================================

export interface ToolCall {
  tool: string;
  args: string;
}

export interface HeuristicBreakdown {
  thinkingRepetition: number;
  turnPressure: number;
  tokenVolume: number;
  selfQuestioning: number;
  toolCallRepetition: number;
  total: number;
}

// =============================================================================
// Session Extraction
// =============================================================================

/** Extract thinking blocks from session entries */
export function extractThinkingBlocks(entries: unknown[]): string[] {
  const blocks: string[] = [];
  for (const entry of entries as Array<{
    type?: string;
    message?: { role?: string; content?: Array<{ type?: string; thinking?: string }> };
  }>) {
    if (entry.type === "message" && entry.message?.role === "assistant") {
      for (const item of entry.message.content ?? []) {
        if (item.type === "thinking" && item.thinking) {
          blocks.push(item.thinking);
        }
      }
    }
  }
  return blocks;
}

/** Count consecutive assistant messages since last user message */
export function countConsecutiveAssistant(entries: unknown[]): number {
  let count = 0;
  for (let i = (entries as unknown[]).length - 1; i >= 0; i--) {
    const entry = entries[i] as { type?: string; message?: { role?: string } };
    if (entry.type === "message") {
      if (entry.message?.role === "assistant") {
        count++;
      } else if (entry.message?.role === "user") {
        break;
      }
    }
  }
  return count;
}

/** Extract tool calls from session entries */
export function extractToolCalls(entries: unknown[]): ToolCall[] {
  const calls: ToolCall[] = [];
  for (const entry of entries as Array<{
    type?: string;
    message?: { role?: string; content?: Array<Record<string, unknown>> };
  }>) {
    if (entry.type === "message" && entry.message?.role === "assistant") {
      for (const item of entry.message.content ?? []) {
        if (!item || typeof item !== "object") continue;
        const type = item.type;
        if (type === "tool_use") {
          calls.push({
            tool: (item.name as string) ?? "",
            args: typeof item.arguments === "string"
              ? item.arguments
              : JSON.stringify(item.arguments ?? {}),
          });
        } else if (type === "toolCall") {
          // Kilo/pi stores tool call name at top level of the item
          calls.push({
            tool: (item.name as string) ?? "",
            args: JSON.stringify(item.arguments ?? {}),
          });
        }
      }
    }
  }
  return calls;
}

/** Sum total input tokens across all assistant messages */
export function sumInputTokens(entries: unknown[]): number {
  let total = 0;
  for (const entry of entries as Array<{
    type?: string;
    message?: { role?: string; usage?: { input?: number } };
  }>) {
    if (entry.type === "message" && entry.message?.role === "assistant") {
      total += entry.message.usage?.input ?? 0;
    }
  }
  return total;
}

/** Average cache hit ratio across assistant messages (0–1) */
export function avgCacheRatio(entries: unknown[]): number {
  let totalInput = 0;
  let totalCache = 0;
  for (const entry of entries as Array<{
    type?: string;
    message?: { role?: string; usage?: { input?: number; cacheRead?: number } };
  }>) {
    if (entry.type === "message" && entry.message?.role === "assistant") {
      const usage = entry.message.usage;
      if (usage) {
        totalInput += usage.input ?? 0;
        totalCache += usage.cacheRead ?? 0;
      }
    }
  }
  if (totalInput === 0) return 1;
  return totalCache / (totalCache + totalInput);
}

// =============================================================================
// Similarity
// =============================================================================

/** Jaccard similarity of word n-grams between two strings */
export function ngramJaccard(a: string, b: string, n: number = 3): number {
  const aWords = a.toLowerCase().split(/\s+/);
  const bWords = b.toLowerCase().split(/\s+/);
  const aNgrams = new Set<string>();
  const bNgrams = new Set<string>();

  for (let i = 0; i <= aWords.length - n; i++) {
    aNgrams.add(aWords.slice(i, i + n).join(" "));
  }
  for (let i = 0; i <= bWords.length - n; i++) {
    bNgrams.add(bWords.slice(i, i + n).join(" "));
  }

  if (aNgrams.size === 0 || bNgrams.size === 0) return 0;

  let intersection = 0;
  for (const ng of aNgrams) {
    if (bNgrams.has(ng)) intersection++;
  }

  const union = aNgrams.size + bNgrams.size - intersection;
  return intersection / union;
}

// =============================================================================
// Heuristic Signals
// =============================================================================

/** Analyze thinking repetition across consecutive blocks */
export function analyzeThinkingRepetition(blocks: string[]): number {
  if (blocks.length < 2) return 0;

  let maxOverlap = 0;
  let highOverlapStreak = 0;

  for (let i = 1; i < blocks.length; i++) {
    const overlap = ngramJaccard(blocks[i - 1], blocks[i]);
    maxOverlap = Math.max(maxOverlap, overlap);
    if (overlap > 0.45) {
      highOverlapStreak++;
    } else {
      highOverlapStreak = 0;
    }
  }

  const streakBonus = Math.min(highOverlapStreak / 3, 1) * 0.3;
  return Math.min(maxOverlap * 0.7 + streakBonus, 1);
}

/** Count thinking blocks that end with a self-directed question */
export function countSelfQuestions(blocks: string[]): number {
  let count = 0;
  for (const block of blocks) {
    const lines = block.split("\n").filter((l) => l.trim());
    const lastLine = lines[lines.length - 1]?.trim() ?? "";
    if (lastLine.endsWith("?") && lastLine.length > 10) {
      count++;
    }
  }
  return count;
}

/** Detect repeated tool calls (same tool + similar args) */
export function analyzeToolCallRepetition(calls: ToolCall[]): number {
  if (calls.length < 3) return 0;

  const fileOps = calls.filter((c) => c.tool === "read" || c.tool === "bash");
  if (fileOps.length < 3) return 0;

  const filePaths = fileOps.map((c) => {
    const match = c.args.match(/(?:path|file|command)["\s]*[:=\s]*["']?([\/\w.-]+[\w.-]+)/i);
    return match?.[1] ?? c.args.slice(0, 80);
  });

  const pathCounts = new Map<string, number>();
  for (const p of filePaths) {
    pathCounts.set(p, (pathCounts.get(p) ?? 0) + 1);
  }

  const maxRepeats = Math.max(...pathCounts.values(), 0);
  if (maxRepeats >= 3) {
    return Math.min(maxRepeats / 5, 1);
  }
  return 0;
}

// =============================================================================
// Overall Score
// =============================================================================

/** Compute overall heuristic loop score (0–1) with full breakdown */
export function calcHeuristicScore(
  thinkingBlocks: string[],
  consecutiveAssistant: number,
  toolCalls: ToolCall[],
  entries: unknown[],
): HeuristicBreakdown {
  const repetition = analyzeThinkingRepetition(thinkingBlocks);
  const turnPressure = Math.min(consecutiveAssistant / 12, 1);
  const questionRatio = countSelfQuestions(thinkingBlocks) / Math.max(thinkingBlocks.length, 1);
  const toolRep = analyzeToolCallRepetition(toolCalls);

  // Token volume: normal sessions use ~5K–50K input tokens total.
  // The loop session used 1.5M. Score rises sharply above 200K.
  const totalInputTokens = sumInputTokens(entries);
  const tokenScore = Math.min(Math.max((totalInputTokens - 200_000) / 300_000, 0), 1);

  const total = Math.min(
    repetition * 0.25 +
    turnPressure * 0.30 +
    tokenScore * 0.25 +
    questionRatio * 0.10 +
    toolRep * 0.10,
    1,
  );

  return {
    thinkingRepetition: repetition * 0.25,
    turnPressure: turnPressure * 0.30,
    tokenVolume: tokenScore * 0.25,
    selfQuestioning: questionRatio * 0.10,
    toolCallRepetition: toolRep * 0.10,
    total,
  };
}
