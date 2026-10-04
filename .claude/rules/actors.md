---
paths:
  - "utils/comms.lua"
  - "modules/base.lua"
---

# Actors (IPC)
- **Actors broadcast across all MQ instances on the network, including different servers** — two MQ installations on the same machine (Live + EMU) will receive each other's actor messages. Always include `server = mq.TLO.EverQuest.Server()` in every broadcast and filter on it in the message handler. Add zone filtering when behavior is zone-specific (combat, pet arming); omit it for global use cases.
- Cache server name at module load: `local myServer = mq.TLO.EverQuest.Server() or ""`
- Filter pattern: `if content.server ~= myServer then return end` / `if content.zoneId ~= (mq.TLO.Zone.ID() or 0) then return end`
