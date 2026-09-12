# claude-code

```
/plugin marketplace add https://github.com/ftnext/claude-code
```

## opinionated-python-hook

```
/plugin install opinionated-python-hook@nikkie-marketplace
```

## opinionated-python-agent

The same formatter hook, plus a `python-writer` subagent.
Editing `.py` from the main conversation is blocked; the subagent does it and keeps the lint output out of your context.

```
/plugin install opinionated-python-agent@nikkie-marketplace
```

Install only one of the two. Both ship the same formatter hook, so the formatter would run twice per edit.

Requires `uv` (`uvx`) and `jq`.
