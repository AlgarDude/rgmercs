---
paths:
  - "ui/**"
  - "modules/**"
  - "utils/**"
  - "init.lua"
---

# ImGui Patterns
- **`imgui.Image` tint broken (ImGui 1.92.5+)** — `ImVec4` tint param on `imgui.Image` no longer applies alpha. Use `DrawList:AddImage` with `IM_COL32(r, g, b, a)` instead (a is 0-255).
- `imgui.Begin(name, pOpen)` returns `(pOpen, shouldDraw)` — first return is close-button state, second is whether to draw. When X clicked, first return becomes `false`. Pattern: `showUI, open = imgui.Begin("Window", showUI)`.
- **Early return after `imgui.Begin` MUST still call `End()` + `PopStyleVar(N)`** — skipping corrupts ImGui's style stack, causing white flashing and frozen windows.
- **NEVER use `mq.delay` in an ImGui render thread** — it blocks the UI.
- **CollapsingHeader + overlapping buttons**: use the two-pass pre/post render pattern.
- **`OpenPopup` and `BeginPopup` must share the same ID-stack context** — a table cell pushes the column index onto the ID stack, so calling `OpenPopup` from inside `BeginTable`/`TableNextColumn` hashes a different ID than the matching `BeginPopup` outside `EndTable()`, and the popup never opens. Hoist `OpenPopup` out of the table by setting a flag in the button handler and firing the actual `OpenPopup` after `EndTable()`.
- **Don't hardcode UI/layout values** — calculate via `GetCursorPosX()`, `GetStyle()`, `CalcTextSize()`. One correct calculation beats three wrong guesses.
- MQ's `CreateTexture` pads non-power-of-2 images to the next power of 2.
- When the user specifies an exact icon name (FA_ or MD_ prefix), use it directly without verification — the user has an icon viewer.
