#!/usr/bin/env bash
# Stop: runs the project's quick gate ($IZI_CHECK) when a code file has
# changed and hasn't been validated yet. Exit 2 sends the error back to Claude.
#
# Variables (set in .claude/settings.json > env by /izi:kickoff):
#   IZI_CHECK     shell command; receives IZI_CHANGED with the changed files
#   IZI_CODE_EXT  extensions that count as code, e.g. "ts,tsx,js" (default: all)
#
# Hooks run outside the Bash sandbox: the result here can differ from a
# command Claude runs sandboxed.

set -uo pipefail

[[ -n "${IZI_CHECK:-}" ]] || exit 0

input="$(cat)"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
stop_hook_active="$(jq -r '.stop_hook_active // false' <<<"$input")"
last_msg="$(jq -r '.last_assistant_message // empty' <<<"$input")"

# A turn that ends with a question to the user is not blocked: forcing it
# to continue would make Claude "fix" things instead of asking.
trimmed="${last_msg%"${last_msg##*[![:space:]]}"}"
[[ "$trimmed" == *"?" ]] && exit 0

root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

ext_re=".*"
if [[ -n "${IZI_CODE_EXT:-}" ]]; then
  ext_re="\\.(${IZI_CODE_EXT//,/|})$"
fi

# git status covers modified, staged and untracked files, and works without HEAD.
mapfile -t changed < <(
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
hash="$( { printf '%s\n' "${changed[@]}"; ((${#existing[@]})) && cat -- "${existing[@]}"; printf '%s' "$IZI_CHECK"; } 2>/dev/null | sha1sum | cut -d' ' -f1)"

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
{
  echo "Quick gate failed (IZI_CHECK). Fix the cause; don't weaken tests or suppress errors."
  tail -n 60 <<<"$out"
} >&2
exit 2
