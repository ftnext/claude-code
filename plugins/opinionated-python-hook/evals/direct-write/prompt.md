---
name: direct-write
description: Main writes Python directly; the PostToolUse formatter hook drives it to a lint-clean result without suppressions
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Write, Edit]
tags: [hook]
---

エラトステネスの篩を sieve.py に書いて
