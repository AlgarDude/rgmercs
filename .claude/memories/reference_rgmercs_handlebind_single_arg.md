---
name: rgmercs-handlebind-single-arg
description: Base:HandleBind forwards only the FIRST /rgl argument — multi-arg module commands need a per-module HandleBind override (class.lua and pull.lua are the precedents).
metadata: 
  node_type: memory
  type: reference
  originSessionId: c56c542a-75bc-4d4c-b11b-1ed491cccbea
---

`Base:HandleBind` (modules/base.lua) does `local params = ...` and calls `handler(self, params)` — every bind argument after the first is silently dropped before the handler runs. The dispatch chain (`/rglua` → `Binds.MainHandler` → `Modules:ExecAll("HandleBind", cmd, ...)`) forwards everything; Base is where the truncation happens.

Any module command taking multiple arguments must override `HandleBind` to forward varargs. Precedents: class.lua (~2541, wraps in `Core.SafeCallFunc`) and pull.lua (added 7/4/26 for `fightto`/`huntfrom`; mirrors Base's exact behavior — exact match on `cmd:lower()`, then `Strings.StartsWith` substring — with `...` forwarded). Extra varargs are harmless to existing single-arg handlers (Lua ignores them).

Symptom when missed: multi-arg command forms fail with confusing wrong-argument errors while single/zero-arg forms work — caught only by an adversarial audit in the pull-modes work because nothing exercised the real dispatch path. Whether to fix Base itself for all modules is an open pull-rewrite question (`../plans/RGMERCS_PULL_REWRITE_BRIEF.md` §5.5).
