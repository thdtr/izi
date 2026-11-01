# IZI

[Leia em português](README.pt-BR.md)

IZI is a plugin for [Claude Code](https://code.claude.com/docs/en/overview)
that gives a developer a short, repeatable way to build software with
Claude. You decide what gets built and approve the steps that matter.
Claude writes the code and the tests, commits, and opens the pull request.
It keeps working when a second person joins the project.

## What you need

| Tool | Why |
|---|---|
| [Claude Code](https://code.claude.com/docs/en/quickstart), in the terminal or the desktop app | IZI runs inside it |
| [git](https://git-scm.com/) and the [GitHub CLI](https://cli.github.com/) | Branches, commits and pull requests. Run `gh auth login` once |
| [jq](https://jqlang.org/) | The hooks use it to read what Claude Code sends them |
| [bubblewrap](https://github.com/containers/bubblewrap) and [socat](http://www.dest-unreach.org/socat/), on Linux | The sandbox needs them |
| [gitleaks](https://github.com/gitleaks/gitleaks), optional | Looks for passwords and keys before each commit |

On Windows you also need Git for Windows. There's a section about it
further down.

## Install

In a terminal, once per machine

```bash
claude plugin marketplace add thdtr/izi
claude plugin install izi@izi
```

The desktop app doesn't need the terminal. Open a local session, type
`/plugin marketplace add thdtr/izi`, accept it and install `izi` with the
buttons that show up.

Then open Claude in your project folder and run `/izi:kickoff`. It reads
what is already there, asks only what it can't work out, shows you every
change it plans to make and waits for your OK before writing anything.
If the project used another way of working (Cursor rules, a folder of
plans, another agent's notes), it tells you where each piece goes and
removes the leftovers in a separate commit you can undo.

Joining a project that already uses IZI? Install the plugin with
`claude plugin install izi@izi --scope project`, or pick the project scope
in the desktop app, and run `/izi:kickoff`. It only sets up your machine.

## The flow

```text
/izi:kickoff          once per project
/izi:spec "feature"   Claude interviews you and writes docs/specs/<slug>.md, you approve it
/clear
/izi:build <slug>     slice by slice, a test and a commit each, then an independent review
/izi:ship             opens the pull request and waits for CI, merging is up to you
```

Claude only stops and waits for you to approve the spec and to merge.
You review everything else in the pull request.

## Which command to use

| Situation | Use |
|---|---|
| A feature with a decision about data, permissions or UI | `/izi:spec`, then `/izi:build` and `/izi:ship` |
| A bug, a failing test or a quick tweak | `/izi:fix "what is happening"` |
| Working from a GitHub issue | `/izi:spec #42` or `/izi:fix #57` |
| Seeing what's next, on the roadmap and in open issues | `/izi:spec` on its own |
| A small change across a few files | [Plan mode](https://code.claude.com/docs/en/permission-modes), then just ask |
| A typo or a text change | Just ask |

## What happens on its own

Every edited file gets formatted. Before each commit, types, lint and the
tests for what changed are checked, and gitleaks looks for secrets. If
something fails, the commit is blocked and Claude fixes it. The same
check runs when a reply leaves code uncommitted, unless the reply ends
with a question for you. CI runs everything again on every pull request.

The commands live in `.claude/settings.json` as `IZI_FORMAT` and
`IZI_CHECK`, and kickoff fills them in for your stack. In a repository
with several stacks they point to `scripts/izi-check.sh` and
`scripts/izi-format.sh`, so a change to one stack only checks that stack.

Kickoff and spec run on Opus. Build, fix and ship run on Sonnet, and code
search runs on Haiku.

## Working with two people

Nothing changes when you work alone. When someone joins, the roadmap in
`docs/PROJECT.md` is still a short list of what comes next, and an item
counts as done once its specs say `Status: shipped`. Nobody edits the
list, so pull requests don't clash over it. Bugs and ideas go to GitHub
issues, and Claude asks before opening one. Whoever runs `/izi:spec #42`
or `/izi:fix #57` is assigned the issue, and it closes when the pull
request is merged. Merging is always a person's call, and green CI is
the only hard rule.

## Sandbox

On Linux, macOS and WSL2, kickoff turns on the
[Claude Code sandbox](https://code.claude.com/docs/en/sandboxing), so
commands run isolated and don't ask for permission at every step. Keep
only development credentials in your local `.env`. `git push` and `gh pr`
run outside the sandbox and ask first. When a command fails with
`EACCES`, `Read-only file system` or a blocked host, that's the sandbox,
and Claude tells you what to add to the settings instead of changing your
code. Your package manager's cache folders go in
`.claude/settings.local.json`, which stays on your machine.

## Windows and the desktop app

IZI runs natively on Windows, in the terminal and in the desktop app.
Install [Git for Windows](https://git-scm.com/download/win), since the
hooks run in its Git Bash, and jq with `winget install jqlang.jq`. Both
need to be on the PATH in your system environment variables, because the
desktop app doesn't read your PowerShell profile, and the app needs a
restart after you change it. If Claude Code can't find Git Bash, point
`CLAUDE_CODE_GIT_BASH_PATH` to its `bash.exe`.

Windows has no sandbox, so Claude asks for permission more often, and
auto mode takes care of most of that. Commits made through PowerShell go
through the same checks as Bash.

The desktop app loads plugins in local and SSH sessions, but not in WSL
or cloud sessions. If you prefer WSL, use it from the terminal and keep
the repository inside WSL rather than under `/mnt/c`.

## Updating

Projects set up by kickoff have auto-update turned on for IZI, and a new
version loads in your next session. To update by hand, open `/plugin`, go
to Marketplaces, pick `izi` and choose Update marketplace. What changed
in each version is in [CHANGELOG.md](CHANGELOG.md).

## Contributing

Try a change without publishing it with
`claude --plugin-dir ./plugins/izi`. Before a pull request, run
`claude plugin validate .`, `bash tests/hooks.sh` and
`bash tests/templates.sh`. CI runs the tests on Linux, macOS and Windows.
The [evals](https://code.claude.com/docs/en/plugin-evals) compare runs
with and without the plugin and cost money, so run the ones for the
skill you changed.

```bash
cd plugins/izi
claude plugin eval . --scaffold --allow-tools Edit --case <name>
```

An installed copy only changes when `version` in
`plugins/izi/.claude-plugin/plugin.json` changes, so every change needs a
new version and a CHANGELOG entry. CI checks both and tags the release
after the merge. To try a branch in the desktop app, close it, delete
`~/.claude/plugins/cache/izi` and install again.

## License

[MIT](LICENSE)
