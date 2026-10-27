# Changelog

Each version here is the `version` in `plugins/izi/.claude-plugin/plugin.json`.
Installed copies update only when that number changes.

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
