#!/usr/bin/env bash
# PreToolUse (Bash "git commit *"): blocks the commit if gitleaks finds a
# secret in what is staged. Without gitleaks installed, it doesn't block
# (CI still runs gitleaks on the PR).

set -uo pipefail

command -v gitleaks >/dev/null 2>&1 || exit 0
if ! command -v jq >/dev/null 2>&1; then
  echo "izi: jq not found, secret scan skipped. Install it: https://jqlang.org/download/" >&2
  exit 0
fi

# tr: jq.exe inside Git Bash ends lines with CRLF.
cwd="$(jq -r '.cwd // empty' | tr -d '\r')"
root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

if ! out="$(gitleaks git --pre-commit --staged --redact --no-banner 2>&1)"; then
  {
    echo "Commit blocked: gitleaks found a possible secret in the staged changes. Remove the secret from the file (use an environment variable) and try again."
    tail -n 30 <<<"$out"
  } >&2
  exit 2
fi
exit 0
