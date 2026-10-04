---
name: mq-nav-map-loc-quirks
description: "MQ2Nav PathExists can't Z-resolve 2D locs (always false); MQ2Map pullradius circle anchors at the player; /maploc radius CAN anchor a circle remotely (+ maploc doc contradicts itself on coord order)."
metadata: 
  node_type: memory
  type: reference
  originSessionId: c56c542a-75bc-4d4c-b11b-1ed491cccbea
---

All verified in-game 7/5/26 (Algar, RoF2 EMU) during the pull-modes feature work.

- **`Navigation.PathExists`/`PathLength` with a 2D destination (`locxy X Y`) return false ALWAYS.** The TLO does not perform the nearest-valid-height Z-resolution that the `/nav locxy` COMMAND performs — the identical location with an explicit Z returns true, and `/nav locxy` navigates fine. Validate 2D destinations by attempting nav (nav refusing to activate = unreachable evidence), never by PathExists. The mq-definitions claim of "same parameters as /nav" is grammatically true but behaviorally false here — see [[mq-defs-docs-pr-backlog]] #4.
- **`/mapfilter pullradius <n>` (MQ2Map) anchors its circle at the PLAYER's position when the filter command fires.** It cannot draw a circle around a remote point; re-issuing it while away from the intended center draws the circle in the wrong place. (rgmercs suppresses the circle while traveling to a remote hunt site for this reason.)
- **`/maploc <loc> radius <d> rcolor <r g b>` DOES anchor a circle at the given loc** (plus an X; optional `label <text>` at the end; `remove <loc>` is the safe cleanup — `remove <index>` collides with user-placed X's). Caveat: the maploc doc contradicts itself on coordinate order (Syntax line says `<x> <y>`, Options section says `<yloc> <xloc>`) — verify in-game before scripting it; logged in [[mq-defs-docs-pr-backlog]] #5.
