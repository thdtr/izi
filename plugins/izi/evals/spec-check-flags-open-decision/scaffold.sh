#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
mkdir -p docs/specs
cat > docs/PROJECT.md <<'J'
# Teamboard

## What it is

Task boards for small teams. Multi-tenant: every record belongs to a team.

## Architecture decisions

- A user can belong to several teams, with role admin or member in each.
J
cat > docs/specs/team-invites.md <<'J'
# Team invites

## Problem
Admins add people by asking them to sign up and then emailing support.

## Done when
- [ ] An admin invites someone by email and they end up in the team.

## Out of scope
- Bulk invites.

## Decisions
- Invites are stored in an invites table with email, team_id and token.

## Slices
### 1. Invite by email and accept
- [ ] done
- Verification: `pnpm test invites`

## Notes
J
git add -A && git commit -qm "docs: spec team-invites"
