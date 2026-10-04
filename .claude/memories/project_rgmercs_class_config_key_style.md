---
name: rgmercs-class-config-table-key-style
description: RGMercs class-config named tables use bracket-string keys; only list elements use bare keys
metadata: 
  node_type: memory
  type: project
  originSessionId: 86ae69c5-c7a8-48b2-95c8-3a271888d149
---

In RGMercs class config files (`class_configs/**/*_class_config.lua`), **named tables use
bracket-string keys**: `['Mez']`, `['AASets']`, `['RotationOrder']`, and nested named sub-tables too
(`['AASets'] = { ['ManaRestore'] = { ... } }`). Only the **array elements** inside those tables use
bare-key tables — the ability/rotation entries like `{ type = "AA", name = "Stasis", cond = function() ... end, }`.

So when adding a new named config table or a container with named sub-lists, use `['Name'] = { ... }`,
not bare `Name = { ... }`. Example (charm container): `['Charm'] = { ['Abilities'] = {...}, ['Tash'] = {...}, ['Assist'] = {...}, }`.

**Why:** matches the established layout; the user has had to point this out repeatedly. Keeps configs
visually consistent and greppable. Related: [[project_rgmercs_settings_gotchas]] (Index must be unique),
[[project_rgmercs_require_order]].
