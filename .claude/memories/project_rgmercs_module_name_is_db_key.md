---
name: rgmercs-module-name-is-db-key
description: RGMercs uses Module._name as the settings DB namespace key — renaming silently breaks saved settings
metadata: 
  node_type: memory
  type: project
  originSessionId: 83bafce2-9c95-4bc8-874b-e47249013ab4
---

In RGMercs, each module's `Module._name` field (e.g. `Module._name = "Named"` for the named module) is the namespace key used by `Config:RegisterModuleSettings` (`utils/config.lua`) to scope that module's settings in the on-disk DB. Saved values are looked up under `<Module._name>.<settingName>`.

**Why:** any rename of `Module._name` silently invalidates users' existing saved settings — values can't be found under the new key, and the module reverts to defaults without warning. Same string is also used as the dispatch key for `Modules:ExecModule("X", ...)` and `Modules.ModuleList["X"]` lookups across the repo.

**How to apply:** when contemplating a module rename or refactor that touches `_name`, treat it as a breaking DB schema change. Cheap path: rename only the user-facing label (`DisplayName`/tab header) and leave `_name` alone — fits most cosmetic-rename instincts. Full rename requires DB migration plus updating every `Modules:ExecModule("OldName", ...)` and `Modules.ModuleList["OldName"]` call site. Verify the impact via repo-wide grep before committing.
