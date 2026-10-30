# Sandbox profile per stack

Reference for /izi:kickoff to adjust `sandbox`, `env` and `permissions`
in `.claude/settings.json`. The template already covers the pnpm and
GitHub domains. `allowWrite` cache paths depend on the machine, so they
go to `.claude/settings.local.json`, which isn't committed and which
Claude Code merges with the project's settings.

## Facts behind the profile

- Only Bash runs in the sandbox. Read/Edit/Write, hooks, MCP and LSP run
  outside it.
- `Read(...)`/`Edit(...)` denies in permissions also apply to sandboxed
  processes: denying `Read(./.env)` makes `next build`, vitest, prisma
  etc. run without env. That's why the template doesn't deny reading
  `.env`; the local `.env` should only hold dev/test credentials.
- Always write-protected, with no possible exception: `.claude/**`
  (settings, skills, agents, hooks), `.git/config`, `.git/hooks`,
  `.vscode/`, `.idea/`. Consequences: `git push -u` and `lefthook install`
  fail in the sandbox; an npm package that ships a `.vscode/` folder
  breaks the install.
- On Linux, the machine's `localhost` can't be reached from inside the
  sandbox. A command can only reach servers it started itself.
- Outside the project directory and TMPDIR, it only writes where
  `allowWrite` allows. `~/.npm` and `~/.cache` are blocked by default.
- Network: only `allowedDomains`. A host not on the list asks for
  confirmation in manual mode and is refused in auto mode.
- `excludedCommands` matches on text: every command in the call has to
  match; `cd`, a pipe into another command, a redirect to a file and
  `$(...)` keep the call in the sandbox. `x *` matches `x` with or
  without arguments. An excluded command goes through the normal
  permission flow.
- Prefer `allowWrite`/`allowedDomains` over excluding a whole command.
- On Linux and WSL2, a protected path that doesn't exist (`.bashrc`,
  `.mcp.json`, `.vscode`, `.claude/hooks`...) shows up inside the sandbox
  as a character device: git lists it as untracked and `git add .` fails.
  The `.gitignore` template covers the root ones; the rest is handled by
  staging files by name.

## Package manager

`allowWrite` goes to `.claude/settings.local.json`; `allowedDomains` to
the project's settings.

| PM | `allowWrite` | `allowedDomains` |
|---|---|---|
| pnpm | `~/.local/share/pnpm`, `~/.cache/pnpm` (macOS: `~/Library/pnpm`, `~/Library/Caches/pnpm`) | `registry.npmjs.org` |
| npm | `~/.npm` | `registry.npmjs.org` |
| yarn | `~/.cache/yarn`, `~/.yarn` (macOS: `~/Library/Caches/Yarn`, `~/.yarn`) | `registry.yarnpkg.com`, `registry.npmjs.org` |
| bun | `~/.bun/install/cache` | `registry.npmjs.org` |
| Go | `~/go/pkg/mod`, `~/.cache/go-build` (macOS: `~/go/pkg/mod`, `~/Library/Caches/go-build`) | `proxy.golang.org`, `sum.golang.org` |
| Python (uv) | `~/.cache/uv`, `~/.local/share/uv` | `pypi.org`, `files.pythonhosted.org` |
| Dart/Flutter (pub) | `~/.pub-cache`, plus the Flutter SDK's `bin/cache` the first time it downloads artifacts | `pub.dev`, `storage.googleapis.com` |
| PHP (Composer) | `~/.cache/composer` or `~/.composer/cache` (macOS: `~/Library/Caches/composer`) | `repo.packagist.org`; packages come from `codeload.github.com` |

pnpm with `packageManager` pinned to a different version can hang
silently in the sandbox: match the installed version to the one in
`package.json`.

## Common tools

| Tool | Adjustment |
|---|---|
| Next.js | `env`: `NEXT_TELEMETRY_DISABLED=1`. `next/font/google` at build time: `fonts.googleapis.com`, `fonts.gstatic.com` |
| Turborepo | `env`: `TURBO_TELEMETRY_DISABLED=1` |
| Prisma | `allowWrite`: `~/.cache/prisma`; `allowedDomains`: `binaries.prisma.sh`; `env`: `CHECKPOINT_DISABLE=1` |
| Playwright | `allowWrite`: `~/.cache/ms-playwright` (macOS: `~/Library/Caches/ms-playwright`); e2e in `excludedCommands` (browser inside the sandbox and server on the host) |
| Docker / docker compose | Incompatible: `excludedCommands` with the exact subcommand, e.g. `docker compose *` |
| Local database (Postgres/Redis in a container) | Tests that connect to it go in `excludedCommands` (e.g. `pnpm test *`), or use an in-process database in tests (PGlite, SQLite) and keep them in the sandbox |
| Vercel CLI | Already `ask`; `allowedDomains`: `api.vercel.com`, `vercel.com` |
| Stripe CLI | `excludedCommands`: `stripe listen *` (long-lived connection) |
| gh | Already excluded for `pr`/`run`/`issue`: the token may be in the keyring, which the sandbox can't reach |
| Signed commits (GPG/SSH) | `git commit *` in `excludedCommands` (the key agent is a blocked socket) |

## Format and gate commands per language

| Stack | `IZI_FORMAT` | `IZI_CHECK` | `IZI_CODE_EXT` |
|---|---|---|---|
| TS + Prettier + ESLint + Vitest | `pnpm exec prettier --write --ignore-unknown --log-level=silent` | `pnpm exec tsc --noEmit --incremental && pnpm exec eslint --max-warnings=0 --no-warn-ignored $IZI_CHANGED && pnpm exec vitest related --run --passWithNoTests $IZI_CHANGED` | `ts,tsx,js,jsx,mjs,cjs` |
| TS + Biome | `pnpm exec biome format --write --no-errors-on-unmatched` | `pnpm exec tsc --noEmit --incremental && pnpm exec biome check --no-errors-on-unmatched $IZI_CHANGED && pnpm exec vitest related --run --passWithNoTests $IZI_CHANGED` | `ts,tsx,js,jsx,mjs,cjs` |
| TS + Jest | (same) | replace vitest with `pnpm exec jest --findRelatedTests --passWithNoTests $IZI_CHANGED` | |
| Go | `gofmt -w` | `go vet ./... && go test ./...` (Go caches the tests of unchanged packages, so this stays quick) | `go` |
| Python (ruff + pytest) | `ruff format` | `ruff check $IZI_CHANGED && pytest -q -x --testmon` (with `pytest-testmon`; without it, `pytest -q -x` runs the whole suite) | `py` |
| Dart/Flutter | `dart format` | `dart analyze --fatal-infos $IZI_CHANGED` (the tests run in the full gate: `flutter test`, or `dart test` for pure Dart) | `dart` |
| PHP (Pint + PHPStan + Pest) | `vendor/bin/pint` | `vendor/bin/phpstan analyse --no-progress $IZI_CHANGED && vendor/bin/pest --dirty` (PHPUnit: `vendor/bin/phpunit`) | `php` |

Replace `pnpm exec` with the runner of the project's package manager
(`npx --no-install`, `yarn`, `bunx`). Short output saves tokens: prefer
quiet reporters (`--reporter=dot`, `-q`).

## More than one stack

A repository with stacks in their own directories (say an API and a
mobile app) keeps one quick gate, so a change in one stack doesn't run
the other's tests:

- Copy `templates/izi-check.sh` and `templates/izi-format.sh` to
  `scripts/` and fill one line per stack: its quick check (the
  `IZI_CHECK` column above) and its full check (lint, types, every test
  and build). Each check runs inside its directory; the quick one gets
  `IZI_CHANGED` with only that stack's files, relative to it.
- `env`: `IZI_CHECK` = `scripts/izi-check.sh`, `IZI_FORMAT` =
  `scripts/izi-format.sh`, `IZI_CODE_EXT` = every stack's extensions.
- Full gate in `AGENTS.md`: `scripts/izi-check.sh --all` (every stack's
  full check), one command, so it needs no `cd` in the sandbox.
- CI: one job per stack, running `scripts/izi-check.sh <stack>`. Don't
  filter by `paths` at the workflow level: a required check that gets
  skipped stays pending and blocks the merge.
- Sandbox: the `allowWrite` and `allowedDomains` of every stack.
