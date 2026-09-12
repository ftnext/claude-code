---
type: regex
target:
  source: file
  path: sieve.py
pattern: '(isqrt\(n\)|n ?\*\* ?0\.5\)) ?\+ ?1'
match: contains
---

The inner loop's upper bound must be inclusive of the integer square root (isqrt(n) + 1, or
int(n**0.5) + 1), so that sieve(25) no longer wrongly includes 25.
