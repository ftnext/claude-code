---
name: fix-existing
description: python-writer fixes a pre-existing off-by-one bug and the file's lint violations without suppressing diagnostics
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Agent, Write, Edit]
tags: [agent, hook]
---

sieve.py の sieve(25) の結果に 25 が含まれてしまうバグを直して
