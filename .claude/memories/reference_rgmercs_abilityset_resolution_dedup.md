---
name: rgmercs-abilityset-resolution-dedup
description: RGMercs AbilitySet resolution dedupes discs/spells across sets — two sets can NEVER both resolve to the same ability; design conditional sets with disjoint contents
metadata: 
  node_type: memory
  type: reference
  originSessionId: 3fc3fe6f-7bcc-4edc-ae3b-29b87cbbb937
---

In RGMercs, `Rotation.ResolveActions` (utils/rotation.lua) builds `ResolvedActionMap` by calling `Rotation.GetBestSpell(spellTable, alreadyResolvedMap)` for each AbilitySet **in alphabetically-sorted set-name order**, passing the accumulating map. `GetBestSpell` **skips any candidate whose spell ID already appears in the map** (the `alreadyUsed` loop). 

**Consequence:** two AbilitySets that both list the same disc/spell will NOT both resolve to it — the alphabetically-earlier set name claims it, and the later set falls through to its next-best entry (or resolves to nil if nothing's left). 

**So you cannot make a "Warden vs non-Warden" (or any conditional) pair of sets that share discs** — e.g. `StrikeDisc {Mighty Blow, Mighty Strike}` + `StrikeDiscWarden {Mighty Blow, Mighty Strike}` is broken: the second resolves to Mighty Strike (or nil) because the first claimed Mighty Blow.

**Correct pattern (used for EQ Might Warrior strike discs):** partition so each ability lives in exactly ONE set. Put the shared/baseline abilities in one set used by everyone, and the conditional-only ability in its own disjoint set. Then express priority/exclusion in the rotation entry `cond` (runtime), e.g. fire the optional disc only when `discSpell.Level() > Core.GetResolvedActionMapItem('OtherSet').Level()`. Order the optional-disc entry before the baseline entry so it wins in its window.

**Also:** a disc-type rotation entry's `cond` is only evaluated when its resolved action is non-nil (rotation.lua: `if condArg ~= nil then pass = ...`), so conds may safely deref `discSpell` (e.g. `discSpell.Level()`) without a nil guard.

Related: [[project_rgmercs_module_instance_shadowing]] (reach modules via Core/Modules accessors, used here for `Core.GetResolvedActionMapItem`).
