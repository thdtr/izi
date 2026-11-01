---
name: spec
description: Interviews you about a feature and writes docs/specs/<slug>.md with done criteria and verifiable vertical slices. The starting point for every new feature.
disable-model-invocation: true
model: opus
effort: high
argument-hint: "roadmap slug, #issue, or feature description (empty: roadmap and open issues)"
---

# spec

Feature: $ARGUMENTS

This skill runs on Opus only until the end of this turn: the interview
and the approval go through `AskUserQuestion`, never by waiting for a
free-text reply. If `AskUserQuestion` isn't available (`claude -p`, another harness),
ask the same questions as text, at most 4, and stop until they're
answered.

## 1. Context before asking

No argument: show what can be picked up next.

- The `Roadmap` of `docs/PROJECT.md` with each item's status, taken from
  the specs. An item's specs are `docs/specs/<slug>.md` plus every spec
  whose `Roadmap:` line names the item, so an item split into several
  specs still adds up. Shipped: it has specs and all of them say
  `Status: shipped`. In progress: some spec without it. Not started: no
  spec. Older roadmaps: `[x]` counts as shipped, and a numbered item
  matches the specs whose `Roadmap:` line names its number.
- The open issues, when the repository has a GitHub remote:
  `gh issue list --state open --limit 20 --json number,title,assignees`,
  with number, title and assignee (none = free). If `gh` fails or there
  is no remote, leave this part out without comment.

Ask with `AskUserQuestion` which one to spec, recommending the first
roadmap item not started; the options hold up to 4, and anything else
in the list can be typed. An issue picked here follows the `#<n>` path
below.

Argument:

- a roadmap slug: that item is the feature, and its slug is the spec's;
- `#<n>`: an issue. Read it with `gh issue view <n>`, assign yourself
  (`gh issue edit <n> --add-assignee @me`), so the other dev sees who
  took it, and slug it from its title;
- anything else: a description of the feature.

Read `docs/PROJECT.md` and the code the feature touches (broad search:
`Explore`). Pick the size of the process:

- The diff fits in one sentence: not a feature. Say so and point to
  `/izi:fix` (with the issue number, if it came from one).
- One small slice with no data, permission or UX decision: say it
  doesn't need a spec and suggest plan mode (Shift+Tab) or just asking
  for it directly.
- Otherwise, keep going.

## 2. Interview only the hard parts

`AskUserQuestion`, up to 4 questions per call, recommended option first,
3 rounds at most. Don't ask what the code, `PROJECT.md` or `AGENTS.md`
already answer. Dig into:

- what the end user sees when it works and when it goes wrong
- who can do what (roles, tenant)
- data changes: model, migration, existing data
- edge cases and states (empty, plan limits, concurrency)
- what is explicitly left out

Vague answer on a decision that changes data, permissions or UX: ask
again, concretely. Minor detail: decide and record it in `Decisions`.

## 3. Write `docs/specs/<slug>.md`

Slug: short kebab-case. Format:

```markdown
# <Feature>

Roadmap: <slug of the roadmap item, if any>
Issue: <#n, if it came from one>

## Problem
## Done when
- [ ] <criterion a user or a test can observe>
## Out of scope
## Decisions
- <data/model, contracts, authz rule, migration (expand/contract?)>
## Slices
### 1. <end-to-end behavior>
- [ ] done
- Verification: `<test command>` + <what to look for in the app, if UI>
### 2. ...
## Risks
## Notes
```

Slice rules:

- Vertical: each one cuts through whatever database + server + UI it
  needs and delivers behavior that can be tested on its own. Never
  "create tables", "create endpoints", "create screen".
- The first one is the smallest end-to-end version; the next ones extend
  it.
- Each one has a verification command that would fail without it.
- A slice that doesn't fit in one work session: split it.
- Record decisions and signatures, not code: the implementation is
  build's job.

## 4. Builder check

Delegate to the `izi:spec-check` subagent, passing the spec path, and
wait for its answer in this turn. `detail` items: decide and record them
in `Decisions`. `decision` items go to the user in the approval round.

## 5. Approval

Show the file path and a 5-10 line summary (slices + decisions the user
didn't make explicitly) and, in the same turn, ask with
`AskUserQuestion`: the open `decision` items, if any, and approval
(approve | adjust), up to 4 questions per call. Record the answers in
the spec. Adjustments: edit and ask again.

Once approved: update main (`git switch main`, then `git pull` if there
is a remote), `git switch -c feat/<slug>`, commit the spec
(`docs: spec <slug>`). Tell the user: `/clear` and then
`/izi:build <slug>`.
