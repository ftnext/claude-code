---
type: regex
target: trace
pattern: '"parent_tool_use_id":null[^\n]*(\.py:\d+:\d+:|Found \d+ error|PostToolUse:(Edit|Write) hook)'
match: not_contains
---

The main thread (parent_tool_use_id null) must never see raw lint/formatter output or PostToolUse
hook feedback directly - only the python-writer subagent should absorb that.
