---
name: mq-spell-and-buff-duration-quirks
description: "Two related duration quirks: Spell.MyDuration is Live-verified but base-only on EMU (confirmed — no TLO exposes the realized full there, so capture it from the song window); BuffDuration is a timestamp datatype, and permanent buffs report a NEGATIVE raw value (TotalSeconds overflows huge) — detect permanent via raw sign."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 58c1d265-d263-410c-aceb-f1d7202c5135
---

## Spell.MyDuration: Live verified, EMU base-only (confirmed)
`mq.TLO.Spell(id).MyDuration` is documented as the adjusted duration accounting for caster focus/AAs.

- **Verified Live (2026-05-02):** for bard War March of Centien (id 5376), `Spell.Duration.TotalSeconds() == 12` while `Spell.MyDuration.TotalSeconds() == 30` — bard duration AAs are properly summed in.
- **EMU: confirmed base-only (6/28/26, EQ Might + Project Lazarus).** `Spell(x).MyDuration` returns the unfocused base — `Spell("Chorus of Life").MyDuration.TotalSeconds() == 12` while the song's *realized* duration is ~20-21s. It ignores Extended Ingenuity AND the active "A Tune Stuck In Your Head" AA. The buff *instance's* MyDuration (`Me.Song(x).MyDuration`) is the SAME base value — `buff` extends `spell`, so it just reads spell data. `CachedBuff(x).OriginalDuration` is **nil for self** (CachedBuff is for targeted/remote entities only). **So no TLO exposes the realized full duration of your own song on EMU.**
- **Why:** EQEmu bakes the SPA-128 duration focus into the realized buff server-side (`AddBuff`→`GetActSpellDuration`), so the song window shows the true duration — but MQ's client-side MyDuration prediction doesn't replicate the server's focus calc.

**Apply:**
- Live: `Spell.MyDuration` is the right call — no manual summing.
- EMU: do NOT trust MyDuration for full duration, and do NOT hardcode AA-rank values (server-tuned: Laz 21s @ 5 ranks Extended Ingenuity, EQ Might 20s @ 3 ranks — and the active Tune Stuck varies it). **Capture the realized duration from the song window** — the peak `remaining` right after a (re)sing, per-cast (not a running max) so it tracks the Tune Stuck boost. Robust to server retunes; no hardcoding.
- When porting duration math Live→EMU, expect to capture rather than read MyDuration.

## Pet.BuffDuration: timestamp datatype, permanent = negative raw
`Me.Pet.BuffDuration(name|slot)` is a **timestamp datatype**, not a plain int. Bare call `()` returns remaining ms (e.g. `374415`); members `.TimeHMS` ("4:53"), `.TotalSeconds` (293), `.Seconds` are available.

**Permanent buffs (e.g. Dire Charm) report a NEGATIVE raw value** (observed `-4` for a permanent aura). The bare `()` is signed-negative, but `.TotalSeconds`/`.TimeHMS` reinterpret it as unsigned → huge garbage (e.g. "199999999999999 hours", `TotalSeconds` = 18446744073709551). So:
- **Detect "permanent / no countdown"** via the raw `dur()` sign (`< 0` = permanent), NOT `.TotalSeconds() > 0` (overflows true for permanent).
- **Display a real countdown** with `.TimeHMS()` — don't hand-roll m:ss math (user preference; explicitly said keep using TimeHMS).
- "No such buff" returns 0/nil from the bare call.

`charm.lua` `GetCharmDuration` + Render use this: raw-sign `< 0` → "Charmed (Permanent)", else `TimeHMS()`. The mq-definitions are wrong about the return type — see [[project_mq_defs_docs_pr_backlog]] entry #1. This runtime behavior persists regardless of any defs fix.
