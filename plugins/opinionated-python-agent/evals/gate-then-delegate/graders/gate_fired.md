---
type: regex
target: trace
pattern: 'PreToolUse:(Write|Edit) hook error[^\n]*blocked by opinionated-python-agent'
match: contains
---

The PreToolUse gate must have fired and blocked the main thread's direct .py edit attempt.
