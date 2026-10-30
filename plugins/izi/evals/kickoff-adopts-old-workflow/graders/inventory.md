---
type: llm
---

The project has three leftovers from its previous workflow: `.cursor/rules/general.mdc` (generic advice plus the test command), `docs/plans/01-orders.md` (a finished plan) and `docs/plans/02-refunds.md` (a pending plan with the rule "refunds only within 7 days of delivery").

PASS if the reply's plan gives each of the three a destination, and: the finished plan and the generic advice are deleted; the refund plan becomes a roadmap item; the 7-day refund rule is a business rule in docs/PROJECT.md; the roadmap does not start with a walking skeleton.
FAIL if any of the three is missing from the plan, if old files are kept "for reference" or moved to an archive, or if the roadmap starts with a walking skeleton.
