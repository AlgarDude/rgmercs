---
name: emu-hash-gm-commands-silent
description: "EMU `/say"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 27e08510-3115-48ee-8884-30861a154eeb
---

EMU servers route GM/admin commands via `/say #cmd` (e.g. `#clearxtargets`, `#summon`), but `/say` lines starting with `#` are NOT broadcast to nearby players the way a normal `/say` is. Safe to use from scripts without spamming chat to bystanders.

Matters for: scripts that fire GM commands during play (e.g. RGMercs auto-`#clearxtargets` for stuck XTarget corpses) — no need to design around chat noise.
