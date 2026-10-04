---
name: mq-npc-search-includes-npcpet
description: "MQ spawn search: `npc` already matches NPC-owned pets (npcpet) since MQ commit 01b0dac4 (2021); never sum npc + npcpet, it double-counts. `npc` excludes player pets; `nopet` excludes all pets."
metadata: 
  node_type: memory
  type: reference
  originSessionId: d846030e-54a3-475a-9fcf-2c46146f8ffd
---

In MQ spawn search, the **`npc` type already matches NPC-owned pets** (`npcpet`). This has been true since MQ commit `01b0dac4` ("NPCPET is now also NPC in SpawnSearch"), client-side in `SpawnMatchesSearch` — so it holds on **both Live and EMU**.

Consequences:
- **Never search/count `npc` AND `npcpet` and sum them** — it double-counts every NPC pet. Just use `npc`. (This was a pre-2021 idiom that became redundant; Derple's original RGMercs mez/aggro code carried it forward and it propagated. Fixed across charm/combat/mez 6/15/26.)
- **`npc` does NOT match player pets** (pcpet) — a player-owned pet is explicitly excluded from an `npc` search. So an `npc` search never sweeps in pcpets.
- **`nopet`** is a real supported filter that excludes all PET-type spawns; add it to an `npc` search when you want true NPCs only.
- Verified empirically (EMU: `npc`=87, `npc nopet`=66, `npcpet`=21 → 87 = 66 + 21) and in the MQ source.

The PC side (`pc` / `pcpet` / `mercenary`) inclusion relationship was NOT verified the same way — don't assume `pc` subsumes `pcpet` without checking.
