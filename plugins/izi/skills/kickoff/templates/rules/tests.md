---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/__tests__/**"
  - "e2e/**"
  - "tests/**"
---

# Tests

- Runner: <>. Location: <next to the code | __tests__>. Naming: <*.test.ts>.
- Test database: <in-process database (PGlite/SQLite) | dedicated container>; never the dev one.
- E2E: <Playwright in e2e/>, critical flows only (signup, login, checkout).
- Test observable behavior (return value, HTTP response, what shows up
  on screen), not internal details.
- A test only counts if it would fail with the logic broken. A fixed bug
  gets a test that reproduces it.
- Mock only at the external boundary (network, Stripe, email, clock),
  never the module under test.
- Never weaken a test to make it pass (removing an assert, `skip`,
  loosening an expectation). An existing test only changes with a
  justification in the commit.
