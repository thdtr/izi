---
name: ship
description: Wraps up the current branch - pending review, records, push, PR, CI and, if asked, production deploy.
disable-model-invocation: true
model: sonnet
argument-hint: "[prod] to also promote to production"
---

# ship

## 1. Preconditions

- Current branch is not `main`; commit whatever is left.
- `feat/` branch: every slice in the spec is checked and `Notes` has
  `Review: <sha> no blockers`, with no code commits after that sha (only
  `docs:`). Otherwise, run step 4 of `/izi:build` and come back.
- `fix/` branch: invoke the `code-review` skill with `low` and fix the
  blockers.
- Diff touches auth, sessions, permissions, billing, webhooks or uploads:
  with an `origin` remote, also invoke `security-review` (it compares
  against origin's default branch) and fix what's real. Without one, say
  the security review was skipped and why.
- Full gate from `AGENTS.md`: run it only if it hasn't passed on this
  HEAD in this session. Failed: fix via `izi:fix`.

## 2. Records

`feat/` branch: add `Status: shipped` on the line below the spec's
title, so it reads as a record of what was built, not a live contract.
That line is what marks the roadmap item as done: don't edit
`docs/PROJECT.md`, so two open PRs never conflict there. Commit
`docs: ship <slug>`.

## 3. PR

No remote or no `gh`: warn that there will be no CI and offer, with
`AskUserQuestion`, `git switch main` + `git merge --squash <branch>`.

With a remote:

1. `git fetch origin` and `git merge origin/<default branch>`, never
   rebase: the branch may already be published and force push is denied.
   Conflict: resolve it keeping both sides' intent. If the merge brought
   changes, run the full gate again.
2. `git push -u origin HEAD` (asks for confirmation).
3. `gh pr create` with title = the effect of the change; body with a 3-5
   line summary, link to the spec, how it was verified, migrations and
   deploy order (if any), and review suggestions that weren't applied.
   The spec's `Issue:` line, or an `(#<n>)` in the branch's commits:
   `Closes #<n>` in the body. Write the body with the Write tool to a
   file outside the repository (the scratchpad or the system temp
   folder) and run `gh pr create --title "..." --body-file <file>` on
   one line: a multi-line body, backticks or `$(...)` in the command
   keep it inside the sandbox, where `gh` can't reach the token.
   `gh` answering HTTP 401 or "not logged in" inside the sandbox is that,
   not a missing login: run the same command again with the sandbox off
   (it asks first), never ask the user for `gh auth login`.
4. `gh pr checks --watch` with `run_in_background`: CI outlasts the Bash
   timeout. Wait for the notification, don't keep polling. Right after
   the push GitHub may not have registered the checks yet, and the
   command ends at once with "no checks reported": that is not a result.
   Run the same command again, a few times at most, since GitHub
   registers them within seconds. A repository with no CI at all is the
   only case where it stays that way: say so instead of calling the PR
   green.
5. CI failed: read the log (`gh run view --log-failed`), fix via
   `izi:fix`, push, repeat. Green: share the PR link and the preview
   link, if there is one, and say what comes after the merge: `/clear`,
   then `/izi:spec` to see what's next.

The merge is the user's call. Only run
`gh pr merge --squash --delete-branch` if they ask, and only with every
check finished and green (`gh pr checks` with nothing pending or
failing). A check still running is not green: wait for it, even when
the change doesn't seem to touch what it tests. Then
`git switch main`, `git pull`, delete the local branch, and repeat the
next step: `/clear`, then `/izi:spec`.

## 4. Production

Only with `$ARGUMENTS` = `prod` or an explicit request, after the merge,
following the Deploy section of `AGENTS.md`: migrations first, then the
app; explicit confirmation before each production command. Run the
health check and show the result. Failed: offer the rollback from
`AGENTS.md` right away, then investigate with `izi:fix`.
