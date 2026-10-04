---
name: mq-state-check-gotchas
description: "Three TLO state-check idioms that silently fail wrong: BuffsPopulated flickers/stale on target change, Me.Casting.ID() is nil (not 0) off-cast, and EQ instants don't open a casting window."
metadata: 
  node_type: memory
  type: reference
  originSessionId: 58c1d265-d263-410c-aceb-f1d7202c5135
---

## Target.BuffsPopulated unreliable on target change
Right after switching targets, `mq.TLO.Target.BuffsPopulated()` can't be trusted to mean "the NEW target's buffs have actually loaded." It may flicker, or — suspected but not confirmed — momentarily remain/report true, carrying the previous target's populated state before new buff data arrives.

**Apply:** don't gate a buff/mez read on `BuffsPopulated()` immediately after a target switch — poll the specific datum you need instead (e.g. `Target.Mezzed.ID()` for mez detection). Which of flicker-vs-stale-true it is remains unverified; testable by logging `BuffsPopulated()` across rapid target changes.

## Casting check: use `not Me.Casting()`, NOT `Casting.ID() == 0`
House idiom for "not currently casting": `not mq.TLO.Me.Casting()`. The bare `Casting()` returns the casting spell name when casting, nil when idle, so `not` gives a clean bool. Used throughout combat.lua, mez.lua, move.lua, class.lua.

**Trap:** `mq.TLO.Me.Casting.ID()` returns **nil**, not 0, when not casting. So `Me.Casting.ID() == 0` is a silent always-false bug (never true off-cast). This shipped once in the queued-autoinv work and stopped the stow from ever firing — symptom was "feature does nothing." If you must use `.ID()`, guard it: `(mq.TLO.Me.Casting.ID() or 0) == 0` or check `== nil`. Confirmed by `class.lua` (`Casting.ID() == nil`) and `casting.lua` (`Casting.ID() or -1`).

## EQ instants don't open a casting window
Instant abilities (0 cast time — AAs, discs, items, /doability) do NOT open a casting window at all. Even some very-low-cast abilities don't, due to server latency. (EQ-mechanics, user-supplied.)

**Apply:** any logic keying off `mq.TLO.Window("CastingWindow").Open()` or `mq.TLO.Me.Casting()` to mean "I'm busy" is unaffected by firing an instant — the instant doesn't touch those signals. This is what makes it safe to fire instant AAs/discs/items concurrently with a bard song (the song's casting window stays the sole controller of that signal) and is the mechanical basis for the bard mid-song thin-fire approach (DoMidSong / DoMidSongEngage in the Class module, shipped). Conversely, do NOT expect an instant to set `Me.Casting()` true — verify success via the action's own readiness flip / cooldown, not the cast window. Relevant to RGMercs and Squire casting logic alike.
