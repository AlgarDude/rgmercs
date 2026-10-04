---
name: reference-mq-item-clicky-casttime-diverges
description: "TRUST item.Clicky.CastTime - it's the item's authoritative clicky cast time (correctly 0 for instant items even when the spell has a base cast time). max() with the spell was WRONG."
metadata: 
  node_type: memory
  type: reference
  originSessionId: de30caa0-1393-4395-9278-c87922083613
---

`item.Clicky.CastTime()` is the item's authoritative clicky cast time - **trust it.** It correctly reports 0 for a genuinely-instant clicky even when the underlying spell has a nonzero base cast time (the item overrides the spell). Do NOT try to reconcile it with the spell's cast time.

The tempting-but-wrong idea was `max(Clicky.CastTime, Clicky.Spell.MyCastTime)`, tried 7/3/26. It breaks legitimate instant items:
- **Artifact of Power**: `Clicky.CastTime`=0 (correct - instant), `Clicky.Spell.CastTime`=3000 (spurious - the item fires it instantly). max() = 3000 -> wrongly treated as a 3000ms cast -> blocked while moving, never FnF'd.

The item that motivated max() - **Pendant of the Pegasus (Norrath)** - turned out to be **broken custom-item data**: `Clicky.CastTime`=0 but it behaves like the spell's 500ms cast (movement interrupts it). That's a server-side data bug for its dev to fix, NOT a pattern to warp the cast-time source for. max() reverted 7/3/26; the 3 spots (`ItemReady`, `UseItem` castTime, `clickies.lua` move guard) trust `Clicky.CastTime`.

The fields CAN diverge (Dune Shield: Clicky 3000 / spell 0; Stonemaster: 2000 / 1500), but `Clicky.CastTime` is the one to trust for whether the *clicky* casts. With clickies FnF-by-default (see [[reference_rgmercs_instant_cast_confirm]]), a broken item like the Pendant just re-attempts cheaply (0ms) while moving and lands when you stop - no floor-spam.
