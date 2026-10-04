---
name: rgmercs-require-order
description: "Require-block ordering in RGMercs Lua files: mq first, then ImGui, then internal utils.* alphabetically"
metadata: 
  node_type: memory
  type: project
  originSessionId: be672dd2-fe6e-4170-b7a8-c722d3623f6c
---

The `require` block at the top of an RGMercs file follows a fixed order (aspirational - not every existing file conforms, but newly added/edited requires SHOULD):

1. `mq` and `mq.*` (e.g. `require('mq')`, `require('mq.set')`)
2. ImGui (`require('ImGui')`)
3. Project internals (`utils.*` and other project modules), listed ALPHABETICALLY by variable/module name.

When adding a require, insert it in the correct alphabetical slot among the internals - do NOT append at the end. Example (item_manager.lua internals, correct order): Comms, Config, Core, Globals, Logger, Movement, Targeting.
