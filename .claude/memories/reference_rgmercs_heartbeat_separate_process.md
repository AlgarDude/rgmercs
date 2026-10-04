---
name: reference-rgmercs-heartbeat-separate-process
description: "RGMercs heartbeat runs in a separate Lua process; reading main-process runtime globals needs the RGMercs.Globals() bridge, which only carries scalars"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 86ae69c5-c7a8-48b2-95c8-3a271888d149
---

`heartbeat.lua` (the `rgmercs/heartbeat` script, its own PID) is a SEPARATE Lua process from main rgmercs. It `require`s `utils.globals` so it has its OWN `Globals` table that the main loop never populates — `Comms.SendHeartbeat` (called only from `heartbeat.lua`) runs there. The split is intentional so a peer can broadcast status without running full rgmercs.

So any RUNTIME-mutated main-process global the heartbeat needs must be read via the cross-process bridge `mq.TLO.RGMercs.Globals("Name")()` (see `AutoTargetID`/`ForceTargetID` in `SendHeartbeat`), NOT `Globals.Name` directly (that reads the heartbeat process's always-init copy).

The bridge (`utils/datatypes.lua` `rgMercsMainType.Globals`) returns SCALARS ONLY: bool/int direct, and a table comes back as a `Strings.TableToString` string (not a Lua table) - so don't bridge tables. Broadcast single scalar ids and let the receiver aggregate. Charm does exactly this: each PC has ONE charm, so it stages a single `Globals.MyCharmedPetID` / `MyLooseCharmID` (int), bridged like `ForceTargetID`; `RebuildPeerCharmData` unions the per-peer scalars into `Globals.CharmedPetIDs` (Set) / `LooseCharms` (map). Don't model per-PC charm data as a list - a PC only ever holds one charm.

Bug this caused: charm peer-protection + loose-charm assist read `Globals.MyCharmedPetIDs` directly in `SendHeartbeat` (heartbeat process's empty copy) → always empty over the wire → only the charmer protected its own charm; other boxes' MA auto-targeted and killed a broken charm. See [[project_rgmercs_module_instance_shadowing]].
