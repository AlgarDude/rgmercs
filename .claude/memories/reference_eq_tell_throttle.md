---
name: eq-server-tell-throttle
description: "EQ server throttles rapid outbound tells — space them out, don't burst multiple back-to-back"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 58c1d265-d263-410c-aceb-f1d7202c5135
---

The EQ server rate-limits outbound `/tell`s. Sending several in immediate succession can drop later tells silently — they don't error, they just never reach the recipient.

**Apply:** when a script needs to send multiple tells (replies, broadcasts), space them with a small `mq.delay` between sends, or avoid the burst entirely.
