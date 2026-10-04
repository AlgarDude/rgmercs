---
name: rgmercs-status-panel-style
description: "RGMercs module status-panel gotchas - never scan per render frame, compute derived counts AFTER the work, hideRotationCols for ability tables"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e6c53247-7820-4064-98dc-48d76d27623a
---

Gotchas for a module status/info panel (from mez, 6/13/26):

- **Never spawn-scan in Render.** Compute scan-derived values once in GiveTime/DoMez, stash in `TempSettings.Status`, read the snapshot in Render. (The snapshot freezes while the compute path is gated off - e.g. mez's is behind GiveTime's not-moving/not-hovering guards.)
- **Compute derived counts AFTER the work, not before.** A count snapshotted before the tracking/casting pass lags a tick and misses within-tick changes - refresh it at the end of the work function.
- **Don't echo settings the user already controls** - show runtime-derived state, colored via `Globals.Constants.Colors.Condition{Pass,Mid,Fail}` + `Ui.RenderColoredText`, like `ui/standard.lua`'s main info panel.
- Per-entry ability table: reuse `Ui.RenderRotationTable(..., hideRotationCols=true)` (7th arg) to drop the rotation-only Cur ("-") and "Condition Met" columns.
