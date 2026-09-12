#!/usr/bin/env bash
set -u

input=$(cat)
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$input")
agent_id=$(jq -r '.agent_id // empty' <<<"$input")

case "$file_path" in
    *.py) ;;
    *) exit 0 ;;
esac

# agent_id is present only inside a subagent. Subagents may edit Python freely.
if [ -n "$agent_id" ]; then
    exit 0
fi

cat 1>&2 <<'MSG'
Editing Python from the main conversation is blocked by opinionated-python-agent.
Delegate it to the python-writer subagent: call the Agent tool with
subagent_type "opinionated-python-agent:python-writer", and tell it which file to
write and what the code must do. It runs the formatter until clean and reports back
without spending this conversation's context on lint output.
MSG
exit 2
