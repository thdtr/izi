# Changelog

Each version here is the `version` in `plugins/izi/.claude-plugin/plugin.json`.
Installed copies update only when that number changes.

## 1.6.0 - 2026-10-30

### Fixed

- Multi-stack `scripts/izi-check.sh` ran the same command for the quick
  and the full gate. Each stack now has a quick check (the stacks a
  change touches) and a full check (`--all`, and `<stack>` in CI).
  Projects that already copied the script: split each line into
  `name|directory|quick|full`.
- README said auto-update had to be turned on by hand; projects set up
  by kickoff already have it on.

### Changed

- Sandbox cache paths go to the project's `.claude/settings.local.json`
  (not committed) instead of `~/.claude/settings.json`.
- Kickoff checks `bwrap` and `socat` on Linux and WSL2.
- Kickoff and spec ask as text when `AskUserQuestion` isn't available
  (`claude -p`, other harnesses), at most 4 questions, and stop.
- Quicker quick gates in the reference: PHP with `pest --dirty`, Python
  with `pytest-testmon`, Dart analyzing only the changed files.
- Both READMEs rewritten, about half as long.

## 1.5.0 - 2026-10-30

### Added

- More than one stack in a repository: kickoff copies
  `scripts/izi-check.sh` (quick gate only for the stacks a change
  touches, `--all` for the full gate, `<stack>` for a CI job) and
  `scripts/izi-format.sh` (formatter by directory and extension). The
  hooks don't change.
- Sandbox and gate rows for Dart/Flutter and PHP.
- `tests/templates.sh`, run in CI on Linux, Windows and macOS.

## 1.4.0 - 2026-10-30

### Added

- Adopting an existing project: kickoff reads
  `reference/adopt.md`, lists what the previous workflow left (Cursor and
  other agents' rules, spec kits, plans folders, TODOs) with one
  destination each (`AGENTS.md`, `.claude/rules/`, business rules,
  roadmap or deletion), and puts the deletions in their own commit. The
  roadmap comes from the code: no walking skeleton, and `green-gate`
  first when tests, lint or CI are missing.
- `docs/PROJECT.md` gets a "Business rules" section: the critical
  invariants, with their origin. The `reviewer` agent checks the diff
  against them.
- Eval `kickoff-adopts-old-workflow`.

## 1.3.0 - 2026-10-30

### Added

- `/izi:spec` with no argument shows the roadmap with each item's
  status, taken from the specs, and suggests the next one.
- GitHub issues, optional: `/izi:spec #42` and `/izi:fix #57` read the
  issue and assign you; `/izi:ship` adds `Closes #<n>` to the PR. Claude
  offers to open an issue for a problem outside the task, only with your
  OK. Kickoff's settings allow `gh issue view/list` and ask before
  `gh issue create/edit`.
- README: "Working with two people".
- Evals `spec-lists-roadmap-status` and `ship-leaves-project-alone`.

### Changed

- Roadmap items have a slug, the slug of their spec, and no checkbox: an
  item is done when its spec says `Status: shipped`. `/izi:ship` no
  longer edits `docs/PROJECT.md`, so two open PRs never conflict there.
  Older roadmaps keep working: `[x]` counts as done, and a numbered item
  matches the spec whose `Roadmap:` line names it.
- `/izi:ship` merges the default branch into the feature branch before
  pushing (never rebase; force push is denied).

## 1.2.0 - 2026-10-30

### Added

- Kickoff in a project that izi already set up only sets up the machine
  of whoever runs it (sandbox caches, `gh`, the plugin install) and
  leaves the committed files alone. Run it once when you join a project.
- Kickoff on native Windows checks that `bash`, `jq` and `gh` are found,
  skips the sandbox cache paths (there is no sandbox there) and suggests
  Auto mode.
- Kickoff adds `.gitattributes` so shell scripts stay in LF on Windows.
- Eval `kickoff-joins-existing-setup`.

## 1.1.0 - 2026-10-30

### Added

- Commits made through the PowerShell tool go through the secret scan and
  the quick gate, like Bash commits.
- Kickoff's `settings.json` repeats the Bash permission rules for
  PowerShell (force push denied; push, merge and `reset --hard` ask), so
  they hold on Windows too. Existing projects: copy the `PowerShell(...)`
  lines from the template into `.claude/settings.json`.
- README: "Windows and the desktop app", installing from the desktop app,
  and the one-time install for someone joining a project.

### Fixed

- The quick gate and the secret scan could block a command that isn't a
  commit: Claude Code runs a hook's `if` filter on a best-effort basis
  and fires it for any command with `$VAR`, `$()` or a loop. Both scripts
  now check that the command really runs `git commit`. Found on Windows,
  but it happened on every OS.

### Changed

- README: auto-update is off by default for this marketplace; it says how
  to turn it on instead of promising it.

## 1.0.1 - 2026-10-30

### Fixed

- Windows: the quick gate let every change through and formatting never
  ran when `jq.exe` was used inside Git Bash, because its output ends in
  CRLF. The scripts now drop the `\r`, and `.gitattributes` keeps them
  in LF.
- Without `jq`, the hooks skip with a warning instead of blocking every
  turn.
- macOS: the quick gate never ran on the system's bash 3.2 (`mapfile`,
  `sha1sum`).
- Hook tests in `tests/hooks.sh`, run in CI on Linux, Windows and macOS.

## 1.0.0 - 2026-10-27

First versioned release. Before it, every commit on `main` reached users
as soon as their marketplace refreshed.

### Added

- `izi:spec-check` agent: before you approve a spec, it reads it as the
  engineer who will build it and lists what is still open.
- Plugin evals in `plugins/izi/evals/`, run with `claude plugin eval`.

### Changed

- The quick gate also runs before every commit. `build` and `fix` commit
  inside the turn, so the end-of-turn check used to find nothing to check.
- A failed end-of-turn gate reaches Claude as Stop hook feedback instead
  of a hook error.
- `build`, `fix` and `ship` pick Sonnet in their own frontmatter. Projects
  no longer pin a model, so each person's `/model` applies elsewhere.
- `fix` triggers on its own only for things that are broken; one-off
  tweaks go through `/izi:fix`.
- `/izi:ship` marks the spec `Status: shipped`, and runs `security-review`
  only when there is an `origin` remote.
- Kickoff: OS-specific sandbox cache paths go to each person's
  `~/.claude/settings.json`; CI runs the gitleaks binary, which needs no
  license key on organization repositories; the AGENTS.md template drops
  lines current models no longer need; `.gitignore` covers the sandbox's
  phantom files at the project root
  ([claude-code#78419](https://github.com/anthropics/claude-code/issues/78419)).
