---
name: write-sieve
description: Main delegates Python writing to python-writer; the result is lint-clean without suppressions
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Agent, Write, Edit]
tags: [agent, hook]
---

エラトステネスの篩を sieve.py に書いて
