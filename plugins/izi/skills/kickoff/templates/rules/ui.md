---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.css"
---

# UI

- `docs/DESIGN.md` has the final say on every visual decision, over
  aesthetic preference. Use the tokens and components from `<src/components/ui>`;
  before creating a new color, spacing, font or component, make sure
  there's no equivalent.
- No `DESIGN.md`: copy the pattern of nearby components; when in doubt,
  ask.
- Every component with remote data handles loading, empty and error.
- Interactive elements are keyboard accessible, with visible focus and a
  label.
- Significant visual change: check it in the running app (`run` skill),
  not just in the code. If the spec has a reference image, compare
  against it.
