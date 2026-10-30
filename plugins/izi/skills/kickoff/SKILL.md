---
name: kickoff
description: Sets up the project for the izi workflow - AGENTS.md, settings with permissions, sandbox and gates, architecture decisions, vertical roadmap and CI. Once per project, new or existing; run it again on a new machine to set that machine up.
disable-model-invocation: true
model: opus
effort: high
argument-hint: "[short product description, optional]"
---

# kickoff

User context: $ARGUMENTS

This skill runs on Opus only until the end of this turn. Every user
confirmation goes through `AskUserQuestion`, never by waiting for a
free-text reply. If `AskUserQuestion` isn't available (`claude -p`, another harness),
ask the same questions as text, at most 4, and stop until they're
answered.

Templates: `${CLAUDE_SKILL_DIR}/templates/`. Sandbox profile and
per-stack commands: `${CLAUDE_SKILL_DIR}/reference/sandbox.md`. Project
that already has code: also `${CLAUDE_SKILL_DIR}/reference/adopt.md`.

## 1. Survey what already exists

No git repo: `git init -b main`. Read manifests and lockfile
(`package.json`, `go.mod`, `pyproject.toml`...), configs (tsconfig,
eslint/biome/prettier, framework, ORM, test runner, playwright),
`.github/workflows/`, folder structure, `docs/`, and any existing
`CLAUDE.md`, `AGENTS.md` and `.claude/`. Large repo: delegate to
`Explore`. If the code answers it, don't ask.

Existing skills, agents or hooks in `.claude/` that do the same job as
izi's (spec, build, fix, ship, review, exploration, formatting, Stop
gate): list them in the step 3 plan for removal, so nothing is
duplicated.

Linux and WSL2: the sandbox needs `bwrap` and `socat`. A missing one
goes into the step 3 plan with its install command (`sudo apt install
bubblewrap socat`, `sudo dnf install bubblewrap socat`).

Native Windows (platform `win32`; WSL counts as Linux): check from Bash
that `bash`, `jq` and `gh` resolve. A missing one goes into the step 3
plan with its install command (`winget install jqlang.jq`,
`winget install GitHub.cli`). Hooks only work once Git Bash and jq are on
the system `PATH`.

Already set up by izi (`AGENTS.md` and `IZI_CHECK` in
`.claude/settings.json` exist): someone joining, or a re-run. Don't
interview and don't touch committed files. Only set up this machine:
the `allowWrite` cache paths from step 4, `gh auth status`, and whether
`izi` is installed (otherwise:
`claude plugin install izi@izi --scope project`). Report what you did;
`git status` stays clean. A full redo only if the user asks for it.

## 2. Interview only what's missing

`AskUserQuestion`, up to 4 questions per call, recommended option first.
New project, product: what it is, the problem, audience, v1 scope, out of
scope. Open decisions (new or existing):

- Language, framework, package manager, database/ORM
- Auth and multi-tenancy (how many tenants can a user belong to?)
- Billing (Stripe? plans? trial?) and how to test webhooks locally
- Transactional email
- Hosting: git-based deploy (preview per PR?) or by command; where
  migrations run; health check
- Observability (errors and logs) and database backups
- Tests: runner, database in tests (in-process or container), e2e
- Local services (docker, database on the host) that commands need to
  reach: this decides the sandbox `excludedCommands`
- UI: is there an interface? Define `docs/DESIGN.md` now?

Risky fields are never inferred without confirmation: "Do not touch",
deploy, rollback and production commands.

## 3. Write plan

In one message, list every file to create or change and the decisions
made (adopting: the inventory table from `adopt.md`, including what gets
deleted); in the same turn, ask for a single confirmation with
`AskUserQuestion`. Existing file: show the diff of what changes and never
remove the user's content without saying so.

## 4. Write

Files under `.claude/` only with Write/Edit (the sandbox blocks Bash
there).

- `AGENTS.md` from the template: fill in every `<...>`, delete lines that
  don't apply. ~60 lines max; only facts that change behavior. Nothing
  the model already does by default or that the code reveals.
- `CLAUDE.md` with `@AGENTS.md`. If it already exists with content, move
  the project facts into `AGENTS.md` and leave the import at the top.
- `.claude/settings.json` from the template, merged with the existing one:
  - `env`: `IZI_FORMAT`, `IZI_CHECK` and `IZI_CODE_EXT` from the
    per-stack table in the reference, adapted to the project's runner.
    More than one stack: the scripts from "More than one stack" in the
    reference. Test both commands once before saving.
  - `sandbox`, `permissions.ask` and telemetry in `env` according to the
    reference and the answers from step 2. Remove `ask` lines for tools
    the project doesn't use. Only settings that hold on every OS go
    here: the file is shared through git.
  - Keep `extraKnownMarketplaces` and `enabledPlugins` from the template.
- `.claude/settings.local.json`, merged: the
  `sandbox.filesystem.allowWrite` cache paths from the reference for this
  machine's OS. They depend on the machine, so the file isn't committed
  (the `.gitignore` template covers it), and Claude Code merges it with
  the project's settings. Never edit `~/.claude/settings.json`. The
  sandbox can't create these folders: give the user one
  `! mkdir -p <paths>` line for the ones that don't exist yet. Native
  Windows has no sandbox: skip this, say so, and suggest Auto mode to cut
  permission prompts.
- `.claude/agents/Explore.md` from the template (exploration on Haiku).
- `.claude/rules/tests.md` and, if there is UI, `.claude/rules/ui.md`:
  fill in the `<...>` and adjust `paths:` to the real structure.
- `docs/PROJECT.md` from the template. Roadmap = shippable vertical
  slices, one per line, each with a kebab-case slug that will be its
  spec's slug; the first one is the walking skeleton (login + 1 real
  screen + deploy + green CI), or, adopting, what `adopt.md` says. Never
  layer-by-layer steps. Business rules: the critical invariants, with
  their origin.
- `docs/DESIGN.md` from the template, only if there is UI and the user
  wants it now.
- Verifiable architecture (TS): `dependency-cruiser` as a devDependency,
  `.dependency-cruiser.cjs` from the template with the layer rules that
  the PROJECT.md decisions imply, and `depcruise src` inside the `lint`
  script. Other languages: the equivalent, if there is one (e.g.
  import-linter in Python); otherwise, skip it.
- `lint`, `typecheck`, `test`, `build` scripts in the manifest (TS:
  `package.json`); CI and the full gate in AGENTS.md use these names.
- `.github/workflows/ci.yml` from the template: swap the package manager
  and language if it isn't pnpm/Node; safe placeholders for env vars the
  build requires.
- `.gitignore`: make sure it has the lines from `templates/gitignore`.
- `.gitattributes`: make sure it has the lines from
  `templates/gitattributes` (scripts stay in LF on Windows).
- `.worktreeinclude` from `templates/worktreeinclude` (copies `.env` into
  `claude -w` worktrees).
- `.env.example` with the variables the code reads, no values.

## 5. Wrap up

Run the full gate once and report command + result. Then say, in 5 lines
or fewer:

- if the language has an official LSP plugin and it isn't installed:
  `/plugin install <lang>-lsp@claude-plugins-official` (e.g.
  `typescript-lsp`, `gopls-lsp`, `pyright-lsp`);
- if there is UI or a server: run `/run-skill-generator` once, so
  verification in the running app works;
- suggested commit: `chore: set up izi workflow` (adopting: first
  `chore: remove <workflow> artifacts` with only the deletions);
- next step: `/izi:spec <first roadmap slug>`.
