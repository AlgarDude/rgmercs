---
name: reference-eqemu-cast-los-not-facing
description: "EQEmu (EMU RoF2, e.g. EQ Might / Project Lazarus) casting requires LINE OF SIGHT only, never facing/heading. Taunt requires melee range, no facing/LoS, and fails SILENTLY."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 63c275cb-c100-4191-bd48-67bb47e6c07a
---

Verified against EQEmu server source (the emulator EQ Might / Project Lazarus run). Settles "does X require facing or LoS" for EMU.

## Detrimental spells / AAs / discs / clicky items — LoS ONLY, no facing
`zone/spells.cpp` `SpellFinished()` is the only directional gate. For a detrimental spell it checks a geometric raycast and nothing about heading:
```cpp
if (!spells[spell_id].npc_no_los && spell_target && IsDetrimentalSpell(spell_id) &&
    (!CheckLosFN(spell_target) || !CheckWaterLoS(spell_target)) && ...) {
    MessageString(Chat::Red, CANT_SEE_TARGET);   // "You cannot see your target."
    return false;
}
```
- `CheckLosFN` = position geometry (is something between you and the spawn), **independent of which way you face**.
- So "You cannot see your target." is purely an **obstruction/LoS** failure. Being "faced away" never causes it. `/face` cannot fix a LoS-blocked cast — only **repositioning** clears the line.
- `Spawn.LineOfSight` (MQ TLO) is the same geometric raycast.

## Taunt — effective range = melee CombatRange, no facing, no LoS
Read the full source (don't trust the `MaximumTauntDistance=150` rule name — it's a red herring). Player path:
- `zone/client_packet.cpp` `Handle_OP_Taunt`: starts the reuse timer, then gates `DistanceSquared > MaximumTauntDistance²` (150) → on fail emits `TAUNT_TOO_FAR`. Then calls **`Taunt(GetTarget()->CastToNPC(), false)`** (`always_succeed=false`, `from_spell` defaults false).
- `zone/special_attacks.cpp` `Mob::Taunt(NPC*, bool always_succeed, int chance_bonus, bool from_spell, int32 bonus_hate)`: guard `if (!who || DivineAura() || (!from_spell && !CombatRange(who)) || (IsNPC() && IsCharmed())) return;`. With `from_spell=false`, **melee `CombatRange` is required**.

So the **effective player taunt range = melee `CombatRange`** on EMU AND Live. The 150 is a non-binding outer cap — between `CombatRange` and 150, `Taunt()` returns **silently** (no message, no chase); only past 150 do you get `TAUNT_TOO_FAR`. In-game Live test confirmed: taunt works to ~`MaxRangeTo + 3` (MQ client `MaxRangeTo` runs a hair under server `CombatRange`), and fails silently beyond.

**Two gotchas:** (1) the reuse timer is started BEFORE the range check, so an out-of-range taunt **burns the cooldown** for nothing — gate taunt attempts by range. (2) No facing, no LoS in any taunt path.

RGMercs implication (6/26): `Casting.AbilityReady` previously EXEMPTED `"taunt"` from the `MaxRangeTo` check on the false belief taunt was long-range — WRONG. Correct approach: drop the exemption and gate taunt by `MaxRangeTo` like any melee ability (accepting a ~3-unit client/server `MaxRangeTo`-vs-`CombatRange` false-negative band); remove magic `< 30` taunt distance conds in the tank `HateTools` rotations.

## Exception worth remembering
Frontal-cone spells (spell-file `ConeStartAngle`/`ConeStopAngle`) DO care about the target being in your forward arc — the one class of effect where bearing matters. Ordinary hate/taunt tools are not cones.

## Why this matters for RGMercs
The tank `HateTools(AggroTarget)` rotation swaps target to the aggro mob and casts hate tools. When one LoS-fails, the only thing that would make it land is moving the tank off the main target to clear the line - which is the unwanted "chase" behavior. So **skip-on-fail is correct**, and adding `/face` (pre/post_activate or in the CantSee/TooFar handlers) does nothing for landing any of these tools. See [[reference_spells_us_txt_emu_rof2_format]] for the spell-file field map.

Sources: github.com/EQEmu/Server `zone/spells.cpp`, `zone/special_attacks.cpp`.
