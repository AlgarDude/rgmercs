---
name: mq-pet-primary-secondary-drawn-not-equipped
description: "Pet.Primary()/.Secondary() return the drawn (rendered) weapon ID, NOT what the pet has equipped — pet equipment is not accessible via TLO"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 58c1d265-d263-410c-aceb-f1d7202c5135
---

`mq.TLO.Pet.Primary()` and `mq.TLO.Pet.Secondary()` return the **drawn weapon ID** — a client-side rendering value showing what's visually equipped. They do NOT return the pet's equipped item.

There is no TLO accessor for pet equipment. Don't try to determine pet inventory via these.

**Silent failure mode:** code that reads `.Primary()` expecting "what's the pet wielding" gets a rendering value that may differ from actual equip state, and there's no error — just a wrong answer.
