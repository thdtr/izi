#!/usr/bin/env bash
# PostToolUse (Edit|Write): formats the edited file with $IZI_FORMAT.
# Silent on purpose: formatting never becomes feedback for the model
# (lint, types and tests run on Stop, in check.sh). If the project has no
# IZI_FORMAT (no /izi:kickoff), it does nothing.

set -uo pipefail

[[ -n "${IZI_FORMAT:-}" ]] || exit 0

file="$(jq -r '.tool_input.file_path // empty')"
[[ -n "$file" && -f "$file" ]] || exit 0

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$file")}" || exit 0

# The command gets the path as its last argument; formatter failures
# (a file type it doesn't know, missing binary) are ignored.
bash -c "$IZI_FORMAT \"\$1\"" _ "$file" >/dev/null 2>&1 || true
exit 0
