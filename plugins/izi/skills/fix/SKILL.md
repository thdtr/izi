---
name: fix
description: Fixes a bug or makes a small change outside a spec - reproduces, finds the root cause, fixes and verifies. Use it for any bug, unexpected error, broken test or one-off tweak (text, styling, config).
argument-hint: "bug symptom or the change you want"
---

# fix

Target: $ARGUMENTS

## 0. Scope

- Needs new behavior, several modules, or a product/data decision: not a
  fix. Point to `/izi:spec` and stop.
- `EACCES`, `Read-only file system`, `Network is unreachable` or a
  blocked host: that's the sandbox, not the code. State the command and
  the path/host and propose the change in `.claude/settings.json`; don't
  edit code.
- On main: `git switch -c fix/<slug>`. Inside a feature in progress:
  stay on its branch.

## 1. Bug: root cause before any edit

1. Reproduce: a test that fails with the symptom, or the command that
   shows it. Project with no test setup: reproduce through the command or
   the running app (`run` skill) and, if you can, write a
   characterization test of the current behavior before changing
   anything. No reproduction, no fix: say what's missing to reproduce it.
2. Locate it by reading the code along the symptom's path (broad search:
   `Explore`).
3. State the cause in 1-3 lines with `file:line` and why it produces the
   symptom. Go straight to the fix, unless it touches "Do not touch" in
   `AGENTS.md` or changes a public contract. In that case, ask with
   `AskUserQuestion`.
4. Fix the cause, not the symptom: no suppressing errors, `as any`,
   `@ts-ignore`, `skip` or loosening tests.
5. Run the reproduction and the related tests.

Two attempts without solving it: stop. Write down what you tried, what
each attempt assumed and what the evidence disproved (in `Notes` of the
active spec, if there is one, otherwise in your reply). Point out the
shared assumption that hasn't been checked yet and suggest `/clear` with
that summary.

## 2. Tweak (not a bug)

Edit and run whatever verification exists (test, build, running app).

## 3. Commit

`fix: <effect>` or `chore: <effect>`, without asking for confirmation.
Outside a feature in progress, the next step is `/izi:ship`.
