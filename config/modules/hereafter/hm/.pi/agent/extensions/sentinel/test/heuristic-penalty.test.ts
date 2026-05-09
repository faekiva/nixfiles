/**
 * Heuristic penalty tests
 *
 * Verifies that after the judge denies a loop case, the effective sentinel
 * threshold increases by 0.1 per denial, so the heuristic score must grow
 * before being re-sent to LLMs.
 */

import { describe, it, expect } from "vitest";
import { SENTINEL_TRIGGER, STRICT_SENTINEL_TRIGGER } from "../src/sentinel-core";

describe("heuristic penalty on judge denial", () => {
  /**
   * Simulates the effective threshold calculation from index.ts.
   * When the judge denies (says "not a loop"), heuristicPenalty += 0.1.
   * The effective sentinel trigger becomes: sentinelThreshold + heuristicPenalty.
   */
  function effectiveThreshold(
    sentinelThreshold: number,
    judgeDenials: number,
  ): number {
    return sentinelThreshold + judgeDenials * 0.1;
  }

  it("starts at the base sentinel threshold with zero denials", () => {
    expect(effectiveThreshold(SENTINEL_TRIGGER, 0)).toBe(SENTINEL_TRIGGER);
    expect(effectiveThreshold(SENTINEL_TRIGGER, 0)).toBe(0.15);
  });

  it("increases by 0.1 after each judge denial", () => {
    expect(effectiveThreshold(SENTINEL_TRIGGER, 1)).toBeCloseTo(0.25, 5);
    expect(effectiveThreshold(SENTINEL_TRIGGER, 2)).toBeCloseTo(0.35, 5);
    expect(effectiveThreshold(SENTINEL_TRIGGER, 3)).toBeCloseTo(0.45, 5);
  });

  it("works with strict mode base threshold", () => {
    expect(effectiveThreshold(STRICT_SENTINEL_TRIGGER, 0)).toBeCloseTo(0.10, 5);
    expect(effectiveThreshold(STRICT_SENTINEL_TRIGGER, 1)).toBeCloseTo(0.20, 5);
    expect(effectiveThreshold(STRICT_SENTINEL_TRIGGER, 2)).toBeCloseTo(0.30, 5);
  });

  it("requires higher scores to re-escalate after denials", () => {
    const score = 0.20;
    const baseThreshold = SENTINEL_TRIGGER; // 0.15

    // First time: score 0.20 > 0.15 → escalates
    expect(score >= effectiveThreshold(baseThreshold, 0)).toBe(true);

    // After 1 judge denial: score 0.20 < 0.25 → blocked
    expect(score >= effectiveThreshold(baseThreshold, 1)).toBe(false);

    // After 2 judge denials: score 0.20 < 0.35 → blocked
    expect(score >= effectiveThreshold(baseThreshold, 2)).toBe(false);
  });

  it("score must grow to overcome accumulated penalty", () => {
    // After 3 denials, the effective threshold is 0.45
    const threshold = effectiveThreshold(SENTINEL_TRIGGER, 3);
    expect(threshold).toBeCloseTo(0.45, 5);

    // A score of 0.30 won't cut it
    expect(0.30 >= threshold).toBe(false);

    // But a score of 0.50 will
    expect(0.50 >= threshold).toBe(true);
  });
});
