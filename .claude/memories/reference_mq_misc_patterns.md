---
name: mq-misc-patterns
description: Assorted MQ Lua mechanics - bag settle time, settings pickle, bag slots, spell memorization and interrupt detection, giving items to pets
metadata:
  type: reference
---

- Freshly summoned bags need ~300ms settle time before `/itemnotify in` works on contents
- Settings: `mq.pickle()` to save, `loadfile()` to load from `mq.configDir`
- Pack slots: `Me.NumBagSlots()` for dynamic count (10-12)
- Spell mem: `/memspell N "SpellName"`, verify with `Me.Gem(N)` + `Me.SpellReady(N)` loop
- `/memspell` is a no-op while feigned — doesn't break feign, doesn't memorize
- `SpellBookWnd.Open()` is a reliable memorize-interrupt signal: book opens ~60-100ms after `/memspell`, closes on completion OR on interrupt (knockback, /stand, etc.). "Book opened then closed with gem still empty" catches interrupts within one 100ms poll tick vs waiting out the 25s timeout
- Give to pet: target pet, item on cursor, `spawn.LeftClick()`
- **Trades fail on attacking pets**: left-click-target won't open GiveWnd while the pet is actively attacking. Any cursor/bag/trade method relying on `/click left target` to open GiveWnd will timeout.
- Find a player's pet: `mq.TLO.Spawn("pc " .. playerName).Pet`
