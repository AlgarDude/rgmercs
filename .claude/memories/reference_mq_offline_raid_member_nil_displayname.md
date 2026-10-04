---
name: mq-offline-raid-member-nil-displayname
description: "Offline raid members have truthy member() but nil DisplayName() — guard with `or \"\"` to avoid nil-string crashes"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 58c1d265-d263-410c-aceb-f1d7202c5135
---

In `mq.TLO.Raid.Member(N)`, an offline raid member returns a **truthy member object** but `member.DisplayName()` returns **nil** (not empty string). Code that assumes "member exists ⇒ DisplayName is a string" will crash on the next `:lower()` / `:find()` / concat.

**Idiom:** `(member.DisplayName() or "")` whenever iterating raid roster code that may include offline members.
