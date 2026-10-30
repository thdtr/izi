#!/usr/bin/env bash
# Tests for the multi-stack scripts kickoff copies into a project
# (plugins/izi/skills/kickoff/templates/izi-check.sh and izi-format.sh).
#   bash tests/templates.sh

set -uo pipefail

templates="$(cd "$(dirname "$0")/../plugins/izi/skills/kickoff/templates" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; echo "     $2"; failures=$((failures + 1)); }
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else echo "$1"; fi; }

# A project with two stacks whose "checks" record where they ran and what they got.
repo="$tmp/repo"
mkdir -p "$repo/scripts" "$repo/api/pkg" "$repo/app/lib"
log="$tmp/log"
# make_check <api quick check>: each check records which stack, which kind
# (quick/full), where it ran and what it got.
make_check() {
  sed -e "s#\"<name>|<directory>|<quick check>|<full check>\"#\"api|api|$1|echo api full >>'$log'\" \"app|app|echo app quick \\\\\$PWD \\\\\$IZI_CHANGED >>'$log'|echo app full >>'$log'\"#" \
    "$templates/izi-check.sh" >"$repo/scripts/izi-check.sh"
}
make_check "echo api quick \\\\\$PWD \\\\\$IZI_CHANGED >>'$log'"
sed -e "s#\"<directory>|<ext,ext>|<format command>\"#\"api|go|echo api >>'$log'; echo\" \"app|dart|echo app >>'$log'; echo\"#" \
  "$templates/izi-format.sh" >"$repo/scripts/izi-format.sh"

check() { : >"$log"; out="$(cd "$repo" && IZI_CHANGED="$1" "$BASH" scripts/izi-check.sh ${2:+"$2"} 2>&1)"; code=$?; ran="$(cat "$log")"; }

check "api/pkg/a.go api/b.go"
[[ $code == 0 && "$ran" == "api quick "*"/api pkg/a.go b.go" ]] && pass "quick gate runs only the touched stack, inside it, with its own paths" ||
  fail "quick gate runs only the touched stack, inside it, with its own paths" "code=$code ran=$ran out=$out"

check "README.md"
[[ $code == 0 && -z "$ran" ]] && pass "quick gate skips files outside every stack" ||
  fail "quick gate skips files outside every stack" "code=$code ran=$ran"

check "" --all
[[ $code == 0 && "$ran" == *"api full"* && "$ran" == *"app full"* && "$ran" != *quick* ]] && pass "--all runs the full check of every stack" ||
  fail "--all runs the full check of every stack" "code=$code ran=$ran"

check "" app
[[ $code == 0 && "$ran" == "app full" ]] && pass "a stack name runs only that stack's full check" ||
  fail "a stack name runs only that stack's full check" "code=$code ran=$ran"

check "" nope
[[ $code == 2 && "$out" == *"Unknown stack"* ]] && pass "an unknown stack name fails" ||
  fail "an unknown stack name fails" "code=$code out=$out"

make_check "exit 1"
check "api/b.go"
[[ $code != 0 ]] && pass "a failing check fails the gate" || fail "a failing check fails the gate" "code=$code"

: >"$log"
(cd "$repo" && "$BASH" scripts/izi-format.sh "$(native "$repo/app/lib/main.dart")")
[[ "$(cat "$log")" == "app" ]] && pass "format picks the stack by directory and extension" ||
  fail "format picks the stack by directory and extension" "log=$(cat "$log")"

: >"$log"
(cd "$repo" && "$BASH" scripts/izi-format.sh "$(native "$repo/api/notes.md")")
[[ -z "$(cat "$log")" ]] && pass "format ignores other extensions" ||
  fail "format ignores other extensions" "log=$(cat "$log")"

echo
((failures == 0)) && echo "all passed" || { echo "$failures failed"; exit 1; }
