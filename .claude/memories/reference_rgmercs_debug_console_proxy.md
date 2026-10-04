---
name: rgmercs-debug-console-proxy
description: "RGMercs debug console wraps modules in __index proxies — writes don't reach the real module, reads through proxy can be stale"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 27e08510-3115-48ee-8884-30861a154eeb
---

RGMercs's debug-window Lua tab sandboxes script execution via `modules/debug.lua:Module:Exec`. Module references inside the script are `__index` proxy tables, e.g.:

```lua
locals.Targeting = setmetatable({}, { __index = require('utils.targeting'), })
locals.Globals   = setmetatable({}, { __index = Globals, })
-- ... same pattern for Config, Core, Casting, Combat, Comms, etc.
```

**Gotcha:** writes to the proxy DO NOT propagate to the real module — they `rawset` on the proxy table only. Reads through the proxy then return the proxy-local value, masking the real module's actual state.

```lua
-- BROKEN diagnostic pattern:
Targeting.XTClearTime = 0                  -- rawsets on proxy
Targeting.ClearStuckXTargets()             -- helper updates REAL module
printf(tostring(Targeting.XTClearTime))    -- reads proxy → still 0 (misleading)
```

**Fix:** grab a direct reference to the real module for read/write to module state:

```lua
local real = require('utils.targeting')
real.XTClearTime = 0
Targeting.ClearStuckXTargets()
printf(tostring(real.XTClearTime))         -- correct
```

Function calls through the proxy still work fine (the function itself uses its own lexical `require`d references, not the proxy). The pitfall only applies to reading/writing module fields directly from a debug console script.
