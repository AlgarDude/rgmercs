---
name: code-comment-style-deltas
description: "Deltas on CLAUDE.md's comment rules — match sibling precedent for WHETHER to comment; @param prose welcome (not bare types); multi-step navigational signposts ARE wanted for genuinely complex code."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 58c1d265-d263-410c-aceb-f1d7202c5135
---

CLAUDE.md owns the base comment rules (minimize, one-sentence summaries, no multi-line summary blocks, no usage/contract prose like "pair with"/"caller must"/"use when"). This memory holds the deltas not in CLAUDE.md:

1. **Match sibling precedent for WHETHER to comment at all.** Don't annotate something the code already self-documents (e.g. a `load_cond = not Core.IsTanking()` already says "DPS only") UNLESS the neighboring entries/functions of the same kind carry similar comments. If siblings have them, follow precedent and match their length/wording (e.g. the existing `ForgeDisc` Burn entry's `-- for DPS mode`); if they don't, add none. This governs WHETHER to comment, NOT whether to adopt a verbose style (see #4).

2. **Complex multi-step code: short navigational signposts ARE wanted.** Normally anti-inline-comment, but for genuinely complex multi-step functions (e.g. the mez machine) the user wants short one-line signposts atop each block saying WHAT it does (e.g. `-- count unmezzed tracked mobs, minus the autotarget`), so he can skim the flow and jump to the right section while troubleshooting. Still ONE short line, no parentheticals, no restating the obvious. This is granted by code complexity, not a general license.

3. **`@param`/`@return` lines: plain-language explanations welcome, NOT bare types.** Real prose beats `---@param peer string`. Even when the leading summary is gone, keep the per-param explanations.

4. **Precedent trap:** a util file (e.g. `utils/comms.lua`) being wall-to-wall with multi-line summary blocks is NOT license to replicate them — the one-sentence-summary rule overrides local verbose precedent. Those existing multi-liners were added by another dev, the user disapproves, and they're slated for cleanup. When editing in such a file, write the lean form regardless of neighbors.

5. **Mechanical self-check while writing:** if a second sentence is appearing to explain usage, that's the tell — cut it. The sprawl is almost never from describing WHAT a function does (that compresses to one sentence fine); it's from documenting HOW/WHEN to CALL it. A doc comment states what the function IS/RETURNS (+ at most one non-obvious constraint); it must NOT carry call-site instructions.

**Exemplar (user-approved):**
```lua
--- Runs the main-loop engage step mid-song, gated to the combat target so it never re-targets off a mez/charm/cure victim.
---@param targetId number The song's target (UseSong's targetId).
function Module:DoMidSongEngage(targetId)
```
One sentence (what + one non-obvious constraint), then a per-param explanation.

**Anti-exemplar (the multi-line summary is the problem, NOT the param lines):**
```lua
--- Sends a directed actor message to a single peer by looking up
--- their server and character name from PeersToServerNameMap.
--- @param peer string The peer key ("Name (Server)") to send to.
```
Fix: collapse the summary to ONE sentence (or drop entirely for trivial fns); KEEP per-param explanations.

See also CLAUDE.md Working Rules (the stricter "don't ADD a new comment without asking" rule, including the bugfix-comment ban) and [[feedback_tooltip_style]] (same brevity ethos).
