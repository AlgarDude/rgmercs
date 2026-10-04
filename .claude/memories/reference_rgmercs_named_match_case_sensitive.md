---
name: reference_rgmercs_named_match_case_sensitive
description: RGMercs named-list mob-name matching is exact/case/punctuation-sensitive; zone keys are lowercased but mob names are not
metadata: 
  node_type: memory
  type: reference
  originSessionId: af621692-24e3-4720-9f98-5c5548786f83
---

In `modules/named.lua`, named detection is a raw Lua table lookup by the spawn's exact name:
`self.NamedList[spawn.Name()] or self.NamedList[spawn.CleanName()] or self.NamedList[cleanNameFixed]`. `IngestDefEntry` stores entries keyed by the name string verbatim. So **mob-name matching is case- AND punctuation-sensitive** — `"Magi P`Tasa"` ≠ `"Magi P`tasa"`, and `"Ambassador DVinn"` ≠ `"Ambassador D`Vinn"`. Only the ZONE keys are lowercased (RefreshNamedCache `:lower()`s `Zone.Name()`/`Zone.ShortName()`), not the mob names.

Consequences for named-list data: a miscased or wrong-separator entry is a **dead entry that never matches**. This is why PEQ-vs-revamp spelling variants can BOTH be valid distinct NPCs that both belong in the list (e.g. classic `Magi P`Tasa` npc 6623 + TBM-Revisited `Magi P`tasa` npc 50203; classic `Ambassador DVinn` npc 356 with no separator + later `Ambassador D`Vinn` npc 37913).

IMPLEMENTATION TODO (user's plan): when wiring the named-list restructure, decide whether to make matching case-INsensitive (`:lower()` both sides at the lookup + IngestDefEntry keys + RefreshNamedCache). If done, all CASE discrepancies become moot. CAVEAT: `:lower()` does NOT collapse SEPARATOR diffs (`"DVinn":lower()` ≠ `"d`vinn"`) — those still need both entries unless matching also strips `` ` ``/`'`/`-`. See the named-list restructure plan for the wiring decision.
