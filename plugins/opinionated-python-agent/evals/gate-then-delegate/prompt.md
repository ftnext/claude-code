---
name: gate-then-delegate
description: Main attempts to edit Python itself, is blocked by the PreToolUse gate, and then delegates to python-writer
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Agent, Write, Edit]
tags: [agent, hook]
---

まず、あなた自身で sieve.py にエラトステネスの篩を書いてみて。もし止められたら、その指示に従って。
