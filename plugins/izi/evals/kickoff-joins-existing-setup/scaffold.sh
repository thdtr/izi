#!/usr/bin/env bash
# A project already set up by izi, opened by someone who just joined.
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p .claude docs src
cat > AGENTS.md <<'J'
# AGENTS.md

## Project

- Product: Shop, a small online store. Scope and roadmap: `docs/PROJECT.md`.

## Commands

- Full gate: `pnpm lint && pnpm typecheck && pnpm test && pnpm build`
J
printf '@AGENTS.md\n' > CLAUDE.md
cat > .claude/settings.json <<'J'
{
  "env": {
    "IZI_FORMAT": "pnpm exec prettier --write --ignore-unknown --log-level=silent",
    "IZI_CHECK": "pnpm exec tsc --noEmit",
    "IZI_CODE_EXT": "ts,tsx"
  },
  "enabledPlugins": { "izi@izi": true }
}
J
cat > docs/PROJECT.md <<'J'
# Shop

## What it is

A small online store.

## Roadmap

- [ ] 1. Walking skeleton: login + product list + deploy + green CI
J
cat > package.json <<'J'
{ "name": "shop", "private": true, "packageManager": "pnpm@10.0.0",
  "scripts": { "lint": "eslint .", "typecheck": "tsc --noEmit", "test": "vitest run", "build": "next build" } }
J
printf 'export const shop = "shop";\n' > src/index.ts
git add -A && git commit -qm "chore: set up izi workflow"
