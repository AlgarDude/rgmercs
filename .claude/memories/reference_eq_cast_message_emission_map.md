---
name: reference-eq-cast-message-emission-map
description: "What emits a catchable 'You begin casting' vs what's silent on RoF2/EMU: spells + items + spell-triggering AAs announce; disciplines + pure-effect AAs are silent."
metadata: 
  node_type: memory
  type: reference
  originSessionId: de30caa0-1393-4395-9278-c87922083613
---

Empirical map (RoF2 / EQ Might, 7/3/26) of what emits the catchable "You begin casting" line vs what's silent to RGMercs' event handler:

**Announce "You begin casting" (catchable):**
- **Spells** - client-side, ~16ms. See [[reference_eq_cast_message_client_vs_server]].
- **Items / clickies** - server-side, ~250ms. Every item tested announced.
- **AAs that trigger a spell** - e.g. warrior Blast of Anger / Area Taunt / Knee Strike all print "You begin casting" (verified from eqlog).

**Silent - no catchable "You begin casting":**
- **Disciplines** - do not emit it on EMU. This is why disc confirmation keys off `Me.ActiveDisc`/cooldown, never a message.
- **Pure-effect instant AAs** (no triggered spell) - e.g. bard Selo's Sonata fires with no cast message at all.
- Some "silent" abilities actually emit a DIFFERENT line the `You begin casting` handler doesn't match - e.g. Boastful Bellow has a custom `you_cast` field ("You shout loudly at your opponent.") in spell data (field 4), so it announces something, just not the catchable line.

The exact server rule for which abilities announce is NOT pinned down - a "cast_time>0 && slot!=Discipline" theory did NOT hold (warrior AAs with cast_time 0 still announced). Trust the observable map, not a derived rule. The reliable structural signal for "slot-occupying disc" stays `Casting.IsActiveDisc`.

**You cannot read these messages from the Spell TLO on EMU.** `mq.TLO.Spell(x).CastOnYou` / `.CastOnAnother` / `.WearOff` return placeholder junk ("You feel bogus as an unknown spell accosts you.", " is the victim of an unknown spell.", "An unknown spell is gone.") for the abilities checked - the real strings live in the client's spell string file, not where the TLO reads. So message-based detection can't be built from the TLO; catch the actual in-game chat event instead (`mq.event` + scoped `mq.doevents`). Also note bare `mq.TLO.Spell("name")` resolves ranked AAs to the wrong entry - resolve via the AA (`Me.AltAbility(name).Spell`).

Related: [[reference_rgmercs_instant_cast_confirm]], [[reference_spells_us_txt_emu_rof2_format]] (field 4 = you_cast, field 6 = cast_on_you).
