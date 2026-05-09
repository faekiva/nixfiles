/**
 * Sentinel core function tests
 *
 * Runs the heuristic functions from src/sentinel-core.ts against real
 * session fixture data to verify loop detection works.
 *
 * Usage: npm test          (in the sentinel/ directory)
 *        npm run test:watch (watch mode)
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
  analyzeThinkingRepetition,
  countSelfQuestions,
  ngramJaccard,
  sumInputTokens,
  avgCacheRatio,
  analyzeToolCallRepetition,
  SENTINEL_TRIGGER,
  AUTO_ABORT_THRESHOLD,
} from "../src/sentinel-core";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const FIXTURES_DIR = path.join(__dirname, "fixtures");

function loadFixture(name: string): unknown[] {
  const raw = fs.readFileSync(path.join(FIXTURES_DIR, name), "utf8");
  return JSON.parse(raw) as unknown[];
}

// =============================================================================
// Fixtures
// =============================================================================

describe("loop session fixture", () => {
  const entries = loadFixture("loop-session.json");

  it("has session data", () => {
    expect(entries.length).toBeGreaterThan(0);
  });

  it("extracts thinking blocks", () => {
    const blocks = extractThinkingBlocks(entries);
    expect(blocks.length).toBeGreaterThan(0);
  });

  it("extracts tool calls", () => {
    const calls = extractToolCalls(entries);
    expect(calls.length).toBeGreaterThan(0);
  });

  it("counts consecutive assistant messages", () => {
    const count = countConsecutiveAssistant(entries);
    expect(count).toBeGreaterThan(1);
  });

  it("scores above the auto-abort threshold", () => {
    const blocks = extractThinkingBlocks(entries);
    const ca = countConsecutiveAssistant(entries);
    const calls = extractToolCalls(entries);
    const breakdown = calcHeuristicScore(blocks, ca, calls, entries);
    expect(breakdown.total).toBeGreaterThan(AUTO_ABORT_THRESHOLD);
  });

  it("scores above the sentinel trigger threshold", () => {
    const blocks = extractThinkingBlocks(entries);
    const ca = countConsecutiveAssistant(entries);
    const calls = extractToolCalls(entries);
    const breakdown = calcHeuristicScore(blocks, ca, calls, entries);
    expect(breakdown.total).toBeGreaterThan(SENTINEL_TRIGGER);
  });

  it("shows score progression — crosses sentinel threshold eventually", () => {
    // Simulate running the check as the session grows
    let crossedSentinel = false;
    let crossedAbort = false;
    for (let i = 10; i <= entries.length; i += 10) {
      const slice = entries.slice(0, i);
      const blocks = extractThinkingBlocks(slice);
      const ca = countConsecutiveAssistant(slice);
      const calls = extractToolCalls(slice);
      const score = calcHeuristicScore(blocks, ca, calls, slice).total;
      if (score >= SENTINEL_TRIGGER) crossedSentinel = true;
      if (score >= AUTO_ABORT_THRESHOLD) crossedAbort = true;
    }
    expect(crossedSentinel).toBe(true);
    expect(crossedAbort).toBe(true);
  });
});

describe("normal session fixture", () => {
  const entries = loadFixture("normal-session.json");

  it("has session data", () => {
    expect(entries.length).toBeGreaterThan(0);
  });

  it("scores below the auto-abort threshold", () => {
    const blocks = extractThinkingBlocks(entries);
    const ca = countConsecutiveAssistant(entries);
    const calls = extractToolCalls(entries);
    const breakdown = calcHeuristicScore(blocks, ca, calls, entries);
    expect(breakdown.total).toBeLessThan(AUTO_ABORT_THRESHOLD);
  });
});

// =============================================================================
// False positive — sentinel triggered on a normal productive session
// Session: "why is the sentinel pi extension called src in the pi gui?"
// Sentinel aborted things (3x) but this was NOT thrashing — just a normal
// multi-turn conversation with tool calls and a few aborted attempts.
//
// The heuristic correctly flags it (score > 0.15) — that's its job as a canary.
// The false positive was Qwen blindly confirming. The judge model should clear it.
// =============================================================================

describe("sentinel false-positive session", () => {
  const entries = loadFixture("sentinel-false-positive.json");

  it("has session data", () => {
    expect(entries.length).toBeGreaterThan(0);
  });

  it("extracts thinking blocks", () => {
    const blocks = extractThinkingBlocks(entries);
    expect(blocks.length).toBeGreaterThan(0);
  });

  it("extracts tool calls", () => {
    const calls = extractToolCalls(entries);
    expect(calls.length).toBeGreaterThan(0);
  });

  it("is flagged by the heuristic (expected — triggers the filter model)", () => {
    const blocks = extractThinkingBlocks(entries);
    const ca = countConsecutiveAssistant(entries);
    const calls = extractToolCalls(entries);
    const breakdown = calcHeuristicScore(blocks, ca, calls, entries);
    expect(breakdown.total).toBeGreaterThan(SENTINEL_TRIGGER);
  });

  it("stays below the auto-abort threshold (so judge gets a say)", () => {
    const blocks = extractThinkingBlocks(entries);
    const ca = countConsecutiveAssistant(entries);
    const calls = extractToolCalls(entries);
    const breakdown = calcHeuristicScore(blocks, ca, calls, entries);
    expect(breakdown.total).toBeLessThan(AUTO_ABORT_THRESHOLD);
  });

  it("shows score progression — crosses sentinel threshold mid-session", () => {
    // The heuristic should flag this session at some point as it grows
    let crossedSentinel = false;
    let crossedAbort = false;
    for (let i = 10; i <= entries.length; i += 5) {
      const slice = entries.slice(0, i);
      const blocks = extractThinkingBlocks(slice);
      const ca = countConsecutiveAssistant(slice);
      const calls = extractToolCalls(slice);
      const score = calcHeuristicScore(blocks, ca, calls, slice).total;
      if (score >= SENTINEL_TRIGGER) crossedSentinel = true;
      if (score >= AUTO_ABORT_THRESHOLD) crossedAbort = true;
    }
    expect(crossedSentinel).toBe(true);
    // Should NOT reach auto-abort territory — this was a productive conversation
    expect(crossedAbort).toBe(false);
  });
});

// =============================================================================
// False positive #2 — current session itself triggered sentinel
// User was working on the sentinel extension when sentinel falsely accused
// thinking block 4 of "back-and-forth re-evaluation" (discussing how to handle
// the failing test). Score: 0.24, confidence: 75%, call count: 9.
//
// Same deal: heuristic flags it correctly, judge should clear it.
// =============================================================================

describe("sentinel false-positive session #2 (current session)", () => {
  const entries = loadFixture("current-session-false-positive.json");

  it("has session data", () => {
    expect(entries.length).toBeGreaterThan(0);
  });

  it("extracts thinking blocks", () => {
    const blocks = extractThinkingBlocks(entries);
    expect(blocks.length).toBeGreaterThan(0);
  });

  it("is flagged by the heuristic (expected — triggers the filter model)", () => {
    const blocks = extractThinkingBlocks(entries);
    const ca = countConsecutiveAssistant(entries);
    const calls = extractToolCalls(entries);
    const breakdown = calcHeuristicScore(blocks, ca, calls, entries);
    expect(breakdown.total).toBeGreaterThan(SENTINEL_TRIGGER);
  });

  it("stays below the auto-abort threshold (so judge gets a say)", () => {
    const blocks = extractThinkingBlocks(entries);
    const ca = countConsecutiveAssistant(entries);
    const calls = extractToolCalls(entries);
    const breakdown = calcHeuristicScore(blocks, ca, calls, entries);
    expect(breakdown.total).toBeLessThan(AUTO_ABORT_THRESHOLD);
  });
});

// =============================================================================
// Unit: ngramJaccard
// =============================================================================

describe("ngramJaccard", () => {
  it("returns 1 for identical strings", () => {
    expect(ngramJaccard("hello world foo", "hello world foo")).toBe(1);
  });

  it("returns 0 for completely different strings", () => {
    const sim = ngramJaccard("aaa bbb ccc", "xxx yyy zzz");
    expect(sim).toBe(0);
  });

  it("returns partial similarity for overlapping strings", () => {
    const sim = ngramJaccard("hello world foo bar baz", "world foo bar baz qux");
    expect(sim).toBeGreaterThan(0);
    expect(sim).toBeLessThan(1);
  });

  it("returns 0 when strings are shorter than n-gram size", () => {
    expect(ngramJaccard("a b", "x y", 3)).toBe(0);
  });
});

// =============================================================================
// Unit: analyzeThinkingRepetition
// =============================================================================

describe("analyzeThinkingRepetition", () => {
  it("returns 0 for a single block", () => {
    expect(analyzeThinkingRepetition(["just one block"])).toBe(0);
  });

  it("returns 0 for an empty array", () => {
    expect(analyzeThinkingRepetition([])).toBe(0);
  });

  it("returns high score for identical blocks", () => {
    const repeated = Array(4).fill("the same thinking over and over again");
    expect(analyzeThinkingRepetition(repeated)).toBeGreaterThan(0.5);
  });

  it("returns low score for diverse blocks", () => {
    const diverse = [
      "first I need to check the config file",
      "now let me look at the database schema",
      "running the build to see if it compiles",
      "deploying to staging for testing",
    ];
    expect(analyzeThinkingRepetition(diverse)).toBeLessThan(0.3);
  });
});

// =============================================================================
// Unit: countSelfQuestions
// =============================================================================

describe("countSelfQuestions", () => {
  it("counts blocks ending with a question", () => {
    const blocks = [
      "Let me think about this.\nWhat should I do next?",
      "I will try the first approach.",
      "Hmm, maybe I should look at the docs?\nActually no.",
      "Let me check if this works?",
    ];
    expect(countSelfQuestions(blocks)).toBe(2);
  });

  it("ignores short question-like endings", () => {
    const blocks = ["ok?"];
    expect(countSelfQuestions(blocks)).toBe(0);
  });

  it("returns 0 for empty array", () => {
    expect(countSelfQuestions([])).toBe(0);
  });
});

// =============================================================================
// Unit: analyzeToolCallRepetition
// =============================================================================

describe("analyzeToolCallRepetition", () => {
  it("returns 0 for fewer than 3 file ops", () => {
    expect(
      analyzeToolCallRepetition([
        { tool: "read", args: '{"path":"/foo"}' },
        { tool: "bash", args: "ls" },
      ]),
    ).toBe(0);
  });

  it("detects repeated reads of the same file", () => {
    const calls = Array(5).fill({ tool: "read", args: '{"path":"/etc/config.toml"}' });
    expect(analyzeToolCallRepetition(calls)).toBeGreaterThan(0);
  });
});

// =============================================================================
// Unit: sumInputTokens / avgCacheRatio
// =============================================================================

describe("sumInputTokens", () => {
  it("returns 0 for empty entries", () => {
    expect(sumInputTokens([])).toBe(0);
  });

  it("sums input tokens from assistant messages", () => {
    const entries = [
      { type: "message", message: { role: "assistant", usage: { input: 100 } } },
      { type: "message", message: { role: "user" } },
      { type: "message", message: { role: "assistant", usage: { input: 200 } } },
    ];
    expect(sumInputTokens(entries)).toBe(300);
  });
});

describe("avgCacheRatio", () => {
  it("returns 1 when there are no input tokens", () => {
    expect(avgCacheRatio([])).toBe(1);
  });

  it("calculates cache ratio correctly", () => {
    const entries = [
      { type: "message", message: { role: "assistant", usage: { input: 100, cacheRead: 100 } } },
    ];
    expect(avgCacheRatio(entries)).toBe(0.5);
  });
});
