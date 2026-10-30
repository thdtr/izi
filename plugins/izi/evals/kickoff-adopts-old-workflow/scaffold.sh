#!/usr/bin/env bash
# A working app that used Cursor and a plans folder, adopting izi.
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p .cursor/rules docs/plans src test
cat > .cursor/rules/general.mdc <<'J'
---
alwaysApply: true
---
Write clean code. Use meaningful variable names. Run `node --test` before committing.
J
cat > docs/plans/01-orders.md <<'J'
# Plan 01: orders
Status: done. Orders can be created and listed.
J
cat > docs/plans/02-refunds.md <<'J'
# Plan 02: refunds (pending)
Customers ask for a refund from the order page. A refund is only allowed
within 7 days of delivery; after that the button is hidden and the API
refuses it.
J
cat > package.json <<'J'
{ "name": "shop", "type": "module", "scripts": { "test": "node --test" } }
J
cat > src/orders.js <<'J'
const orders = [];
export function createOrder(items) {
  const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  const order = { id: orders.length + 1, items, total, status: "created" };
  orders.push(order);
  return order;
}
export const listOrders = () => orders;
J
cat > test/orders.test.js <<'J'
import { test } from "node:test";
import assert from "node:assert/strict";
import { createOrder } from "../src/orders.js";
test("total is the sum of the items", () => {
  assert.equal(createOrder([{ price: 10, qty: 2 }]).total, 20);
});
J
git add -A && git commit -qm "feat: orders"
