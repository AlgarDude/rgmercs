---
name: eq-clearxtargets-behavior
description: "EMU GM `#clearxtargets` — what it wipes, what persists, and how to make slots repopulate afterward"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 27e08510-3115-48ee-8884-30861a154eeb
---

EMU GM command `/say #clearxtargets` (works for all players on most EMU servers, see [[reference_emu_hash_gm_commands_silent]]):

- **Wipes**: every slot's populated entry — every `XTarget(i).ID()` becomes 0, every `Name()` becomes empty. Includes user-configured non-corpse entries too, not just bugged Auto Hater corpses.
- **Persists** (TargetType survives): Auto Hater, Empty Target, Specific PC, dynamic role types (Group Tank, Group Assist, Group Puller, Raid Assist N, Pet Target, *_Target variants, marks, etc.).
- **DOES NOT persist** (TargetType reverts to Auto Hater): **Specific NPC**. EMU server resets this type when its bound spawn is cleared, including via `#clearxtargets`. Verified 6/26 with both town NPCs and combat-able NPCs.

**Repopulation behavior after wipe:**
- Auto Hater: auto-fills again from next aggro.
- Specific PC: TargetType preserved, name wiped — reissue `/xtarget set N "name"` (best: by ID via `Targeting.AddXTByID` while spawn is in zone; offline PCs cannot be restored, slot stays empty Specific PC).
- Specific NPC: TargetType GONE (reverted to Auto Hater) — restoration cannot rely on reading current TargetType post-wipe; must drive off a pre-wipe snapshot. `Targeting.ClearStuckXTargets`'s restore loop branches on `idSnap[i]` instead of current TargetType for this reason.
- Dynamic role types: slot type persists but the resolver does NOT re-fire. Must toggle to a different type and back (e.g. `/xtarget set N emptytarget` then `/xtarget set N grouptank`) to force resolution.

**Full `/xtarget set N <keyword>` vocab** is verified and stored in code at `rgmercs/utils/targeting.lua` `Targeting.XTargetTypeKeywords` — covers all 21 TargetType values from the XTarget TLO docs (group/raid + *'s Target variants included). Specific PC/NPC use `"name"` directly.

Implementation lives in `Targeting.ClearStuckXTargets()` (EMU + Downtime gated, fires only when a stuck corpse — `TargetType == "Auto Hater"` AND `Type() == "Corpse"` — is detected); see [[project_rgmercs_dirs]].
