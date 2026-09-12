---
type: regex
target:
  source: file
  path: sieve.py
pattern: '\bprint\('
match: not_contains
---

The fixed file must no longer use print() (T201).
