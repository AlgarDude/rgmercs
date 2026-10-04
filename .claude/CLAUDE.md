# RGMercs

MacroQuest Lua automation framework. Personal setup (machine paths, working style) goes in `CLAUDE.local.md` at the repo root, which is gitignored.

## Working Rules
- **Check existing patterns before implementing.** Before writing UI elements, settings, utility helpers, or repeated patterns, scan the file for similar existing implementations. Grep the relevant utility module (e.g. `comms.lua`, `strings.lua`) for similar helpers first — don't reinvent string formatters, peer/lookup helpers, or normalization functions that already exist.
- **Replicate structure, not formatting.** Match approach/shape, but naming and formatting follow the rules below even when adjacent code is terser — repo style has drifted from other AI work, so terser neighbors are drift, not a template.
- **When two conventions genuinely conflict, ask.** Don't pick on your own.
- **Don't add new comments without asking.** If a line/block has no comment today, do not add one as part of an edit. Bugfix/rationale comments ("this avoids X", "NPC search already includes pets so...") are especially unwanted: nobody reading the code later sees the bug context. Rationale belongs in the commit/PR. Editing existing comments is fine.
- **No AI attribution in git.** No `Co-Authored-By: Claude ...` trailer in commits and no "Generated with Claude Code" line in PRs. Also enforced by `attribution` in `.claude/settings.json`.

## Lua Conventions

**Keep it minimal.** No over-engineering, no premature abstractions, no "improvements" beyond what was asked. Only make changes that are directly requested or clearly necessary.

### Values and Variables
- Keep values inline where they're used; don't create module-level constants or extract single-use values unless there's a clear need
- No variable tables — avoid grouping variables into table structures
- camelCase naming: `thisThing = value` (not `this_thing` or `ThisThing`)
- Descriptive names, not cryptic abbreviations — `spell` over `sp`, `entryType` over `t`, `targetType` over `tt`. When the readable name would shadow a Lua builtin like `type`, qualify it (`entryType`) rather than reverting to the abbreviation.
- Initialize variables at the lowest scope possible. Inline calculations are fine, even complex ones, unless a local genuinely improves readability/formatting.
- Module-level variables are acceptable when used many times throughout the file
- Module-level state variables: always `local foo = nil`, not bare `local foo`
- `return nil` when the caller inspects the return value ("not found" / "no error"); bare `return` for early-exit bail-outs

### Functions and Flow
- Extract functions when they clarify logic or reduce duplication; keep them focused on a single responsibility
- Create helpers for patterns repeated 3+ times. Three similar lines is better than a premature abstraction.
- **Exception**: complex, lengthy functions all working toward one goal can stay together
- Keep main flow linear; use guard clauses for early returns and validate prerequisites at the start
- Use section comments to group related functions (e.g., `-- Utility Functions`) — concise labels, not descriptions

### Comments
- Minimize comments — code should be self-documenting; don't restate what the code does. Use them only for non-obvious logic, edge cases/workarounds, platform-specific behavior.
- Doc/summary comments: ONE sentence (what it does/returns, plus at most one non-obvious constraint). Never a multi-line summary block.
- No usage/contract prose in any comment — never "pair with X", "caller must Y", "use this when Z"
- More detail: `.claude/memories/feedback_code_comment_style.md`

### Formatting
Matches the sumneko `Lua.format.defaultConfig`: 4-space indent, 180-char max line (wrap long lines, don't pre-wrap short ones), aligned continuation params, and a trailing `,` after the last entry of every table literal, even single-line: `{ a = 1, b = 2, }`. A hook strips trailing whitespace and adds the final newline on `.lua` edits.

### What NOT to Add (unless explicitly asked)
Don't expand the implementation beyond what was asked. Do flag related issues for the user to triage — surfacing them is welcome, silently fixing or padding the diff with them is not.
- Error handling for impossible scenarios; validation of trusted internal code; defensive programming or complex error recovery
- Type annotations, feature flags, backwards-compatibility shims, configurability "for later"
- Logging or debug code unless part of the design
- Configuration files for simple inline values
- `goto` / `goto continue` / `::continue::` patterns

## MacroQuest Specifics

### Reference Documentation
- MQ docs (https://github.com/macroquest/docs) and MQ Lua definitions (https://github.com/macroquest/mq-definitions). Local clone paths are in `CLAUDE.local.md`.
- Neither source is complete — if there are gaps or discrepancies, defer to the user

### Patterns
- Use simple one-liner helpers for repeated patterns (like distance checks); keep `mq.delay` callbacks inline unless reused
- Trust that spawn objects exist after validation. **Exception**: follow-on checks where data can go stale across a yield or delay are reasonable.
- Module-level TLO references are acceptable when used extensively (e.g., `local invWindow = mq.TLO.Window('InventoryWindow')`)
- `mq.Set` (`lua/mq/Set.lua`): `Set.new(t)`, `add(v)`, `remove(v)`, `contains(v)`, `toList()` for O(1) membership checks
- `mq.gettime()` (ms since client start) for timing, not `os.clock()`

### TLO Safety
- **String method chains need nil guards.** `(me.CombatState() or ""):lower()`, NOT `me.CombatState():lower()`.
- **`nil == nil` is `true`.** When comparing two TLO values that can both be nil, capture the expected value into a local and guard it first: `local petId = petSpawn.ID() or 0; if petId == 0 then return false end`, then compare against `petId`.
- **Capture state before async boundaries.** TLO values can change after `mq.delay` or `mq.cmd` — capture into a local BEFORE (e.g., `Cursor.Name()` before `/autoinventory`).
- **`mq.delay` callbacks must return bool.** `not mq.TLO.Cursor.ID()` is safe. Dangers: returning a TLO value directly (`return mq.TLO.Cursor.ID()` returns a number) and short-circuits (`return abortFunc and abortFunc()` returns `nil` when `abortFunc` is nil).
- **`Spawn.TargetOfTarget` only populates for your current target.** `Me.TargetOfTarget` requires the client's Target-of-Target window option (NULL otherwise) — unreliable for detection logic.

### Nil-Check Idioms
- Some TLOs return nil when absent (e.g., `Cursor.ID()`) — use `~= nil` or `not X`
- Some return 0 when absent (e.g., `Pet.ID()`, `Target.ID()`) — use `(X or 0) > 0` or `== 0`
- **`.Pet` returns "NO PET" (truthy string) when there is no pet** — `not petSpawn()` will NOT catch it. Use `(petSpawn.ID() or 0) == 0`.
- For other spawn existence, `not spawn()` is sufficient — don't stack redundant ID checks
- Pick one idiom per concept and use it consistently

### Strings
- **In-game strings** (names, commands, tells): `""` double quotes — names may contain apostrophes
- **Infrastructure strings** (requires, constants like `'INGAME'`): `''` single quotes
- Strings containing inner `"` (e.g., `/memspell %d "%s"`) stay single-quoted
- No em dashes (`—`) in anything shown in game — MQ's default font renders them as `?`. Use `-`.

### EMU Servers
- **Outbound tells echo as inbound**: tells you send also appear as `YourName tells you, 'message'`. Event patterns matching inbound tells must filter out self-tells.

## Memory Notes
Durable rgmercs gotchas and EQ/MQ mechanics live in `.claude/memories/` — grep it by topic before implementing. Prefixes: `reference_*` (EQ/MQ/EMU mechanics), `project_*` (rgmercs internals), `feedback_*` (style conventions).
