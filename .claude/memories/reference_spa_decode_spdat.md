---
name: reference-spa-decode-spdat
description: How to decode SPA effect IDs (from spells_us.txt effect slots) into readable effect names via EQEmu spdat.h
metadata: 
  node_type: memory
  type: reference
  originSessionId: 6bd26d0c-cc29-4230-926b-3ba01037ae4f
---

To turn a spell/disc's raw SPA effect IDs into readable effect names, use EQEmu's authoritative header `common/spdat.h` (the same source Spire/Lucy derive their labels from):

`https://raw.githubusercontent.com/EQEmu/Server/master/common/spdat.h` — defines every `SE_*` constant and its number (e.g. `169 = CriticalHitChance`, `185 = DamageModifier`, `186 = MinDamageModifier`, `184 = HitChance`, `178 = MeleeLifetap`). WebFetch it and ask for the specific numbers.

**Workflow** (ties into [[reference_spells_us_txt_emu_rof2_format]]):
1. From `spells_us.txt`, a spell's effect slots are fields 86-97 (the SPA/effectid per slot 1-12) with base magnitude in fields 20-31, limit in 32-43. SPA value 254 = empty slot.
2. Look up each SPA number in spdat.h to get the effect type.
3. The base magnitude's in-game scaling (e.g. CriticalHitChance base 10000) is NOT obvious from the raw value — the user reads exact magnitudes off **Spire** (running locally). spdat.h gives the effect TYPE; Spire gives the readable number.

**Local sources that do NOT work for SPA names** (checked 6/26): Spire on disk is a single compiled binary (`spire-windows-amd64.exe`, no source tree, names not greppable); `peqdump` is only SQL schema; no EQEmu server source checkout exists locally. The GitHub spdat.h fetch is the reliable path.
