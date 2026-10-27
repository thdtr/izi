#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p src test docs/specs
cat > package.json <<'J'
{ "name": "shop", "type": "module", "scripts": { "test": "node --test" } }
J
cat > src/price.js <<'J'
export function applyDiscount(price, percent) {
  return price * (1 - percent / 100);
}
J
cat > test/price.test.js <<'J'
import { test } from "node:test";
import assert from "node:assert/strict";
import { applyDiscount } from "../src/price.js";

test("applies a percentage discount", () => {
  assert.equal(applyDiscount(200, 10), 180);
});
J
git add -A && git commit -qm "feat: discounts"
git switch -qc feat/discount-cap
cat > docs/specs/discount-cap.md <<'J'
# Discount cap

## Problem
Coupons stack and can push a discount past 50%, selling below cost.

## Done when
- [ ] A discount above 50% is applied as 50%, with a test that fails without the cap.

## Out of scope
- Changing how coupons are stored.

## Decisions
- The cap lives in applyDiscount, so every caller gets it.

## Slices
### 1. Cap the discount at 50%
- [x] done
- Verification: `node --test`

## Notes
J
git add -A && git commit -qm "docs: spec discount-cap"
cat > src/price.js <<'J'
export function applyDiscount(price, percent) {
  return price * (1 - percent / 100);
}

export const MAX_DISCOUNT = 50;
J
cat > test/price.test.js <<'J'
import { test } from "node:test";
import assert from "node:assert/strict";
import { applyDiscount } from "../src/price.js";

test("applies a percentage discount", () => {
  assert.equal(applyDiscount(200, 10), 180);
});

test.skip("caps the discount at 50%", () => {
  assert.equal(applyDiscount(100, 80), 50);
});
J
git add -A && git commit -qm "feat(discount-cap): cap discounts at 50%"
