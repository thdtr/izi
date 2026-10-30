#!/usr/bin/env bash
# Runs the project's quick gate ($IZI_CHECK) when a code file has changed
# and hasn't been validated yet. Registered on two events:
#   PreToolUse (git commit)  a failure blocks the commit (exit 2); build and
#                            fix commit inside the turn, so this is where
#                            their changes get checked
#   Stop                     covers what is left uncommitted; a failure goes
#                            back to Claude as Stop hook feedback
#
# Variables (set in .claude/settings.json > env by /izi:kickoff):
#   IZI_CHECK     shell command; receives IZI_CHANGED with the changed files
#   IZI_CODE_EXT  extensions that count as code, e.g. "ts,tsx,js" (default: all)
#
# Hooks run outside the Bash sandbox: the result here can differ from a
# command Claude runs sandboxed.

set -uo pipefail

[[ -n "${IZI_CHECK:-}" ]] || exit 0

# Without jq the hooks can't read the payload: skip with a warning instead
# of blocking every turn.
if ! command -v jq >/dev/null 2>&1; then
  echo "izi: jq not found, quick gate skipped. Install it: https://jqlang.org/download/" >&2
  exit 0
fi
# jq.exe inside Git Bash ends lines with CRLF; the \r would break paths.
jqr() { jq -r "$@" | tr -d '\r'; }

input="$(cat)"
event="$(jqr '.hook_event_name // empty' <<<"$input")"
cwd="$(jqr '.cwd // empty' <<<"$input")"
stop_hook_active="$(jqr '.stop_hook_active // false' <<<"$input")"
last_msg="$(jqr '.last_assistant_message // empty' <<<"$input")"

# Before a tool call, only a real git commit is gated. The hook's "if" filter
# is best-effort: Claude Code also runs it for commands with $VAR, $() or loops.
if [[ "$event" == "PreToolUse" ]]; then
  cmd="$(jqr '.tool_input.command // empty' <<<"$input")"
  commit_re='(^|[;&|[:space:](])git[[:space:]]([^;&|]*[[:space:]])?commit([[:space:];&|)]|$)'
  [[ -z "$cmd" || "$cmd" =~ $commit_re ]] || exit 0
fi

# A turn that ends with a question to the user is not blocked: forcing it
# to continue would make Claude "fix" things instead of asking.
trimmed="${last_msg%"${last_msg##*[![:space:]]}"}"
[[ "$event" == "Stop" && "$trimmed" == *"?" ]] && exit 0

root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

ext_re=".*"
if [[ -n "${IZI_CODE_EXT:-}" ]]; then
  ext_re="\\.(${IZI_CODE_EXT//,/|})$"
fi

# git status covers modified, staged and untracked files, and works without HEAD.
# A read loop, not mapfile: macOS still ships bash 3.2.
changed=()
while IFS= read -r f; do changed+=("$f"); done < <(
  git -c core.quotepath=off status --porcelain -uall 2>/dev/null \
    | sed -E 's/^.{3}//; s/.* -> //' \
    | grep -E "$ext_re" | sort -u
)
((${#changed[@]})) || exit 0

existing=()
for f in "${changed[@]}"; do [[ -f "$f" ]] && existing+=("$f"); done

git_dir="$(git rev-parse --absolute-git-dir)"
ok_file="$git_dir/izi-check-ok"
fail_file="$git_dir/izi-check-fail"
hash="$( { printf '%s\n' "${changed[@]}"; ((${#existing[@]})) && cat -- "${existing[@]}"; printf '%s' "$IZI_CHECK"; } 2>/dev/null | git hash-object --stdin)"

[[ "$hash" == "$(cat "$ok_file" 2>/dev/null)" ]] && exit 0
# Nothing changed since the last block: let it through instead of spending
# another turn on the same error (the native limit of 8 continuations also applies).
if [[ "$stop_hook_active" == "true" && "$hash" == "$(cat "$fail_file" 2>/dev/null)" ]]; then
  exit 0
fi

export IZI_CHANGED="${existing[*]:-}"
if out="$(bash -c "$IZI_CHECK" 2>&1)"; then
  echo "$hash" >"$ok_file"
  rm -f "$fail_file"
  exit 0
fi

echo "$hash" >"$fail_file"
msg="$(
  echo "Quick gate failed (IZI_CHECK). Fix the cause; don't weaken tests or suppress errors."
  tail -n 60 <<<"$out"
)"

if [[ "$event" == "Stop" ]]; then
  # The gate working as designed, not a hook error: additionalContext keeps
  # Claude going with the same loop protections as a block.
  jq -n --arg ctx "$msg" '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $ctx}}'
  exit 0
fi
echo "$msg" >&2
exit 2
