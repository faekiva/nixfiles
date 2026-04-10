---
name: prefer-simple-solutions
description: User prefers simple, low-ceremony solutions (like commenting out code) over elaborate abstractions (mkEnableOption, filterAttrs pipelines) for toggling packages
type: feedback
---

Prefer the simplest possible approach for toggling things on/off in nix configs — e.g. commenting out a line rather than adding mkEnableOption boilerplate or building filtering abstractions.

**Why:** The user pointed out that mkEnableOption adds a lot of boilerplate that would compound over time, and that even a data-driven approach was overengineered for the task. A comment is obvious, grep-able, and zero-cost.

**How to apply:** When the user wants to temporarily disable something in their nix config, default to commenting it out unless they specifically ask for a module option or programmatic approach.
