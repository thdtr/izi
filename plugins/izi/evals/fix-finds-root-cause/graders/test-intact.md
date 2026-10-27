---
type: regex
target: { source: file, path: test/price.test.js }
pattern: 'assert\.equal\(applyDiscount\(200, 10\), 180\);\s*assert\.equal\(applyDiscount\(50, 50\), 25\);'
---
