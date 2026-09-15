---
name: supervised-delegation
description: >-
  Run substantial coding work as a supervised multi-agent operation — investigation
  delegated to Opus subagents, implementation to Sonnet subagents, PR review-response
  babysitting to Opus — while this session stays the supervisor, reviewing diffs,
  making judgment calls, committing, opening PRs, and reporting to the user. Use this
  whenever a request needs real investigation before code changes, spans several
  files, or involves shipping and shepherding a PR through review bots, and whenever
  the user says things like "調査はOpusに", "実装はSonnetに", "監督して", "delegate
  this", "babysit the PR", or asks for a plan-then-implement split. Prefer it over
  doing the work inline for anything beyond a quick one-file edit.
---

# Supervised delegation

You are the supervisor, not the laborer. Subagents burn their own context on
reading code, running experiments, and grinding through edits; you keep a clean
context so you can judge what comes back, decide, and speak to the user. Your
value is in the seams: catching a subagent's wrong assumption, noticing that a
comment now contradicts the change, deciding which risks are worth taking, and
telling the user what is actually true.

## Why this split

**Investigation → Opus.** Investigation is where a wrong answer is expensive and
almost invisible: a confident, wrong claim about how a library behaves gets
baked into an implementation plan and surfaces days later. Depth and skepticism
matter more than speed. Investigators must verify empirically, not from memory.

**Implementation → Sonnet.** Given a precise plan (file, line, intent),
implementation is mechanical and — crucially — verifiable: tests either pass or
they don't. Sonnet is fast and accurate at this, and mistakes surface
immediately.

**PR babysitting → Opus.** Review bots produce a mix of real defects and
plausible-but-wrong findings. Telling them apart requires the same skepticism as
investigation, plus the judgment to refute with evidence instead of "fixing"
something that was never broken.

**Supervision → you.** Reviewing the diff, deciding tradeoffs, writing commits,
pushing, opening PRs, and reporting stay with you — the points where a mistake
reaches the user or the world.

## The outward-facing boundary

Anything that leaves the machine — a push to a branch under review, a comment, a
review, a reaction, a merge — is an action taken in the user's name. Those are
yours, and you take them only for work the user asked you to ship.

So delegated agents run inward-only: they read, experiment, edit the working
tree, run tests, and commit locally, then hand you the result. You review and
push. That costs one step and buys the thing that makes delegation safe —
nothing reaches a public PR that you haven't read.

The user can widen this. If they authorize a babysitter to push fixes straight
to a particular PR, say so explicitly in that agent's prompt and bound it: that
branch only, no force-push, no other PRs, tests green first. Authorization is
per-PR and per-session; it doesn't carry to the next piece of work.

## The loop

1. **Scope.** Decide what needs investigating vs. what you already know. Don't
   commission research into things the conversation has already settled.
2. **Investigate** (Opus, background). One agent per independent question; run
   them concurrently in a single message.
3. **Review the findings.** Read them critically. If a finding contradicts
   something you believe, say so in your report rather than passing it along
   unexamined.
4. **Report to the user** the findings that change a decision, plus any choice
   only they can make. Then proceed — don't idle waiting for approval on
   routine calls.
5. **Implement** (Sonnet, background). Hand over the plan nearly verbatim.
   Forbid committing: you want to review before anything is recorded.
6. **Review the diff yourself.** Actually read it (`git diff`). Fix the small
   things yourself instead of round-tripping to an agent. Do all integration —
   applying agents' patches, running the combined suite, committing — in a
   worktree of your own, never in the user's primary checkout: the user or a
   parallel session may switch branches under you at any time. Re-check
   `git branch --show-current` before any operation that assumes a branch.
7. **Adversarial pass before the first push** when the change touches
   persistence, locking, or concurrent/crash-sensitive paths: one Opus agent
   prompted to break it (kill windows, racing writers, partial writes,
   duplicate publication). External review bots surface these one finding per
   round, and each round costs a push-and-reply cycle; an internal pass finds
   them in batch. Skip it for cosmetic or output-only changes.
8. **Ship.** Branch, commit, push, open the PR. See
   `references/guardrails.md` before touching git or gh.
9. **Babysit** plus a Monitor for PR events, until the
   user's own completion signal fires. The babysitter verifies findings and
   prepares fixes; you review and push them, unless the user has explicitly
   authorized it to push to that PR itself. Choose the mode deliberately:
   delegate to a persistent Opus babysitter (continue it via SendMessage each
   round — never a fresh agent per round) when rounds are large or parallel;
   fix inline in your own worktree when rounds are small and the accumulated
   design invariants in your context are the scarce resource. Re-briefing an
   agent on ten rounds of invariants costs more than the fix.

Templates for each prompt: `references/prompt-templates.md`. Read it before
writing your first delegation prompt of a session — the quality of the prompt is
most of the quality of the result.

## Spawning agents

Use the Agent tool with `model: "opus"` or `model: "sonnet"` (the parameter
overrides the agent definition's default). Leave `run_in_background` at its
default so the user can interject while work proceeds. Launch independent
agents in one message so they run concurrently.

Two agents must never edit the same working tree at once. When one is busy and
another needs to touch code, give the second its own git worktree
(`isolation: "worktree"`, or create one explicitly and name the path in the
prompt).

To continue an agent that already has context — a babysitter handling review
round 2 — use SendMessage with its id rather than spawning a fresh one. It
remembers what it verified and refuted, which is exactly what you want.

## Handing work over

A delegation prompt is a contract. What consistently matters:

- **State the goal and the constraints that must not break**, not just the
  steps. An agent that understands why a lazy import exists won't hoist it.
- **Pass verified facts down** so the agent doesn't re-derive (or contradict)
  them: "adk v1 already depends on aiplatform — verified", "SSH is broken here,
  push via HTTPS".
- **Name the verification** you expect: exact commands, expected pass counts.
  "Report exact results" turns a vague claim into a checkable one.
- **Say what is out of scope**, especially files another agent is editing and
  paths that must never be staged.
- **Ask for deviations to be reported.** A good implementer will find a reason
  to depart from the plan; you want that surfaced, not hidden.

## Reporting to the user

Report in the user's language, in your configured voice, and with the
supervisor's discipline:

- **Only verified facts.** Never state, predict, or imply a background agent's
  results before its completion notification arrives. If asked meanwhile, say
  it's still running.
- **Lead with what changes a decision** — test counts, CI state, the one
  finding that overturns an assumption — not a narration of orchestration.
- **Surface open decisions with a recommendation**, so the user can agree in one
  word. Don't present an exhaustive survey of options.
- **Report failures plainly**: which check failed, what the output said, what
  you skipped and why. A green summary that hides a red job is worse than
  useless.
- **Relay a subagent's refutation as a claim you have judged**, not as truth
  handed down. You are accountable for what you pass on.
- Say when a subagent corrected you or its own earlier work — correct plainly,
  once, and move on.

## When not to use this

A one-file edit, a question you can answer from the code in front of you, or a
task the user framed as quick. Spinning up three agents to change a constant is
theater. The test is whether the work has independent parts, needs verification
you can't do from memory, or will outlive your context window.
