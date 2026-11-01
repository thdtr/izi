# <Product>

## What it is

<1-2 sentences>

## Problem and audience

<who struggles with what, today>

## v1 scope

- <observable capability>

## Out of scope (for now)

- <what not to reopen now>

## Business rules

Invariants whose violation loses money, data or trust. One line each,
with where it came from (`file:line` or the old doc). The code and the
tests are the truth; this is what review checks them against.

- <Price always comes from the catalog, never from the client - src/orders/price.ts:12>

## Architecture decisions

One line each: decision - reason (YYYY-MM-DD). Changed your mind? Strike
the old one and add the new one. Dependency rules between layers also
live in `.dependency-cruiser.cjs`, which lint checks.

- <Auth with X - reason (date)>

## Roadmap

Direction, not a backlog: the next vertical slices that can ship to
production, in order. Each item's slug is the slug of its spec; an item
is done when its specs say `Status: shipped` (`docs/specs/<slug>.md`, or
the specs whose `Roadmap:` line names it, when it was split), so nobody
edits this list to mark progress. Bugs and small improvements go to
issues, if the project uses them.

- `walking-skeleton`: login + <1 real screen> + deploy + green CI
- `<slug>`: <slice>
