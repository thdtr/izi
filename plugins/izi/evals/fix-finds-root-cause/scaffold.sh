#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p src test
cat > package.json <<'J'
{ "name": "shop", "type": "module", "scripts": { "test": "node --test" } }
J
cat > src/price.js <<'J'
export function applyDiscount(price, percent) {
  return price - percent;
}
J
cat > test/price.test.js <<'J'
import { test } from "node:test";
import assert from "node:assert/strict";
import { applyDiscount } from "../src/price.js";

test("applies a percentage discount", () => {
  assert.equal(applyDiscount(200, 10), 180);
  assert.equal(applyDiscount(50, 50), 25);
});
J
git add -A && git commit -qm "feat: discounts"
