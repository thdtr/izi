# Adopting an existing project

Read by /izi:kickoff when the project already has code. Whoever adopts
izi follows izi's conventions: the previous workflow's files don't stay
alongside it. Everything below goes into the step 3 plan; nothing is
changed before the user's OK.

## Inventory

Look for what other workflows and agents left behind:

- Agent instructions: `CLAUDE.md` content, an `AGENTS.md` izi didn't
  write, `.cursorrules`, `.cursor/rules/`, `.windsurfrules`, `.clinerules`,
  `GEMINI.md`, `.github/copilot-instructions.md`, `.github/instructions/`,
  `.kiro/`
- Spec and planning kits: `openspec/`, `.specify/`, `memory-bank/`,
  `specs/` or `docs/specs/` in another format
- Plans and lists: `docs/plans/`, `plans/`, `TODO.md`, `ROADMAP.md`,
  ADRs (`docs/adr/`), loose docs that describe how the product should
  behave
- `.claude/` skills, agents or hooks that duplicate izi (step 1)

## One destination per item

| Content | Goes to |
|---|---|
| A fact that changes how an agent works here and the code doesn't show (commands, conventions, what not to touch) | `AGENTS.md`, within its ~60 lines |
| A rule that only applies to some paths | `.claude/rules/<name>.md` with `paths:` |
| A business invariant (prices, permissions, states, limits) | `docs/PROJECT.md` > Business rules, one line with its origin |
| An architecture decision that still holds | `docs/PROJECT.md` > Architecture decisions |
| A pending plan, TODO or open idea | Roadmap, as a vertical slice with a slug; a small one becomes an issue if the project uses them |
| A finished plan, a duplicated rule, generic advice the model already follows, the old workflow's config | Delete |
| Docs for people (README, API docs, runbooks, CHANGELOG) | Keep: not izi's business |

- The code is the truth. Check a rule against the code before carrying
  it over; a doc the code contradicts is a `decision` for the step 2
  interview, not something to copy.
- Business rules: only the critical ones, whose violation loses money,
  data or trust. Not every validation.
- In the step 3 plan, show the inventory as a table: path, what it
  holds, destination.
- Deletion goes in its own commit, `chore: remove <workflow> artifacts`,
  before `chore: set up izi workflow`, so it can be reverted on its own.
  Git history is the archive: no `docs/archive/`.

## Roadmap from the code

- It's not a new project: no walking skeleton. Compare what the old docs
  and the user say the product should do with what the code does.
- Tests, lint or CI missing or failing: the first item is `green-gate`,
  so the quick gate means something before any feature.
- Then the pending plans and TODOs, rewritten as vertical slices with
  slugs. Known bugs: issues, if the project uses them, or one item.
- `v1 scope` describes what exists today and what's left for v1.
