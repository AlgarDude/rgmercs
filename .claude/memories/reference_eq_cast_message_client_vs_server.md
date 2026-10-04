---
name: reference-eq-cast-message-client-vs-server
description: "Spell cast messages are client-side (instant ~0-16ms); item cast messages come from the SERVER (~250-350ms, jittery). Tested RoF2/EMU; Live UNTESTED."
metadata: 
  node_type: memory
  type: reference
  originSessionId: de30caa0-1393-4395-9278-c87922083613
---

On **RoF2 / EMU (EQ Might, tested 7/3/26)**, the "You begin casting" cast message originates differently depending on the source, and this is a big deal for confirm timing:

- **Spells → client-side.** The gem locks out client-side the instant you cast, so `readyCheck`/gem flips and the message lands near-instantly (~0-16ms). Fast.
- **Items (clickies) → server-side.** The "You begin casting" line doesn't arrive until ~250-350ms after `/useitem`, and it's **variable across fires** (network jitter). It lands in the same band as the server-confirmed cooldown flip. Even truly-instant, no-cast-bar clickies behave this way.

Measured live (EQ Might, ping ~146ms): a no-recast instant clicky's message arrived at 241/283/353ms across three fires, with the confirm loop polling every ~13ms (per-frame) the whole time — so the gap is REAL, not a polling artifact.

Consequence: you cannot confirm an item cast faster than ~250ms whichever signal you use (message or cooldown flip). **Spells are the only instants that confirm fast.** So for performance, FnF items rather than wait; keep the confirm only where it's consumed (the queue).

**Live is UNTESTED** — this is a RoF2/EMU observation. Don't assume it holds on Live.

Related: [[reference_rgmercs_instant_cast_confirm]].
