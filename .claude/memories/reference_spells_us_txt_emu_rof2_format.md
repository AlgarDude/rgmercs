---
name: reference-spells-us-txt-emu-rof2-format
description: "Field map for EMU RoF2-client spells_us.txt (237 fields). Applies to all current EMU servers (EQ Might, Project Lazarus, etc.). Live uses a DIFFERENT 166-field format — not covered here."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 4a68fb18-01cf-42b9-b10b-9064c065629d
---

# EMU RoF2 spells_us.txt field map (237 fields)

**Scope:** All EMU servers currently shipping the **RoF2 client** (EQ Might, Project Lazarus, and any other EMU server using RoF2). **Live is a different schema** (166-field classic format) — see [[project_rgmercs_spell_list_sort_procedure]] for the Live mapping; this memory is RoF2-only.

**Authoritative source:** [EQEmuTools/spire](https://github.com/EQEmuTools/spire) — `internal/models/spells_new.go` defines the column order; `internal/clientfiles/export.go` simply joins those columns with `^` and newlines, producing spells_us.txt verbatim. If the schema ever changes, re-derive from that Go file.

**User has Spire running locally** — for ad-hoc queries, the user prefers to use their own Spire UI rather than ask Claude to grep the file. Only do PowerShell lookups when explicitly asked.

## Format basics

- One spell per line, fields `^`-delimited, **237 fields per row** (indices 0-236)
- Indexing below is **0-based**, matching PowerShell `$f = $line -split '\^'` (so `$f[0]` is id, `$f[1]` is name, etc.)
- 12 effect slots: each slot has a `base`, `limit`, `max`, `formula`, and `effectid` (SPA) value, stored as 5 parallel arrays
- 16 classes (1-16 = War, Clr, Pal, Rng, Shd, Dru, Mnk, Brd, Rog, Shm, Nec, Wiz, Mag, Enc, Bst, Ber); value 255 = uncastable

## Full field index

| Index | Name | Notes |
|---|---|---|
| 0 | id | spell ID |
| 1 | name | spell name |
| 2 | player_1 | |
| 3 | teleport_zone | |
| 4 | you_cast | message when you cast |
| 5 | other_casts | message when another casts |
| 6 | cast_on_you | landed-on-you message |
| 7 | cast_on_other | landed-on-other message |
| 8 | spell_fades | fade message |
| 9 | range | |
| 10 | aoerange | |
| 11 | pushback | |
| 12 | pushup | |
| 13 | cast_time | milliseconds |
| 14 | recovery_time | ms |
| 15 | recast_time | ms |
| 16 | buffdurationformula | duration calc formula (see EQEmu source for formula table) |
| 17 | buffduration | duration input (interpretation depends on formula) |
| 18 | AEDuration | |
| 19 | mana | |
| 20-31 | effect_base_value 1-12 | slot base value (e.g. damage; negative = HP decrease) |
| 32-43 | effect_limit_value 1-12 | slot base2 / limit |
| 44-55 | max 1-12 | slot max (cap on scaled value) |
| 56 | icon | |
| 57 | memicon | |
| 58-61 | components 1-4 | reagent item IDs |
| 62-65 | component_counts 1-4 | reagent counts |
| 66-69 | NoexpendReagent 1-4 | focus item IDs (not consumed) |
| 70-81 | formula 1-12 | per-slot scaling formula |
| 82 | LightType | |
| 83 | goodEffect | |
| 84 | Activated | |
| 85 | resisttype | 0=unresistable, 1=magic, 2=fire, 3=cold, 4=poison, 5=disease, 6=chromatic, 7=prismatic, 8=physical, 9=corruption (verify against EQEmu source) |
| 86-97 | effectid (SPA) 1-12 | per-slot effect type — SPA number defines what the slot does (HP decrease, stun, heal, etc.) |
| 98 | targettype | |
| 99 | basediff | |
| 100 | skill | |
| 101 | zonetype | |
| 102 | EnvironmentType | |
| 103 | TimeOfDay | |
| **104-119** | **classes 1-16 (levels)** | **War=104, Clr=105, Pal=106, Rng=107, Shd=108, Dru=109, Mnk=110, Brd=111, Rog=112, Shm=113, Nec=114, Wiz=115, Mag=116, Enc=117, Bst=118, Ber=119. Value 255 = uncastable.** |
| 120 | CastingAnim | |
| 121 | TargetAnim | |
| 122 | TravelType | |
| 123 | SpellAffectIndex | |
| 124 | disallow_sit | |
| 125-141 | deities 0-16 | 17 entries (deities0 through deities16) |
| 142 | field_142 | unknown / reserved |
| 143 | field_143 | unknown / reserved |
| 144 | new_icon | |
| 145 | spellanim | |
| 146 | uninterruptable | |
| 147 | ResistDiff | resist modifier |
| 148 | dot_stacking_exempt | |
| 149 | deleteable | |
| 150 | RecourseLink | spell ID cast on caster after this spell |
| 151 | no_partial_resist | |
| 152 | field152 | unknown |
| 153 | field153 | unknown |
| 154 | short_buff_box | song window flag |
| 155 | descnum | |
| 156 | typedescnum | |
| 157 | effectdescnum | |
| 158 | effectdescnum2 | |
| 159 | npc_no_los | |
| 160 | field160 | unknown |
| 161 | reflectable | |
| 162 | bonushate | |
| 163 | field163 | unknown |
| 164 | field164 | unknown |
| 165 | ldon_trap | |
| 166 | EndurCost | |
| 167 | EndurTimerIndex | |
| 168 | IsDiscipline | 1 if discipline, 0 if spell |
| 169-172 | field169-172 | unknown |
| 173 | HateAdded | |
| 174 | EndurUpkeep | |
| 175 | numhitstype | |
| 176 | numhits | |
| 177 | pvpresistbase | |
| 178 | pvpresistcalc | |
| 179 | pvpresistcap | |
| 180 | spell_category | |
| 181 | pvp_duration | |
| 182 | pvp_duration_cap | |
| 183 | pcnpc_only_flag | |
| 184 | cast_not_standing | |
| 185 | can_mgb | mass group buff allowed |
| 186 | nodispell | |
| 187 | npc_category | |
| 188 | npc_usefulness | |
| 189 | MinResist | |
| 190 | MaxResist | |
| 191 | viral_targets | |
| 192 | viral_timer | |
| 193 | nimbuseffect | |
| 194 | ConeStartAngle | |
| 195 | ConeStopAngle | |
| 196 | sneaking | |
| 197 | not_extendable | |
| 198-199 | field198-199 | unknown |
| 200 | suspendable | |
| 201 | viral_range | |
| 202 | songcap | |
| 203-204 | field203-204 | unknown |
| 205 | no_block | |
| 206 | field206 | unknown |
| 207 | spellgroup | groups ranks (Rk. I/II/III share a group) |
| 208 | rank | 1/2/3 for Rk. I/II/III |
| 209-210 | field209-210 | unknown |
| 211 | CastRestriction | |
| 212 | allowrest | |
| 213 | InCombat | |
| 214 | OutofCombat | |
| 215-217 | field215-217 | unknown |
| 218 | aemaxtargets | |
| 219 | maxtargets | |
| 220-223 | field220-223 | unknown |
| 224 | persistdeath | |
| 225-226 | field225-226 | unknown |
| 227 | min_dist | float |
| 228 | min_dist_mod | float |
| 229 | max_dist | float |
| 230 | max_dist_mod | float |
| 231 | min_range | |
| 232-236 | field232-236 | unknown / reserved |

## Calibration spot-checks (against EQ Might spells_us.txt)

- **Dread Pyre** (id 7994, necro DoT): `effect_base_value1` (field 20) = `-956` matches the in-game tooltip "decreases HP by 956". Confirms field 20 = slot 1 damage magnitude (negative for HP decrease).
- **Complete Heal** (cleric 39): field 105 (clr) = 39. Confirms class-level offsets.
- **Spirit of Wolf** (rng 28, dru 10, shm 9, bst 24): field 107=28, 109=10, 113=9, 118=24. Confirms class slot order.

## "field_NNN" entries

The Go model has many `Field142`, `Field143`, ... `Field236` columns where EQEmu hasn't named the field. These still hold values in the file (often 0) and are part of the 237-field row. Don't strip them — preserve verbatim when reading/writing.

## Cross-references

- [[project_rgmercs_spell_list_sort_procedure]] — uses this format (specifically the 104-119 class levels) for sorting `AbilitySets`. That memory also has the Live 166-field offsets (war=36 ... ber=51) for comparison.
- [[reference_mq_spell_duration_quirks]] — duration accounting quirks on EMU vs Live, related to fields 16-17.
