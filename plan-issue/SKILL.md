---
name: plan-issue
description: >
  Research a GitHub issue and produce a detailed implementation plan, posted
  as an issue comment for a human or a different agent to pick up cold.
  Runs under Claude Code's plan mode: all research and drafting happens
  read-only, and the plan is only posted to the issue after the user approves
  it via ExitPlanMode. Trigger when the user runs /plan-issue with a GitHub
  issue URL or number (e.g. /plan-issue https://github.com/owner/repo/issues/42
  or /plan-issue #42), or says "plan out issue #N", "draft a plan for #N",
  "write a plan for #N". Language-agnostic. The skill never branches, opens a
  PR, or writes code -- see /pick-up-issue for execution.
---

# Plan a GitHub Issue

Research once, decide once, hand off clean. The output is a plan someone else -- human or agent -- can execute without this conversation.

---

## Hard rules

- **Plan mode only.** No branch, no commit, no PR, no code. The only write action this skill ever takes is posting the approved plan as one issue comment.
- **The plan is the interface.** Write it for a cold reader: zero access to this conversation, possibly a different agent entirely. If a step only makes sense because "we discussed this earlier," it is not in the plan yet.
- **Nothing gets posted before approval.** The plan is drafted and refined inside plan mode; it reaches GitHub only after the user approves it through `ExitPlanMode`.

---

## Step 0 — Enter plan mode

If you are not already in Claude Code's plan mode, enter it now (`EnterPlanMode`) before touching anything else. Everything through Step 3 is research and drafting -- read-only tools only.

---

## Step 1 — Fetch issue context

```bash
gh issue view <num> --json number,title,body,labels,assignees,milestone,comments,url
```

Read the body AND every comment. The latest decisions are often in comments, not the description. Extract:

- Acceptance criteria (explicit or implicit)
- Linked issues, PRs, or discussions
- Constraints the reporter called out
- Labels (bug vs feature determines the PR closing keyword)

---

## Step 2 — Research the codebase

Before forming a plan, ground yourself:

- Grep for symbols, files, or terms the issue names
- Read surrounding code, not just the named file
- Check `git log` on relevant files for recent context
- Read `CLAUDE.md` (root and any nested) -- these carry architectural patterns, conventions, and test runner commands
- Check whether the project has an ADR (Architecture Decision Record) directory. Common locations: `docs/adr/`, `docs/decisions/`, `adr/`, or files named `NNNN-*.md`. Note the location so the plan can point the executor at it.

**Stop if** the issue is ambiguous, acceptance criteria are unclear, or research reveals the issue's premise is wrong. Ask the user directly in this conversation rather than guessing -- do not post questions to the issue; nothing goes to GitHub until Step 4.

---

## Step 3 — Clarifying questions

Ask the user clarifying questions in a single batch until you are **at least 90% confident** you understand:

- The problem being solved
- Expected behaviour: inputs, outputs, edge cases
- Acceptance criteria (explicit or implied)
- Constraints: performance, backwards compatibility, style conventions

Ask in one batch where possible. Do not fire questions one at a time. Do not draft the plan until you have reached the 90% threshold.

If the work spans multiple subsystems, has deeply interdependent phases, or looks like genuine multi-day effort, raise it now regardless of plan length: "This looks like it could be split into child issues -- do you want to break it down first, or plan it as one workstream?"

---

## Step 4 — Draft the plan

Write the plan content (you'll hand it to `ExitPlanMode` next, then post it verbatim). Keep it strategic, not prescriptive: aim for under ~200 lines. If you find yourself describing how to implement something rather than what to implement and why, you are writing a spec, not a plan -- pull back to strategy.

```markdown
<!-- plan-issue:v1 -->
# Issue #<num>: <title>

**Link:** <issue url>
**Suggested branch:** <num>-short-description
**Closing keyword:** Fixes | Closes

## Goal
<1-2 sentences: what done looks like>

## Acceptance criteria
- <explicit or implied criterion, one per line -- this is the executor's checklist>

## Approach
<3-6 bullets: strategy, not step-by-step>

## Phases
1. <name> — <one-line scope>
2. <name> — <one-line scope>

## Files likely to change
- `path/to/file` — <what changes and why>

## Out of scope
- <things that look related but are not part of this issue>

## Open questions
- <anything still unresolved -- flag clearly if it would block an executor>
```

The `<!-- plan-issue:v1 -->` marker is load-bearing: `/pick-up-issue` looks for it to confirm a plan exists. Always include it as the first line, verbatim.

The **closing keyword**: default to `Fixes` for bug-labelled issues, `Closes` for everything else.

---

## Step 5 — Exit plan mode for approval

Call `ExitPlanMode` with the full plan content from Step 4. This is the approval gate -- the user reviews and can request changes before anything touches GitHub. Do not post to the issue until this returns approved.

---

## Step 6 — Post the plan as an issue comment

```bash
gh issue comment <num> --body-file /tmp/issue-<num>-plan.md
rm /tmp/issue-<num>-plan.md
```

This is the single home for the plan -- discoverable from the issue itself, not buried in this conversation. It is also the only write action this skill performs.

If the issue has active participants, mention to the user that it may be worth waiting for their feedback before anyone runs `/pick-up-issue` on it.

**Stop here.** No branch, no PR, no code. Tell the user the plan is posted and ready for `/pick-up-issue #<num>` (by them, or by a different agent) whenever they want execution to start.

---

## Red flags

| If you think this... | The reality is... |
|---|---|
| "I'll just post the plan now, approval is a formality" | Plan mode exists so the user can redirect before a comment goes public. Wait for `ExitPlanMode` to actually return approved. |
| "I'll sketch the how, not just the what" | That's a spec, not a plan. Pull back to strategy -- phases and files, not line-by-line instructions. |
| "This open question is minor, I'll just note it and move on" | If it would block whoever executes this cold, it's not minor. Flag it plainly under Open questions. |
| "I'll fix this while I'm in the code researching" | This skill never writes code. Note it in the plan (Files likely to change, or Out of scope) instead. |
