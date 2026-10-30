#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p docs/specs src
cat > docs/PROJECT.md <<'J'
# Shop

## What it is

A small online store.

## Roadmap

- `walking-skeleton`: login + product list + deploy + green CI
- `checkout`: cart and card payment
- `wishlist`: save products for later
J
cat > docs/specs/walking-skeleton.md <<'J'
# Walking skeleton
Status: shipped

Roadmap: walking-skeleton
J
cat > docs/specs/checkout.md <<'J'
# Checkout

Roadmap: checkout

## Slices
### 1. Cart
- [x] done
### 2. Card payment
- [ ] done
J
printf 'export const shop = "shop";\n' > src/index.ts
git add -A && git commit -qm "feat: walking skeleton"
