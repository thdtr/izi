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
If the spec references a `Roadmap` item in `docs/PROJECT.md`, mark it
`[x]`. Commit `docs: ship <slug>`.

## 3. PR

No remote or no `gh`: warn that there will be no CI and offer, with
`AskUserQuestion`, `git switch main` + `git merge --squash <branch>`.

With a remote:

1. `git push -u origin HEAD` (asks for confirmation).
2. `gh pr create` with title = the effect of the change; body with a 3-5
   line summary, link to the spec, how it was verified, migrations and
   deploy order (if any), and review suggestions that weren't applied.
3. `gh pr checks --watch` with `run_in_background`: CI outlasts the Bash
   timeout. Wait for the notification, don't keep polling.
4. CI failed: read the log (`gh run view --log-failed`), fix via
   `izi:fix`, push, repeat. Green: share the PR link and the preview
   link, if there is one.

The merge is the user's call. Only run
`gh pr merge --squash --delete-branch` if they ask; then
`git switch main`, `git pull` and delete the local branch.

## 4. Production

Only with `$ARGUMENTS` = `prod` or an explicit request, after the merge,
following the Deploy section of `AGENTS.md`: migrations first, then the
app; explicit confirmation before each production command. Run the
health check and show the result. Failed: offer the rollback from
`AGENTS.md` right away, then investigate with `izi:fix`.
