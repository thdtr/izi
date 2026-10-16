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
| [jq](https://jqlang.org/) | IZI's hooks parse the JSON that Claude Code sends them |
| [GitHub CLI (`gh`)](https://cli.github.com/) | Opening PRs and watching CI. After installing, run `gh auth login` and [`gh auth setup-git`](https://cli.github.com/manual/gh_auth_setup-git) |
| [bubblewrap](https://github.com/containers/bubblewrap) and [socat](http://www.dest-unreach.org/socat/) | Linux only. The [Claude Code sandbox](https://code.claude.com/docs/en/sandboxing) needs them |
| [gitleaks](https://github.com/gitleaks/gitleaks) (optional) | Looks for passwords and keys before every commit. Without it, that check only runs in CI |

## Install

On your machine, once:

```bash
claude plugin marketplace add thiagorodriguesdutra/izi
claude plugin install izi@izi
```

In each project, new or already underway, open Claude in its folder and
run:

```text
/izi:kickoff
```

Kickoff reads what's already in the project and only asks about what's
missing. Before creating any file, it shows you the list of what it's
going to do and waits for your OK. At the end, it tells you whether to
install the [LSP plugin](https://code.claude.com/docs/en/plugins/code-intelligence)
for your language and run `/run-skill-generator`, which teaches Claude how
to open your app to check the result.

## How it works

```text
/izi:kickoff            once per project: sets everything up, drafts the roadmap  (Opus)
/izi:spec "feature"  ✋ interviews you and writes docs/specs/<slug>.md            (Opus)
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
| Small change that touches more than one file | [Plan mode](https://code.claude.com/docs/en/permission-modes) (`Shift+Tab`) and just ask |
| Bug, broken test or one-off tweak | `/izi:fix "what's happening"` |
| Trivial change, like a text tweak or a typo | Just ask |
| Mechanical refactor across many files | [`/batch`](https://code.claude.com/docs/en/commands) |
| Clean up the code that changed | [`/simplify`](https://code.claude.com/docs/en/commands) |
| Two features at the same time | [`claude -w <name>`](https://code.claude.com/docs/en/worktrees) |
| Implement the slices without watching | [`/goal`](https://code.claude.com/docs/en/goal) `every slice in docs/specs/<slug>.md checked and the full gate exits 0` |

## Files kickoff creates

```text
AGENTS.md                 project facts Claude reads in every session
CLAUDE.md                 points to AGENTS.md
.claude/settings.json     model, check commands, permissions and sandbox
.claude/agents/Explore.md code search on a cheaper model
.claude/rules/            UI and test rules
docs/PROJECT.md           product, architecture decisions and roadmap
docs/DESIGN.md            colors, typography and visual patterns (optional)
docs/specs/<slug>.md      one spec per feature, written by /izi:spec
.dependency-cruiser.cjs   architecture rules checked by lint (TS)
.github/workflows/ci.yml  lint, typecheck, tests, build and secret scanning
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
| At the end of every reply that changed code | Types, lint and the tests for the changed files are checked. If something fails, Claude fixes it before stopping |
| Before every commit | gitleaks scans what's about to be committed for passwords and keys |
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
| Reviewing the code against the spec | Opus |
| Code search | Haiku |

Opus is used where there are architecture and scope decisions to make.
Everything else runs on Sonnet, which costs less. The bug review at the
end of the build uses Claude Code's own
[`/code-review`](https://code.claude.com/docs/en/code-review-local).

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

| If this happens | Do this |
|---|---|
| Claude asks for access to a new domain | Accept it, or add the domain to `sandbox.network.allowedDomains` |
| `pnpm` hangs with no error | The `packageManager` version in `package.json` doesn't match the installed one. Make them match |
| `pnpm install` fails on a package that ships a `.vscode/` folder | Run it yourself in the Claude prompt: `! pnpm install` |
| "Yes, don't ask again" doesn't stick | Run `claude doctor` and delete the 0-byte files it lists |
| A command you excluded still runs in the sandbox | Ask Claude to run that command on its own, without `cd`, pipes or `&&` |

## Maintenance

- To update IZI, open `/plugin`, go to Marketplaces, pick `izi`, then
  Update marketplace. Projects set up by kickoff update on their own. More
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
  agents/      reviewer
  hooks/       hooks.json
  scripts/     hook scripts
```

To try a change without publishing it, run
`claude --plugin-dir ./plugins/izi`. Before publishing, run
`claude plugin validate .`.

## License

[MIT](LICENSE)
