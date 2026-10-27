#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
git config commit.gpgsign false
cat > index.html <<'J'
<form><input name="email"><button type="submit">Sigin</button></form>
J
git add -A && git commit -qm "feat: login form"
