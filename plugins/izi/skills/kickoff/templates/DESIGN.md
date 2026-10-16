# Design

Visual stack: <Tailwind CSS v4 (CSS-first) · Base UI or shadcn/ui · Lucide>

## Principles

1. <e.g. high density, little ornament>
2. <e.g. one primary action per screen>
3. <e.g. red only for errors and destructive actions>

## Tokens

Defined in <src/styles/tokens.css>. Use them by role, never by value.

- Color: <accent, fg, fg-muted, bg, surface, border, danger, success, warning>
- Typography: <family>; scale <xs..2xl>; numbers with `tabular-nums`
- Spacing: <4px scale>
- Radius: <sm, md, lg>
- Shadow: <1 level at most outside overlays>
- Motion: <150-250ms>; respect `prefers-reduced-motion`

## Components

Base: <wrappers in src/components/ui>. New component only if there's no
equivalent there; when you create one, it goes there.

## Patterns

- Required states: loading (skeleton), empty (with an action), error (with retry).
- Forms: validate on submit and on the server; error next to the field;
  focus moves to the first error.
- Destructive action: explicit confirmation or undo.
- Dark mode: <yes/no>; no flash on SSR.

## Don't

Name concrete patterns; "avoid a generic look" changes nothing.

- <e.g. purple gradients, emoji in the UI, modal inside a modal, card inside a card>
