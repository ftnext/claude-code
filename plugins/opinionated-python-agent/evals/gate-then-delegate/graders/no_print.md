---
type: regex
target:
  source: file
  path: sieve.py
pattern: '\bprint\('
match: not_contains
---

The written file must not use print() (T201 is one of the lint checks the formatter hook enforces).
