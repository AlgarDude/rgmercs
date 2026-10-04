---
name: rgmercs-external-callbacks-via-execmodule
description: "External callbacks (esp. OnChange) reach other modules via Modules:ExecModule(\"X\",\"Method\"). OnChange has NO self — it's a bare call (oldValue, newValue), often misnamed `self` in the wild."
metadata: 
  node_type: memory
  type: project
  originSessionId: 58c1d265-d263-410c-aceb-f1d7202c5135
---

## Reach other modules via Modules:ExecModule
Every RGMercs module is a singleton — `Modules:load()` / `Modules:loadModule()` (`utils/modules.lua`) call `require("modules.X"):New()` exactly once and store the instance at `Modules.ModuleList[name]`. So for any module file in `modules/`, exactly one instance exists, always reachable via the registry.

**Preferred cross-module call:** `Modules:ExecModule("X", "Method", ...)` — the sanctioned dispatch used in `utils/binds.lua`, `utils/combat.lua`, and by `SetSetting`'s `RequiresLoadoutChange` → `Modules:ExecModule("Class", "RescanLoadout")`. It hides the `ModuleList` indexing and passes the instance as `self`.

**Field pokes get wrapped, not reached.** ExecModule dispatches methods only — for a field write from outside a module, give the module a small method that does the write (plus any refresh) and dispatch that, keeping the field private:
```lua
function Module:InvalidateNamedList()
    self.LastZoneID = -1
    self:RefreshAutoTargetProfile()
end
-- in DefaultConfig (Named's, or even Core's UseImmuneData — cross-module is the same call)
OnChange = function() Modules:ExecModule("Named", "InvalidateNamedList") end,
```

`Modules.ModuleList["X"].field` (direct read) is fine when you genuinely need an inline READ that can't be a method call. Add `local Modules = require("utils.modules")` to the file if not imported.

## Why ExecModule is mandatory: OnChange has NO `self`
A setting's `OnChange` is fired as a **bare call** `OnChange(oldValue, cleanValue)` (`utils/config.lua`'s `SetSetting`) — NOT a method call. So there is no `self` to use inside an `OnChange`, regardless of being lexically "in" the module file.

**Misleading precedent in the wild:** some entries write `OnChange = function(self) ... end` — that first param is actually `oldValue`, just badly named; they never read it. Honest examples name them `function(oldVal, newVal)` / `function(_, _)` / `function(_, newValue)`. Dispatch to the owning module via `Modules:ExecModule("X", "Method")`; the method body then has a real `self`.

Related: [[project_rgmercs_module_name_is_db_key]] (Module._name is also the dispatch key for ExecModule/ModuleList).
