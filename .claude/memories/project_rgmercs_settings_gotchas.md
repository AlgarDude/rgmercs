---
name: rgmercs-settings-gotchas
description: "Three settings-system gotchas not visible from casual code reading: GetSetting returns nil (not Default) for unseeded keys; DefaultConfig Index must be unique within a (Header,Category); the unified search input searches setting key + DisplayName + Tooltip and (via FAQ's own filter on the same input) FAQ text — preserve search keywords when renaming."
metadata: 
  node_type: memory
  type: project
  originSessionId: 58c1d265-d263-410c-aceb-f1d7202c5135
---

## GetSetting returns nil for never-seeded keys (silent crash trap)
`Config:GetSetting` calls `GetTempSetting` (in-memory, normally nil until written), then `SettingDbRead`, returning whatever the DB read returned. If the key isn't in the DB yet, it returns **nil** — does NOT fall back to the `Default` field of `DefaultConfig`. Defaults only become readable *because* a separate seed step (`ResolveDefaults` → `SaveModuleSettings`) writes them to the DB during module load.

**Trap:** a reader that does `Config:GetSetting('NewList')[zoneKey]` will index nil and crash if it runs before seeding completes, or if you bypass the seed path. Guard table-typed reads (`(Config:GetSetting('X') or {})[...]`) or trust the seed — but never assume `GetSetting` itself supplies the `Default`.

(Adding a setting needs no migration — the seed step handles existing users correctly. That part IS visible from the code; the nil-trap is the silent failure mode.)

Related: [[project_rgmercs_module_instance_shadowing]] (OnChange-has-no-self), [[project_rgmercs_server_scoped_cache_invalidation]] (cross-instance sync).

## DefaultConfig Index must be unique within a (Header,Category)
Settings within a (Header, Category) are sorted by `Index` ascending, then by `DisplayName` alphabetical, then by `Category` (the `ui/options.lua` comparator). A duplicate `Index` silently falls back to `DisplayName` — the colliding entries drop out of their chosen slot into alphabetical order.

**User convention:** rely strictly on Index — every Index must be unique within its (Header, Category). A duplicate is a defect, not harmless. When adding/inserting, give the entry a unique Index and renumber trailing entries to keep the sequence unique and contiguous. Treat any existing collision as a latent defect to clean up, not precedent to copy.

## Settings search input is text-searched across multiple fields
The settings UI search input drives `self.configFilter`, which feeds **two** filters sharing the same text:
- The main settings filter loop (in `ui/options.lua`'s setting-filter pass that builds `FilteredSettingsByCat`) matches against: **setting key**, **DisplayName**, **Tooltip** — and also header + category names.
- The FAQ section is a separate RenderCategory whose `Search` callback feeds the same `configFilter` to `Modules:ExecModule("FAQ", "SearchMatches", ...)`, which scans **FAQ Question and Answer text**.

From the user's perspective, typing in the search box surfaces a setting via ANY of: key, DisplayName, Tooltip, OR FAQ text describing it. So name/text choices have direct discoverability consequences.

**Why this matters:** during the immunity-tracking feature, the user renamed the registry-merge setting through three names — `UseImmuneList` → `UseBuiltInImmunities` → `UseDefaultImmunities` (rejected) — and picked `UseImmuneData` specifically because "filter for 'immune' will not bring this setting up." The word `immune` had to stay in the key.

**Apply:**
- When naming/renaming a setting, keep at least one obvious search keyword in the setting key. DisplayName usually mirrors the key, inheriting the keyword.
- Tooltip and FAQ text get the same treatment: enumerations of element names, effect names, command names are load-bearing for discoverability, not bloat.
- Cosmetic concision is welcome, but never at the cost of stripping the noun the user would search for.

Related: [[feedback_faq_style]] established this principle for FAQ text.
