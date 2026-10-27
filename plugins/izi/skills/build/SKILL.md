---
name: build
description: Implements the slices of an approved spec in docs/specs/, one at a time, with a test and a commit per slice, and finishes with an independent review.
disable-model-invocation: true
model: sonnet
argument-hint: "spec slug (default: the one from the feat/<slug> branch)"
---

# build

Spec: $ARGUMENTS

## 1. Load

Open `docs/specs/<slug>.md`; with no argument, the slug comes from the
`feat/<slug>` branch. Make sure you're on that branch. Spec with no
slices, or not on a `feat/` branch: stop and point to `/izi:spec`.

## 2. For each unchecked slice, in order

1. Write or adjust the test that expresses the slice's behavior and watch
   it fail for the right reason.
2. Implement the minimum to make it pass, following `AGENTS.md`. The
   quick gate runs on its own before every commit and at the end of the
   turn: fix whatever it reports.
3. Run the slice's `Verification`. UI slice: check it in the running app
   (`run` skill), not just in the code.
4. Check the box and commit `feat(<slug>): <observable effect>`, without
   asking for confirmation. The user audits in the PR.

Unexpected bug along the way: follow the `izi:fix` skill (root cause
before the fix) and go back to the slice.

## 3. When the spec isn't enough

- A decision that changes data, permissions, UX or scope: ask with
  `AskUserQuestion`; record the answer in `Decisions`.
- Minor detail: decide and record it in one line in `Notes`.
- Slice bigger than expected: split it in the spec itself before moving on.

## 4. Finish

With every slice checked:

1. Run the full gate from `AGENTS.md` once.
2. Review, in parallel:
   - invoke the `code-review` skill with the argument `high` (bugs and
     correctness);
   - delegate spec compliance to the `izi:reviewer` subagent, passing the
     spec path and the base branch (`main`, or the remote's default).
3. Fix the blockers following `izi:fix`. A suggestion you don't apply
   goes into `Notes` with the reason. Don't chase findings that don't
   affect correctness or requirements.
4. Check the `Done when` items you verified and record in `Notes`:
   `Review: <short HEAD sha> no blockers`. Commit.
5. Tell the user: next step is `/izi:ship`.
