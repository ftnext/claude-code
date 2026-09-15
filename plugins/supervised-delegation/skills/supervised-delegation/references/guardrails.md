# Guardrails

Hazards that cost real time in practice. Check the ones relevant to what you're
about to do; they are cheap to honor and expensive to rediscover.

## Before touching git

- **Know what's untracked.** `git status --short` first. Stage with `git add -u`
  or explicit paths — never `git add .`, which sweeps in build output, eval
  artifacts, and scratch files the user never wanted committed. Tell subagents
  the same, naming the specific paths to leave alone.
- **Separate PRs need separate branches from the base**, each cut from a clean
  base rather than stacked, unless the user wants them stacked. If two branches
  touch the same file, say so when you hand over the second — a small conflict
  is fine, a surprise is not.
- **Verify push auth before promising a PR.** If SSH is broken in the
  environment (commit signing failures, `Permission denied (publickey)`), push
  with an explicit HTTPS remote URL: `git push https://github.com/<o>/<r>.git
  <branch>`. Avoid commands that implicitly use the broken path afterwards.
- **Match the repo's conventions**: read `git log --oneline -15` and existing PR
  titles before writing yours. Branch naming, commit-message style, and whether
  the repo uses conventional-commit prefixes are all visible there.

## Working with gh

- **`--paginate` on every list endpoint.** They cap at 30 items per page, so a
  monitor or audit without it silently misses everything past the first page.
- **Replying to an inline review comment** requires the PR number in the path:
  `gh api repos/<o>/<r>/pulls/<PR>/comments/<id>/replies -f body=...`. The
  shorter `pulls/comments/<id>/replies` form (valid for GET) 404s on POST.
- **Never act in public on the user's behalf** — comments, reviews, reactions,
  merges, and pushes to a branch someone is reviewing — without explicit
  permission for that specific action. It is outward-facing and effectively
  irreversible: a reviewer may already have read what you overwrite. Force-push
  is a separate, larger ask, since it discards history others may hold.
- **A red check is not automatically your bug.** Read the failing job's log
  (`gh run view <id> --log-failed`) before changing code: a tarball download
  failure or runner hiccup looks identical to a test failure in the summary,
  and re-running the single job is the correct fix.

## Concurrency

- **The user's primary checkout belongs to the user.** They, or a parallel
  session, may switch branches or carry uncommitted work at any time — a
  supervisor integrating agent patches there collides with them silently. Do
  your own integration, commits, and review-fix rounds in a dedicated
  worktree, and re-verify `git branch --show-current` / `git status --short`
  before anything that assumes the tree's state.
- One working tree, one writer. Give a second agent its own git worktree
  (`isolation: "worktree"` or an explicit `git worktree add`) and tell it never
  to `git checkout`/`switch`/`stash` in the shared tree — a branch switch under
  another agent's feet corrupts hours of work.
- Read-only git commands in the shared tree are fine; say that explicitly so
  the agent isn't paralyzed.
- After stopping an agent mid-flight, sweep the tree for probe files and other
  scaffolding it left behind before committing anything.

## Watching a PR without polling by hand

Poll with a Monitor whose script emits only *new* events, so each notification
is something that actually happened. Keep a per-kind state file, diff against
it, and print the difference:

```bash
emit_new() {   # usage: <producer> | emit_new <kind>
  cur="$DIR/$1.cur"; prev="$DIR/$1.prev"
  sort -u > "$cur"
  if [ -f "$prev" ]; then comm -13 "$prev" "$cur"; else cat "$cur"; fi
  mv "$cur" "$prev"
}
```

Watch every state you would act on, not just the good news: new reviews, new
inline comments, the completion signal, **CI failures**, and the PR going
closed/merged (exit the loop there). A monitor that only watches for success
stays silent through a failure, and silence reads as "still running". Poll
remote APIs at 60-90s; anything faster just burns rate limit.

Exclude your own echo — but only your own. Replies and reviews you post via
`gh` arrive as events authored by the *user's* login, so a naive monitor
re-notifies you of your own words moments after you post them. Do NOT fix this
by filtering out that login wholesale: the user's own hand-written comments
arrive under the same login, and one of them may be the completion signal or a
new instruction. Instead, record the id of everything you post (the reply and
comment APIs return it — capture with `--jq .id`) and have the monitor exclude
exactly those ids. Two details close the race this creates: the id can only be
recorded *after* the POST returns, so a poll landing in that gap would still
echo — therefore the monitor must (a) check the exclusion list at *emit* time,
not detection time, and (b) only emit events older than one poll interval.
Recording an id takes seconds; the emit delay is 60-90s, so your ids are
always in place before their events become eligible.

**The completion signal is whatever the user says it is** — a bot's `+1`
reaction, an approving review, a human comment. Confirm it directly before
declaring done (re-read the reactions and check no new findings landed), then
stop the monitor.

## Stop-time review gates

Some environments re-run an adversarial review (e.g. a Codex stop-gate hook)
every time you end a turn, and BLOCK with a finding. Treat a gate finding like
a review-bot comment: verify empirically, then fix or refute with evidence.
The gate re-reviews your *latest* state each round, so hardening related edge
cases in one batch converges faster than one minimal fix per block. The gate's
control commands (status / cancel / review invocations) are often user-only
slash commands: if a gate task hangs, tell the user the exact command to run
rather than attempting it yourself.

## Verifying against a live service

If the plan's verification hits a local server or external endpoint, confirm it
is actually up and healthy before treating a failure as a code defect, and say
in your report which checks you could not run. An E2E check that never ran is
not a passing check.

## Pausing and resuming

When the user stops work mid-flight: stop the monitors and agents, clean the
tree, and write down the exact resume state — branch and head SHA, which review
comment ids are already handled, which are not, what's awaiting the user's
decision. Point-in-time notes decay; note them as of a date, and re-verify
against the repo before acting on them next session.
