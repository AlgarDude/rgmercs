---
name: Tooltip style - terse, no advisories
description: Squire/MQ UI tooltips should be one short sentence stating what the option does; don't enumerate scope or warn about side effects
type: feedback
originSessionId: 676b017c-48e6-4ac0-946a-36ff3efb390d
---
Tooltips should be one short sentence stating what the option does. Don't enumerate where it applies ("manual, tell, reactive..."), don't warn about related settings' side effects, don't append notes about interactions.

**Why:** User rewrote a multi-clause tooltip ("Allow pet arming to proceed while you are in combat or have aggressive XTargets. Applies to manual, tell-triggered, and reactive arming. Your Pre-Queue Command will still fire.") down to "Allow pet arming to proceed under combat conditions." Called it "overly complex."

**How to apply:** When writing Squire/MQ tooltips, draft one sentence. If tempted to add a second sentence clarifying scope or side effects, don't — if side effects matter, the user will discover them or ask. Reserve longer explanations for `/squire help` output or the README.
