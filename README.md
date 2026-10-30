# IZI

[Leia em português](README.pt-BR.md)

A [Claude Code](https://code.claude.com/docs/en/overview) plugin for solo
developers. You decide what to build and approve the steps that matter.
Claude writes the code and the tests, makes the commits and opens the PR.

The defaults are set up for TypeScript (Node.js or Bun, usually with
Next.js). On Go, Python or another language, `/izi:kickoff` swaps in your
project's commands.

## Before you install

| Tool | What it's for here |
|---|---|
| [Claude Code](https://code.claude.com/docs/en/quickstart), current version | Where IZI runs |
| [git](https://git-scm.com/) | Branches and commits |
| [jq](https://jqlang.org/) | IZI's hooks parse the JSON that Claude Code sends them. Without it, formatting, the quick gate and the secret scan are skipped with a warning |
| [GitHub CLI (`gh`)](https://cli.github.com/) | Opening PRs and watching CI. After installing, run `gh auth login` and [`gh auth setup-git`](https://cli.github.com/manual/gh_auth_setup-git) |
| [bubblewrap](https://github.com/containers/bubblewrap) and [socat](http://www.dest-unreach.org/socat/) | Linux only. The [Claude Code sandbox](https://code.claude.com/docs/en/sandboxing) needs them |
| [gitleaks](https://github.com/gitleaks/gitleaks) (optional) | Looks for passwords and keys before every commit. Without it, that check only runs in CI |

On Windows, see [Windows and the desktop app](#windows-and-the-desktop-app).

## Install

On your machine, once:

```bash
claude plugin marketplace add thdtr/izi
claude plugin install izi@izi
```

In the desktop app, you don't need the terminal. In a local session,
type `/plugin marketplace add thdtr/izi` in the prompt box, accept, then
add the `izi` plugin with the buttons that show up (or later with **+**
next to the prompt box, then **Add plugins**). The terminal and the
desktop app share the same plugin settings, so installing in one is
enough.

In each project, new or already underway, open Claude in its folder and
run:

```text
/izi:kickoff
```

Kickoff reads what's already in the project and only asks about what's
missing. In a project that used another workflow (Cursor rules, a plans
folder, another agent's instructions), it lists each file and where its
content goes: `AGENTS.md`, the business rules and roadmap in
`docs/PROJECT.md`, or deletion. The deletion is its own commit, so you
can undo it alone. Before creating any file, it shows you the list of what it's
going to do and waits for your OK. At the end, it tells you whether to
install the [LSP plugin](https://code.claude.com/docs/en/plugins/code-intelligence)
for your language and run `/run-skill-generator`, which teaches Claude how
to open your app to check the result.

Joining a project that already uses IZI? Its `.claude/settings.json`
turns the plugin on but doesn't download it. Add the marketplace and run
`claude plugin install izi@izi --scope project` once, or, in the desktop
app, install `izi` choosing the project scope. Then run `/izi:kickoff`:
in a project that already has IZI, it only sets up your machine and
leaves the committed files alone.

## How it works

```text
/izi:kickoff            once per project: sets everything up, drafts the roadmap  (Opus)
/izi:spec "feature"  ✋ interviews you and writes docs/specs/<slug>.md;           (Opus)
                        the builder reads it and flags what's missing
/clear
/izi:build <slug>       slice by slice: test, code, commit;                       (Sonnet)
                        an independent review at the end
/izi:ship [prod]     ✋ opens the PR and watches CI; merging is up to you
```

✋ marks where Claude stops and waits for you: approving the spec and
merging the PR. Everywhere else it keeps going on its own, and you review
everything in the PR.

The `/clear` between spec and build wipes the conversation, so the build
starts with just the spec instead of dragging the whole interview along.

## Which command to use

| Situation | Use |
|---|---|
| Feature that involves a decision about data, permissions or UI | `/izi:spec`, then `/izi:build` and `/izi:ship` |
| Small change that touches more than one file | [Plan mode](https://code.claude.com/docs/en/permission-modes) (`Shift+Tab`, or the mode selector in the desktop app) and just ask |
| Bug, broken test or one-off tweak | `/izi:fix "what's happening"` |
| Work from a GitHub issue | `/izi:spec #42` for a feature, `/izi:fix #57` for a bug |
| What's next on the roadmap | `/izi:spec` with no argument |
| Trivial change, like a text tweak or a typo | Just ask |
| Mechanical refactor across many files | [`/batch`](https://code.claude.com/docs/en/commands) |
| Clean up the code that changed | [`/simplify`](https://code.claude.com/docs/en/commands) |
| Two features at the same time | [`claude -w <name>`](https://code.claude.com/docs/en/worktrees) |
| Implement the slices without watching | [`/goal`](https://code.claude.com/docs/en/goal) `every slice in docs/specs/<slug>.md checked and the full gate exits 0` |

## Files kickoff creates

```text
AGENTS.md                 project facts Claude reads in every session
CLAUDE.md                 points to AGENTS.md
.claude/settings.json     check commands, permissions and sandbox
.claude/agents/Explore.md code search on a cheaper model
.claude/rules/            UI and test rules
docs/PROJECT.md           product, architecture decisions and roadmap
docs/DESIGN.md            colors, typography and visual patterns (optional)
docs/specs/<slug>.md      one spec per feature, written by /izi:spec
.dependency-cruiser.cjs   architecture rules checked by lint (TS)
.github/workflows/ci.yml  lint, typecheck, tests, build and secret scanning
.gitattributes            keeps shell scripts in LF on Windows
```

Architecture rules use
[dependency-cruiser](https://github.com/sverweij/dependency-cruiser), and
CI runs on [GitHub Actions](https://docs.github.com/en/actions).

Want to leave a note for yourself in `AGENTS.md`? Put it between `<!--`
and `-->`. Claude never sees that part.

## What happens without you asking

| When | What |
|---|---|
| After every edit | The file gets formatted |
| Before every commit | Types, lint and the tests for the changed files are checked, and gitleaks scans for passwords and keys. If something fails, the commit is blocked and Claude fixes it |
| At the end of every reply that left code uncommitted | The same types, lint and tests check. If something fails, Claude fixes it before stopping |
| On every PR | CI runs everything again |

If Claude ends its reply with a question for you, the check won't force
it to keep going.

The commands live in the `env` block of `.claude/settings.json`, under
`IZI_FORMAT` and `IZI_CHECK`. For TypeScript the defaults use
[TypeScript](https://www.typescriptlang.org/),
[Prettier](https://prettier.io/), [ESLint](https://eslint.org/),
[Vitest](https://vitest.dev/) and [pnpm](https://pnpm.io/). If your
project uses other tools, kickoff adjusts them.

## Models

| Step | Model |
|---|---|
| kickoff and spec | Opus |
| build, fix and ship | Sonnet |
| Reading the spec as its builder | Sonnet |
| Reviewing the code against the spec | Opus |
| Code search | Haiku |

Opus is used where there are architecture and scope decisions to make.
Everything else runs on Sonnet, which costs less. The bug review at the
end of the build uses Claude Code's own
[`/code-review`](https://code.claude.com/docs/en/code-review-local).
Outside IZI's commands, each person's own `/model` choice applies.

## Sandbox

Kickoff turns on the
[Claude Code sandbox](https://code.claude.com/docs/en/sandboxing). With
it, the commands Claude runs are isolated from the rest of your machine
and don't ask for permission at every step. A few things change because
of that:

- Keep only development and test credentials in your local `.env`. The
  sandbox can't tell Claude reading the file apart from your build
  reading it, so reads are allowed. Production secrets belong in your
  hosting provider. The `secrets/` folder stays blocked.
- `git push`, `git pull` and `gh pr` run outside the sandbox and ask for
  your confirmation.
- Commands that use Docker or reach a service on `localhost`, like tests
  against Postgres in a container, need to be in
  `sandbox.excludedCommands`. Kickoff asks you about this.
- Errors like `EACCES`, `Read-only file system`, `Network is unreachable`
  or "host not allowed" come from the sandbox, not from your code. Claude
  is told to say which command failed and what to change in
  `.claude/settings.json`, without touching the code.
- Package manager cache folders depend on the OS, so they live in each
  person's `~/.claude/settings.json`, under
  `sandbox.filesystem.allowWrite`. Kickoff sets up your machine; whoever
  joins the project later adds their own.
- On Linux, while a command runs in the sandbox, protected paths that
  don't exist (`.bashrc`, `.mcp.json`, `.claude/hooks`...) show up as
  untracked files. It's a
  [known bug](https://github.com/anthropics/claude-code/issues/78419).
  Kickoff's `.gitignore` hides the ones at the root, and Claude is told
  to ignore them and to stage files by name.

| If this happens | Do this |
|---|---|
| Claude asks for access to a new domain | Accept it, or add the domain to `sandbox.network.allowedDomains` |
| `pnpm install` fails with `EACCES` on a cache folder | Add the folder to `sandbox.filesystem.allowWrite` in your `~/.claude/settings.json`. The table in `plugins/izi/skills/kickoff/reference/sandbox.md` has the paths for each OS |
| `pnpm` hangs with no error | The `packageManager` version in `package.json` doesn't match the installed one. Make them match |
| `pnpm install` fails on a package that ships a `.vscode/` folder | Run it yourself in the Claude prompt: `! pnpm install` |
| "Yes, don't ask again" doesn't stick | Run `claude doctor` and delete the 0-byte files it lists |
| A command you excluded still runs in the sandbox | Ask Claude to run that command on its own, without `cd`, pipes or `&&` |

## Working with two people

IZI is built for one developer, and nothing changes for that. When a
second person joins (the repository owner adds them as a collaborator),
the same commands are enough:

- The roadmap in `docs/PROJECT.md` stays the direction: a short list of
  the next slices, each with the slug of its spec. An item is done when
  its spec says `Status: shipped`, so nobody edits the list and two open
  PRs never conflict there.
- Issues are the inbox for everything else: bugs, improvements, ideas.
  Claude offers to open one when it finds a problem outside the task, and
  only opens it after your OK. Labels: `bug` and `improvement`.
- Whoever takes an issue is its assignee: `/izi:spec #42` and
  `/izi:fix #57` assign you and close the issue when the PR merges.
- Before pushing, `/izi:ship` merges the latest `main` into the branch
  instead of rebasing, since force push is blocked.
- Merging stays a human decision, and green CI is the only hard rule.
  Whether a private repository can enforce branch protection depends on
  your GitHub plan; when it can't, it's a convention.

## Windows and the desktop app

IZI runs on native Windows, in the terminal and in the desktop app.

- Install [Git for Windows](https://git-scm.com/download/win): IZI's hooks
  run in its Git Bash. Then install jq with `winget install jqlang.jq`.
  If Claude Code doesn't find Git Bash on its own, point
  `CLAUDE_CODE_GIT_BASH_PATH` to its `bash.exe`
  (usually `C:\Program Files\Git\bin\bash.exe`).
- Both have to be on the `PATH` in your user or system environment
  variables. The desktop app doesn't read your PowerShell profile; after
  changing the `PATH`, quit and reopen it.
- Native Windows has no sandbox, so commands ask for permission more
  often. Auto mode cuts most of those prompts.
- Commits made through the PowerShell tool go through the same checks as
  Bash, and the same permission rules apply.
- In the desktop app, plugins load in local and SSH sessions, not in WSL
  or cloud sessions. `/izi:` commands work the same way; switch modes with
  the selector under the prompt box instead of `Shift+Tab`.
- WSL2 also works and has the sandbox, like Linux. Use it from the
  terminal, since the desktop app doesn't load plugins there. Keep the
  repository inside WSL (`~/`), not under `/mnt/c`.

## Maintenance

- To update IZI, open `/plugin`, go to Marketplaces, pick `izi`, then
  Update marketplace. Auto-update is off by default for marketplaces like
  this one; to turn it on, pick **Enable auto-update** on the same screen.
  Each person does this on their own machine. What changed in each version is in [CHANGELOG.md](CHANGELOG.md). More
  in the [plugin docs](https://code.claude.com/docs/en/plugins/install).
- When a new model comes out, run `/doctor prompt-audit` and delete the
  instructions the model already follows without being told. Extra
  instructions get in the way.
- `/usage` shows where your tokens are going.
- CI runs `pnpm audit` every week. To update dependencies automatically,
  turn on [Dependabot](https://docs.github.com/en/code-security/dependabot)
  or [Renovate](https://docs.renovatebot.com/).

## Contributing

```text
.claude-plugin/marketplace.json   the "izi" marketplace
plugins/izi/
  skills/      kickoff, spec, build, fix, ship
  agents/      reviewer, spec-check
  hooks/       hooks.json
  scripts/     hook scripts
  evals/       cases that measure what the plugin adds
tests/hooks.sh                    hook script tests
```

To try a change without publishing it, run
`claude --plugin-dir ./plugins/izi`. Before publishing, run
`claude plugin validate .`. After changing a hook script, run
`bash tests/hooks.sh`; CI also runs it on Linux, Windows and macOS.

An installed copy only changes when `version` changes, so reinstalling
the same version keeps the old files. To try an unreleased change from a
branch in the desktop app, close it, delete `~/.claude/plugins/cache/izi`,
then reinstall.

The [evals](https://code.claude.com/docs/en/plugin-evals) run each case
with and without the plugin and show the difference. Run them after
changing a skill and when a new model comes out:

```bash
cd plugins/izi
claude plugin eval . --scaffold --allow-tools Edit "Bash(git *)"
```

Each run counts against your plan. To try a single case, add
`--case <name>`.

### Releasing

Installed copies update only when `version` in
`plugins/izi/.claude-plugin/plugin.json` changes, so a commit to `main`
without a new version reaches no one.

1. Bump `version` following [semver](https://semver.org/): patch for a
   fix, minor for a new behavior, major when a project set up by kickoff
   has to change.
2. Add a `## <version> - <date>` section to [CHANGELOG.md](CHANGELOG.md).
3. Run the evals and `claude plugin validate .`.
4. Merge into `main`. CI creates the `v<version>` tag, and on a PR it
   fails if the plugin changed without a new version.

## License

[MIT](LICENSE)
