---
name: feedback-faq-style
description: "RGMercs FAQ Answer fields should be tight user-facing prose, not tutorials"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a59b2c29-6a50-4d51-b06d-499558612399
---

Keep FAQ Answer fields short, but preserve keyword-bearing enumerations — the settings UI filter searches against this text, so concrete terms (element names, effect names, command names) are load-bearing for discoverability, not bloat. Cut tutorial padding (class-config concepts, IgnoreImmuneCheck) and implementation explanations (auto-detection, spell data, internals). Just: what it does + when to use it, with the searchable nouns intact.

**Why:** User called a SkipFooSpells FAQ "ridiculously verbose" — flagged three bloat sources (teaching class authors about IgnoreImmuneCheck, listing spell/song/disc/AA/clicky after "any," explaining auto-detection from spell data). After I over-trimmed and stripped the element list too, user clarified they actually wanted the first line back because "Fire/Cold/Magic/Poison/Disease" gives the filter useful words to match against.

**How to apply:** When writing FAQ/Answer fields for `Config:GetSetting` entries or `Module.FAQ` arrays, ask "would a user filtering for this term hit my text?" before cutting. Keep the enumerations that name the thing (elements, effects, command names). Cut the paragraphs that explain *how* or teach *who can configure what*. Same spirit as [[feedback_tooltip_style]] and [[feedback_commit_style]] but with one extra constraint: the settings filter is a real consumer of this text.
