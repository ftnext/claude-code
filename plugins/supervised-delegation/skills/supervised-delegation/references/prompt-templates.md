# Delegation prompt templates

Skeletons, not scripts. Keep the section headings — they are what makes results
comparable and complete — and replace the content with the actual task.

## 1. Investigation (Opus, read-only + experiments)

The deliverable is a plan another agent can execute without re-deriving
anything. Demand empirical verification and demand that guesses be labeled.

```
You are investigating (READ-ONLY analysis + running experiments; do NOT modify
any repo files) <question> in <repo path>.

## Context
<what prompted this; the exact command/output if there is one>

## Verified facts you can rely on (re-verify if cheap)
<facts already established, so the agent neither re-derives nor contradicts them>

## The decision already made (do not re-litigate, but flag real problems)
<if the user has decided the approach, say so — investigation is for HOW, not
whether. Ask for consequences to be quantified rather than a counter-proposal.>

## What to inspect
<specific files, config, existing test conventions to mirror, installed
third-party source under .venv when library behavior is in question>

## Experiments you SHOULD run
<concrete commands. Name the environment hazards: isolated envs when checking
dependency minimality, no network services that aren't running, etc.>

## Deliverable (your final message)
1. Exact change(s) with file paths and line numbers, and the ordering reasoning.
2. Options considered and why rejected; what the recommended one costs.
3. Which tests to write and where, naming the existing files/patterns to mirror.
4. Risks and edge cases the implementer must not break.
Report what you verified empirically vs. what you inferred, and mark clearly
anything you could not verify.
```

Ask for the size of consequences, not just correctness: how many packages a
dependency pulls in, how many call sites change, what CI time it adds. That is
what the user needs to make the call.

## 2. Implementation (Sonnet, plan handed over)

Paste the investigated plan close to verbatim. Ambiguity here is re-invented
design, which is what you delegated investigation to avoid.

```
Implement <change> in <repo path> following this investigated plan EXACTLY.
Do NOT commit — leave changes in the working tree. Do NOT touch <out-of-scope
paths>. Keep scope tight: <other concurrent work> is handled separately, so do
not add <that> here.

## Goal
<one paragraph, including the verified facts behind the plan so the agent
understands why, not just what>

## Changes
<the plan, file by file, with line numbers marked approximate and an
instruction to locate precisely by reading>

## Constraints (do not break)
<invariants: lazy imports that must stay lazy, paths that must stay untouched,
public behavior that must not change>

## Tests
<which file, which existing test to mirror, what each new test pins and why>

## Verification (run all, report exact results)
<exact commands and expected outcomes — test suites the way CI runs them,
smoke checks, greps that must come back empty>

## Report back
Files changed with a one-line summary each, exact verification results, and any
deviation from this plan with justification. Match the existing code style
(comment tone, docstring convention, indentation).
```

Deviations are a feature: an implementer that spots a comment contradicting the
new behavior and says so has done real work. Read those reports.

## 3. PR babysitting (Opus, one round per invocation)

```
You are babysitting PR #<n> on <owner/repo>: <url> (branch <b>, base <base>).
This round: watch CI to completion, collect review feedback, address genuine
findings, report.

## Environment constraints
<which working tree is free vs. occupied; worktree path if needed; auth quirks>

## Hard rules
- Do NOT post any comment, review, reply, or reaction on GitHub, and do NOT
  merge, close, or edit the PR description. Do not touch other PRs or branches.
  Communication to the maintainer goes only through your final report.
- Do NOT push. Commit your fixes locally on <branch> and report the SHAs; the
  supervisor reviews and pushes them. <Replace this line only when the user has
  authorized direct pushes for this PR — then give the exact push command, state
  that it is this branch only, and that force-push is not permitted.>
- Tests must pass before you commit: <exact commands and expected counts>.
- Commit style: <convention, including any required trailer>.

## What this PR does (context for judging findings)
<summary plus the design invariants a "fix" must not break>

## Round procedure
1. Snapshot: gh pr view <n> --json state,mergeable,reviews,statusCheckRollup
2. Watch CI: gh pr checks <n> --watch
3. Collect feedback with --paginate on reviews, pulls/<n>/comments, and
   issues/<n>/comments. Already handled: <ids>.
4. For each finding: verify against the code empirically before acting. Review
   bots produce plausible-but-wrong findings; equally, real bugs are possible —
   decide by experiment, not plausibility. Classify: real → fix + regression
   test; refuted → concrete evidence for the report; out of scope → note it.
5. On CI failure, diagnose from logs before assuming the code is wrong;
   infrastructure flakes look like test failures.
6. At most 2 fix-push cycles this round, then stop and report.

## Report
Each finding with classification, evidence, and action (commit SHA if fixed).
Final CI state and test counts. Whether another round looks necessary.
```

Why these rules: a comment, a reaction, and a commit landing on an open PR all
speak in the user's name on a public repo, and a review bot's finding is not a
mandate to change someone's code. Refutations and fixes both come back through
you — the user decides what gets said, you decide what gets pushed after reading
it. This is a boundary, not a formality, which is why the default is "prepare it
and report", with direct pushes granted per PR when the user wants the faster
loop.

Suggest a regression test whose failure would have caught the finding, and where
the fix is subtle, ask for a mutation check — revert the fix, confirm the test
fails, restore it. A test that passes either way pins nothing.
