---
name: RGMercs server-scoped settings powering a module's derived cache need dual invalidation
description: When a module caches state derived from a server-scoped setting, both OnChange (local writes) and a freshness check (remote writes) are required. Either mechanism alone leaves a hole.
type: project
originSessionId: 5594dfc2-1fb0-43e0-b292-4adba7edeb23
---
When module M maintains a derived cache built from a server-scoped setting S, **invalidation needs two mechanisms** — one alone is incomplete:

1. **OnChange callback on S** — invalidates M's cache via a sentinel write to M's instance state (e.g., `Modules.ModuleList["M"].LastZoneID = -1`).
2. **Freshness check inside M's refresh function** — typically a table-identity comparison: `self.LastValue ~= Config:GetSetting(S)`.

**Why both:**
- **Local writes:** `Config:SetSetting` accepts a table the caller already mutated in-place, then stores that same reference. Char A's next `GetSetting` returns the same reference Char A passed in. Identity check fails to detect the change. `OnChange` covers this — it fires on every successful `SetSetting`.
- **Cross-instance writes:** Char A writes to the shared DB. Char B's `Config` cache marks the entry stale via `data_version` polling and re-fetches on next `GetSetting`, returning a NEW table. Identity check fires re-merge on Char B. `OnChange` does NOT fire on Char B (it didn't write).

Either mechanism alone leaves a behavioral gap: OnChange-only misses cross-instance sync; identity-only misses local writes.

**Reference implementation:** `modules/named.lua` — `CustomNamedList` setting + `OnChange` writing `Modules.ModuleList["Named"].LastZoneID = -1`, paired with `Module:RefreshNamedCache` checking both `LastZoneID ~= curZone` AND `LastUserList ~= userList`.

**When this DOESN'T apply:** If the module reads the setting per-call (like pull's `Module:IsMobInList` reading `Config:GetSetting('PullDenyList')[zone]` every check), no cache exists to invalidate — both mechanisms are unnecessary. That's a valid pattern for cold-path lookups; the dual-invalidation pattern is only for hot-path derived caches where per-call reads would cost too much.

**How to apply:** When adding a new server-scoped setting consumed by a module's flattened/derived cache, mirror named's pattern. If the consumer is cold-path, drop the cache entirely and read-per-call.
