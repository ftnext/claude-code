---
type: regex
target:
  source: file
  path: sieve.py
pattern: 'logger\.\w+\(f"'
match: not_contains
---

The fixed file must not use f-string interpolation directly in a logger call (the fixer should
also clean up the pre-existing lint violations, not just the bug).
