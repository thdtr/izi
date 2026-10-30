#!/usr/bin/env bash
# Tests for the hook scripts in plugins/izi/scripts. Each case feeds a hook
# the JSON Claude Code would send and checks the exit code and output.
# Runs on Linux, macOS (bash 3.2) and Git Bash on Windows:
#   bash tests/hooks.sh
# The scripts run with the same bash that runs this file.

set -uo pipefail

scripts="$(cd "$(dirname "$0")/../plugins/izi/scripts" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

# Paths as Claude Code sends them: native Windows paths on Windows.
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else echo "$1"; fi; }

pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; echo "     $2"; failures=$((failures + 1)); }

# A repo with one changed code file.
repo="$tmp/repo"
git init -q "$repo"
echo 'x = 1' >"$repo/app.py"
repo_native="$(native "$repo")"

# jq that answers with CRLF, like jq.exe inside Git Bash.
crlf_bin="$tmp/crlf-bin"
mkdir -p "$crlf_bin"
real_jq="$(command -v jq)"
printf '#!/usr/bin/env bash\n"%s" "$@" | sed '"'"'s/$/\\r/'"'"'\n' "$real_jq" >"$crlf_bin/jq"
chmod +x "$crlf_bin/jq"

# PATH with everything the scripts use except jq. Wrappers, not symlinks:
# Git Bash copies on ln -s, and a copied git.exe can't find its own files.
nojq_bin="$tmp/nojq-bin"
mkdir -p "$nojq_bin"
for c in git sed grep sort cat tail tr cut rm mkdir dirname touch true; do
  printf '#!%s\nexec "%s" "$@"\n' "$BASH" "$(command -v "$c")" >"$nojq_bin/$c"
  chmod +x "$nojq_bin/$c"
done

payload() { # event, last message, stop_hook_active
  printf '{"hook_event_name":"%s","cwd":%s,"last_assistant_message":"%s","stop_hook_active":%s}' \
    "$1" "$("$real_jq" -Rn --arg p "$repo_native" '$p')" "$2" "${3:-false}"
}

# run <script> <stdin>; sets code, out, err. Extra env goes before the call.
run() {
  out="$(printf '%s' "$2" | "$BASH" "$scripts/$1" 2>"$tmp/err")"
  code=$?
  err="$(<"$tmp/err")"
}

reset_gate() { rm -f "$repo/.git/izi-check-ok" "$repo/.git/izi-check-fail"; }

# --- check.sh -------------------------------------------------------------

reset_gate
IZI_CHECK=false run check.sh "$(payload PreToolUse done)"
[[ $code == 2 && "$err" == *"Quick gate failed"* ]] && pass "failed gate blocks the commit" ||
  fail "failed gate blocks the commit" "code=$code err=$err"

reset_gate
IZI_CHECK=false run check.sh "$(payload Stop done)"
[[ $code == 0 && "$out" == *additionalContext* ]] && pass "failed gate goes back to Claude on Stop" ||
  fail "failed gate goes back to Claude on Stop" "code=$code out=$out"

IZI_CHECK=false run check.sh "$(payload Stop done true)"
[[ $code == 0 && -z "$out" ]] && pass "same failure after a block lets the turn end" ||
  fail "same failure after a block lets the turn end" "code=$code out=$out"

reset_gate
IZI_CHECK=false run check.sh "$(payload Stop 'Which one do you want?')"
[[ $code == 0 && -z "$out" ]] && pass "turn ending in a question is not blocked" ||
  fail "turn ending in a question is not blocked" "code=$code out=$out"

reset_gate
counter="$tmp/runs"
: >"$counter"
IZI_CHECK="echo run >>'$counter'" run check.sh "$(payload Stop done)"
IZI_CHECK="echo run >>'$counter'" run check.sh "$(payload Stop done)"
runs="$(wc -l <"$counter" | tr -d ' ')"
[[ $code == 0 && $runs == 1 ]] && pass "passing gate is not rerun for the same files" ||
  fail "passing gate is not rerun for the same files" "code=$code runs=$runs"

reset_gate
PATH="$crlf_bin:$PATH" IZI_CHECK=false run check.sh "$(payload PreToolUse done)"
[[ $code == 2 ]] && pass "gate still blocks when jq answers with CRLF" ||
  fail "gate still blocks when jq answers with CRLF" "code=$code err=$err"

PATH="$nojq_bin" IZI_CHECK=false run check.sh "$(payload Stop done)"
[[ $code == 0 && -z "$out" && "$err" == *"jq not found"* ]] && pass "without jq the gate is skipped with a warning" ||
  fail "without jq the gate is skipped with a warning" "code=$code err=$err"

# --- format.sh ------------------------------------------------------------

file_payload="$(printf '{"tool_input":{"file_path":%s}}' "$("$real_jq" -Rn --arg p "$(native "$repo/app.py")" '$p')")"
mark="$tmp/formatted"

rm -f "$mark"
MARK="$mark" IZI_FORMAT='touch "$MARK"; true' run format.sh "$file_payload"
[[ $code == 0 && -f "$mark" ]] && pass "format runs on the edited file" ||
  fail "format runs on the edited file" "code=$code err=$err"

rm -f "$mark"
PATH="$crlf_bin:$PATH" MARK="$mark" IZI_FORMAT='touch "$MARK"; true' run format.sh "$file_payload"
[[ $code == 0 && -f "$mark" ]] && pass "format still runs when jq answers with CRLF" ||
  fail "format still runs when jq answers with CRLF" "code=$code err=$err"

PATH="$nojq_bin" IZI_FORMAT=true run format.sh "$file_payload"
[[ $code == 0 && "$err" == *"jq not found"* ]] && pass "without jq format is skipped with a warning" ||
  fail "without jq format is skipped with a warning" "code=$code err=$err"

echo
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
