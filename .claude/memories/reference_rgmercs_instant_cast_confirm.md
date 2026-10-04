---
name: reference-rgmercs-instant-cast-confirm
description: "RunCastLoop instant confirm (CORRECTED 7/3/26): many instants DO emit 'You begin casting' but the wait wasn't dispatching events (fixed); smart-return + FnF-opt-in design replaces noWait. See RGMERCS_CAST_CONFIRM_PLAN."
metadata: 
  node_type: memory
  type: reference
  originSessionId: c3243d04-3819-4ebd-8c50-9643a80f07f0
---

`Casting.RunCastLoop` confirms an instant (`castTime==0`) by waiting `floor = max(300, 3×ping)` then checking `readyCheck()`. Two corrections to the old "instants emit no catchable cast message" belief (revised 7/3/26):

- Instants often DO emit "You begin casting" — items always (server, ~250ms), spells client-side (~16ms), spell-triggering AAs too. RGMercs just wasn't catching it: the confirm `mq.delay` checks a `CastCompleted` result but `mq.doevents()` only ran AFTER the delay, so the event never dispatched mid-wait. Fixed with `mq.doevents('Success1')` inside the condition. Discs and pure-effect bard AAs stay genuinely silent. See [[reference_eq_cast_message_emission_map]].
- The floor is wasteful: the real confirm (flip / ActiveDisc / message) lands well before it. "Smart-return" = exit on the real signal, floor as cap. Active discs must key off `Me.ActiveDisc` populating, NOT the cooldown flip — ActiveDisc lags the flip ~30ms (measured 282-403ms vs flip ~250ms) and siblings gate on `NoDiscActive()`, so exiting on the flip reads stale (the a354378 bug).

Design (IMPLEMENTED 7/3/26, casting.lua/rotation.lua/clickies.lua): Confirm is RunCastLoop's DEFAULT so the queue (bypasses ExecEntry, passes no intent) stays safe by omission; FnF is opt-in from `ExecEntry` for rotation Disc/AA/Item, and for clickies via a per-clicky "Confirm Cast" (mustWait) toggle. `entry.noWait` removed entirely. Active discs confirm on `Me.ActiveDisc` populating (lags the flip ~30ms). Blanket fire-and-forget (a354378) reverted and must NOT return — the queue relies on real confirmation.
