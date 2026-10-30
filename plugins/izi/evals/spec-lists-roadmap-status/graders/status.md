---
type: llm
---

The roadmap has three items: `walking-skeleton` (its spec says Status: shipped), `checkout` (spec exists, not shipped) and `wishlist` (no spec).

PASS if the reply shows walking-skeleton as shipped/done, checkout as in progress, and wishlist as not started, and suggests wishlist as the next one to spec.
FAIL if any status is wrong, if it starts writing a spec without asking which item, or if it doesn't show the roadmap.
