# rgmercs code conventions

What the pattern reviewer holds new code to. These are the conventions the existing
code already follows; the reviewer's job is to notice when a change does not.

## Reuse first

- Before adding a helper, grep the utility module for the concept (`utils/strings.lua`,
  `utils/tables.lua`, `utils/core.lua`, `utils/comms.lua`, `utils/targeting.lua`,
  `utils/casting.lua`, `utils/combat.lua`, `utils/movement.lua`). The index the reviewer
  builds lists every function in the tree; if a name or doc line matches the concept,
  use it or explain in the PR why it does not fit.
- Commands go through `Core.DoCmd` / `Core.DoGroupCmd` / `Comms.SendPeerDoCmd`, not raw
  `mq.cmd`. Output goes through `Logger.log_*`, not `print`. Timing uses `mq.gettime()`.
- Main-assist, tank, and peer lookups go through `Core.*` and `Comms.*`, which also handle
  raid assist and cross-server peers.
- Settings are declared in the module's `DefaultConfig` and read through `Config:GetSetting`;
  class configs declare theirs in `DefaultConfig` inside the config table.
- Class config files are data. Logic belongs in `ModeChecks`, `HelperFunctions`, or a
  module, and the `cond` functions on rotation entries should call the existing `Casting`,
  `Targeting`, and `Core` checks rather than re-deriving them from TLOs.
- Three similar lines beat a premature abstraction. Extract a helper for a pattern used
  three or more times, not two.

## Lua style

- 4-space indent, no tabs, 180-column limit, one trailing newline, no trailing whitespace.
- Trailing separator on every table literal, including single-line: `{ a = 1, b = 2, }`.
- camelCase for locals and parameters. Descriptive names: `spell` not `sp`, `entryType`
  not `t`. Qualify instead of abbreviating when a name would shadow a builtin.
- Module-level state is `local foo = nil`, not bare `local foo`.
- Values inline where used; no single-use locals, no module-level constants without a
  clear need, no grouping variables into tables.
- Guard clauses for early exit. Bare `return` for bail-outs; `return nil` when the caller
  inspects the value.
- No `goto` / `::continue::`.
- Comments only for non-obvious logic, workarounds, and platform quirks. One sentence.
  No "this avoids X" rationale comments; that belongs in the PR.
- No type annotations, feature flags, compatibility shims, or defensive checks for
  impossible cases.
- In-game strings (names, commands, tells) use double quotes; infrastructure strings
  (`require` paths, constants) use single quotes. Strings containing `"` stay single-quoted.
- No em dashes in strings: MQ's default font renders them as `?`.

## MacroQuest safety patterns

- A TLO string chained into a string method must be nil-guarded:
  `(me.CombatState() or ""):lower()`, never `me.CombatState():lower()`.
- Two TLO values that can both be nil must not be compared directly (`nil == nil` is
  true). Capture into a local and guard first.
- Capture TLO values into locals before `mq.delay` or `mq.cmd`; they can change across
  the yield.
- `mq.delay` condition callbacks must return a boolean. `not x()` is fine; returning a
  TLO value or a short-circuit expression is not.
- Nil idioms: `Cursor.ID()` style TLOs return nil when absent (`not x`);
  `Pet.ID()` / `Target.ID()` return 0 (`(x or 0) > 0`); `.Pet` returns the truthy
  string `"NO PET"`, so use `(petSpawn.ID() or 0) == 0`.
- Actor messages broadcast across every MQ instance on the network, including other
  servers. Every broadcast carries `server = mq.TLO.EverQuest.Server()` and the handler
  filters on it; add zone filtering when behaviour is zone-specific.

## ImGui

- Never call `mq.delay` from a render function.
- An early return after `imgui.Begin` must still call `End()` and pop any pushed style
  vars, or the style stack corrupts.
- `OpenPopup` and `BeginPopup` must share the same ID-stack context; hoist `OpenPopup`
  out of tables with a flag.
- Do not hardcode layout values; compute from `GetCursorPosX()`, `GetStyle()`,
  `CalcTextSize()`.
- Use `DrawList:AddImage` with `IM_COL32` for tinted images; `imgui.Image` tint alpha
  is broken on current ImGui.
