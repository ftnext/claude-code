---
type: regex
target:
  source: file
  path: sieve.py
pattern: 'noqa|type: ignore'
match: not_contains
---

The written file must not suppress diagnostics with noqa or type: ignore comments.
