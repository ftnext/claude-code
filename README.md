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

Requires `uv` (`uvx`) and `jq`. hatch is pinned (`uvx hatch@1.18.0`); on session start the plugins check that `uvx` exists and build the hatch environments for the project in the background.

The linter runs with Ruff preview rules enabled (`hatch check code --preview`), e.g. [RUF029 unused-async](https://docs.astral.sh/ruff/rules/unused-async/). The formatter uses the stable style.

## supervised-delegation

A skill, not a hook, and independent of the two Python plugins above.
It runs a substantial coding request as a supervised multi-agent operation: investigation is delegated to Opus subagents, implementation to Sonnet subagents, and PR review-response to an Opus babysitter, while your main session stays the supervisor that reads the diffs, commits, and reports.
It triggers on requests like "監督して", "調査はOpusに、実装はSonnetに", "delegate this", or "babysit the PR".

```
/plugin install supervised-delegation@nikkie-marketplace
```

No external dependencies. By design it routes investigation and PR babysitting to Opus subagents, so expect several concurrent Opus runs per task.

## Evals

The two Python plugins ship `claude plugin eval` suites under `evals/`. They check that Python
writing gets delegated to the subagent (or blocked and then delegated) as expected,
that the gate/hook fires when it should, that the produced code has no `noqa`,
`print()`, or f-string logging, and that the files really pass `hatch check` (not
just the agent's own say-so).

Run them with:

```
scripts/run-evals.sh plugins/opinionated-python-agent
scripts/run-evals.sh plugins/opinionated-python-hook
```

Extra `claude plugin eval` flags pass straight through, e.g.:

```
scripts/run-evals.sh plugins/opinionated-python-agent --runs 1 --ablation none --case write-sieve
```

This runs on your own Claude login (subscription usage; no API key needed). A full
run costs a few dollars of API-equivalent usage.

## Tests

The formatter hook itself is tested without a model: it runs both plugins'
`python_format.sh` on small fixtures and checks the exit codes and diagnostics.

```
tests/test-python-format.sh
```
