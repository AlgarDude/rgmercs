---
name: ward-of-might-warden-discipline-swaps
description: EQ Might Ward of Might damage-mod values by rank and the principle for swapping melee disciplines on Wardens vs non-Wardens
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6bd26d0c-cc29-4230-926b-3ba01037ae4f
---

"Warden" = a character with an advanced Ring of the Warden, which casts the **Ward of Might** buff. Detected by `Core.IsWarden()` in `utils/core.lua` (checks `Me.Buff("Ward of Might")` — partial match catches every rank/variant). Gate warden-only logic with a runtime `cond` (the buff can drop mid-fight), never `load_cond`.

**Ward of Might provides SPA 185 (DamageModifier) across all melee skills:**
- Ward of Might (Rk I, id 42894): **+112**
- Ward of Might Rk. II (42895): **+168**
- Ward of Might Rk. III (43115): **+224**

It has **no** SPA 186 (MinDamageModifier). Variants "Raw Ward of Might" (43028) and "Pure Ward of Might" (43116) also exist; all share the base name "Ward of Might".

**Swap principle:** a discipline's DamageModifier (SPA 185) does NOT stack with Ward of Might's — only the highest applies. So any disc whose primary value is SPA 185 (and largely SPA 186) is dead weight on a Warden once Ward of Might is up (already +112 at Rk I). On Wardens, prefer the alternative disc with a *different* mechanic (e.g. CriticalHitChance/SPA 169). Non-Wardens may still want the damage-mod disc — most pronounced for Rogues per the 6/5/26 notes. This principle drives the Warden disc swaps for Bst/Ber/Mnk/Rog/War.

Decode disc effect slots via [[reference_spa_decode_spdat]]; group shared-timer discs via EndurTimer (spells_us.txt field 167) per [[reference_spells_us_txt_emu_rof2_format]].
