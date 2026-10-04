---
name: RGMercs debug-window Lua interleaves with the render loop
description: Why monkeypatching live RGMercs state from the debug window is hazardous, and the one patch that always crashes mercs
type: project
originSessionId: a6c84516-0c04-4092-ab2a-765b4961f434
---
Lua executed in the RGMercs debug window runs **interleaved with the ImGui render loop** (the `RGMercsGUI` callback in `init.lua` keeps firing between statements — you can see the debug window flicker). So monkeypatching live `Config` / `Modules` / `Comms` / `Globals` from there is risky: a frame can land mid-patch.

**The one that always crashes mercs:** patching `Globals.CurLoadedChar` / `Globals.CurServer` / `Globals.CurLoadedClass` to a value with no DB row. The render path does `Config:GetSetting('FontScale') / 100` (and other settings) **with no nil guard** — `GetSetting` reads `Globals.Cur*` to locate the DB row, gets nil for a bogus char/server/class, and `nil / 100` blows up in `RGMercsGUI`, killing the rgmercs script.

**Why:** discovered building `utils/db_management_test.lua` — crashed mercs twice before figuring it out.

**How to apply:** when testing/probing from the debug window, never reassign `Globals.Cur*`. If you must monkeypatch `Modules.ExecModule` / `Comms.SendMessage` etc. (the render loop calls these every frame), make the replacement *delegate* non-target calls to the original (`return sv.ExecModule(self, mod, fn, ...)`), or you'll return nil where the render path expects a value. Keep patched windows to a few synchronous statements and restore unconditionally.
