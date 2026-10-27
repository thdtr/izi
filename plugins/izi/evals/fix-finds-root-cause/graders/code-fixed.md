---
type: regex
target: { source: file, path: src/price.js }
pattern: 'return price - percent;'
match: not_contains
---
