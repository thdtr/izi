#!/usr/bin/env bash
# A finished feature branch in a project with an older, numbered roadmap.
# Regression guard: ship marks the spec, never the roadmap in PROJECT.md.
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p docs/specs src
cat > docs/PROJECT.md <<'J'
# Shop

## Roadmap

- [x] 1. Walking skeleton: login + product list + deploy + green CI
- [ ] 2. Checkout: cart and card payment
J
printf 'export const shop = "shop";\n' > src/index.ts
git add -A && git commit -qm "feat: walking skeleton"
git switch -q -c feat/checkout
cat > docs/specs/checkout.md <<'J'
# Checkout

Roadmap: 2. Checkout

## Done when
- [x] A customer pays for the cart with a card
## Slices
### 1. Cart
- [x] done
### 2. Card payment
- [x] done
## Notes
J
printf 'export const checkout = () => "paid";\n' > src/checkout.ts
git add -A && git commit -qm "feat(checkout): customer pays for the cart"
sha="$(git rev-parse --short HEAD)"
printf -- '- Review: %s no blockers\n' "$sha" >> docs/specs/checkout.md
git add -A && git commit -qm "docs: review checkout"
