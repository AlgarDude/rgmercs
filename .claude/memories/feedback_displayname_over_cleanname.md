---
name: displayname-over-cleanname
description: User prefers Spawn.DisplayName() as the default spawn-name accessor — except when same-name NPC disambiguation matters
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 27e08510-3115-48ee-8884-30861a154eeb
---

User prefers `Spawn.DisplayName()` as the default spawn-name accessor — for command arguments (`/xtarget set`, `/tell`, `/follow`), display strings, identification.

**Why:** DisplayName mirrors EQ's `%T` token (the canonical form EQ uses for its own commands), so it round-trips reliably and matches what's rendered in the UI. CleanName's behavior is under-documented.

**Important exception — keep `.Name()` for NPC disambiguation:** when targeting a specific NPC and there may be same-named mobs in zone, use `.Name()` (the "dirty" internal form with underscores/digits like `a_runeshark00`) because the suffix is what differentiates instances. `RGMercs.Targeting.AddXTByID` uses Name() for non-PC spawns for this exact reason. Don't collapse that branch.

**How to apply:** Default to `DisplayName()` for new spawn-name code. Keep `.Name()` when same-name NPC distinction is the point. For PCs, CleanName/DisplayName are interchangeable; user is migrating toward DisplayName over time.
