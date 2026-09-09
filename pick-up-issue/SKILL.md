---
name: pick-up-issue
description: >
  End-to-end execution of a GitHub issue that already has a detailed plan
  posted as an issue comment (see /plan-issue) -- confirm the plan, branch,
  open a draft PR, implement in phases, verify, and mark ready for human
  review. If the issue has no plan comment, stops and asks the user how to
  proceed rather than drafting one itself. Trigger when the user runs
  /pick-up with a GitHub issue URL or number (e.g. /pick-up
  https://github.com/owner/repo/issues/42 or /pick-up #42), or says "pick up
  issue #N", "work on #N", "implement #N", "ship #N", or "close out issue".
  Language-agnostic. The skill never merges the PR.
---

# Implement GitHub Issue

One branch. One PR. From plan to "ready for review."

---

## Hard rules

- **Never merge the PR.** Merging is the human's final gate. The terminal state is "PR open, all phases verified, marked ready for review."
- **At most 2 subagents at a time, and only for genuinely independent work.** Do research and implementation directly by default. Delegate to a subagent only when a piece of work is truly independent of the rest (e.g. two unrelated areas of the codebase) -- not merely because a step feels broad.
- **All work on a dedicated branch.** Never commit directly to main.
- **PRs must close the issue.** Use `Fixes #N` for bug-labelled issues. Use `Closes #N` for everything else. Always present in the PR body.
- **Never invent a plan.** This skill executes an existing plan; it does not write one. If the issue has no plan comment, stop and ask -- see Step 1.

---

## Core principles

**The code shows WHAT. The PR explains WHY.** Code comments are for non-obvious constraints and subtle invariants only. Reasoning, tradeoffs, and alternatives are recorded as inline PR review comments on the relevant code, or in the project's ADR for decisions with lasting architectural significance.

**Iteration beats theory.** Build to learn; don't theorise to plan. The plan sets direction, not certainty -- most remaining uncertainty resolves in 10 minutes of test-writing, not more upfront analysis.

---

## Step 1 — Confirm a plan exists

```bash
gh issue view <num> --json number,title,body,labels,assignees,milestone,comments,url
```

Search the comments for one starting with the marker `<!-- plan-issue:v1 -->` (posted by `/plan-issue`). If none has the marker, fall back to a comment containing both a `## Phases` and an `## Acceptance criteria` heading.

**If no plan comment is found:** stop. Report back to the user, e.g.:

> "Issue #N has no detailed plan attached. Run /plan-issue #N first, or tell me how you'd like to proceed."

Do not draft a plan yourself, and do not proceed to branching or implementation until the user decides.

**If a plan comment is found**, take the most recent one and continue.

---

## Step 2 — Read the plan

From the plan comment, extract: Goal, Acceptance criteria, Approach, Phases, Files likely to change, Suggested branch, Closing keyword, Out of scope, Open questions.

If any Open question in the plan is still unresolved (check later issue comments for a resolution) and it would block implementation, stop and ask the user -- do not guess or silently resolve it.

---

## Step 3 — Create branch

Check the project's branch naming convention first:

```bash
git branch -a | head -20
```

Use the plan's suggested branch name if one was given; otherwise create one from the issue number and a short kebab-case description:

```bash
git checkout -b <num>-short-description
git push -u origin <num>-short-description
```

---

## Step 3a — Update project status to "In Progress"

Check whether the issue is tracked on a GitHub Project (v2):

```bash
gh issue view <num> --json projectItems --jq '.projectItems'
```

If it belongs to one or more projects, move each to "In Progress" before implementation starts:

```bash
PROJECT_ID=<id from projectItems above>
ITEM_ID=<id from projectItems above>
FIELD_ID=$(gh project field-list <project-number> --owner <owner> --format json --jq '.fields[] | select(.name=="Status") | .id')
OPTION_ID=$(gh project field-list <project-number> --owner <owner> --format json --jq '.fields[] | select(.name=="Status") | .options[] | select(.name=="In Progress") | .id')

gh project item-edit --id "$ITEM_ID" --field-id "$FIELD_ID" --project-id "$PROJECT_ID" --single-select-option-id "$OPTION_ID"
```

If the issue is not on any project, skip this step.

---

## Step 4 — Open draft PR up front

Open the PR before implementation, not after. It is the long-lasting context for the workstream: reviewers can subscribe, phases push commits to it, and cross-references have a stable target.

```bash
gh pr create --draft \
  --title "<commit-type(scope): short description>" \
  --body "$(cat <<'EOF'
## Summary
Closes #<num>

🚧 **Draft — work in progress.**

## Plan
See plan comment on #<num>: <link to the plan comment found in Step 1>

## Status
- [ ] Phase 1: <name>
- [ ] Phase 2: <name>

## Verification evidence
<populated as each phase completes>
EOF
)"
```

Use the closing keyword from the plan (`Fixes` for bug-labelled issues, `Closes` otherwise).

The PR title follows Conventional Commits (`feat`, `fix`, `chore`, `docs`, `refactor`, etc.). Read `CLAUDE.md` or recent commit history to determine the project's convention.

---

## Step 5 — Implement (repeat per phase)

### 5a. Implement

Atomic commits per logical change. Rebase; do not squash. Keep history meaningful -- per-change commits are part of the project's record.

### 5b. Record decisions

When you face a decision worth more than two lines of explanation, route it based on significance:

**Architecturally significant** (affects future contributors, changes a pattern, introduces a dependency, or would be costly to reverse): create or update an ADR in the project's ADR directory. If the project has no ADR directory, ask the user whether to create one before proceeding. Use the project's existing ADR format if one exists; otherwise:

```
# <num>. <Short title>

Date: YYYY-MM-DD
Status: Accepted

## Context
<what situation forced this decision>

## Decision
<what you chose>

## Consequences
<tradeoffs, what becomes easier, what becomes harder>
```

**Implementation-level** (local tradeoff, approach choice, why this algorithm over that one): note it for posting as an inline PR review comment in Step 7. Do not write it into the code.

If you are writing a 5-line code comment explaining a choice, stop. Write a 1-line pointer and record the reasoning for Step 7.

### 5c. Run relevant tests only

During development, run only the tests covering the code you are changing. Do not run the full test suite between phases -- it is reserved for the pre-PR gate. Use the test runner and commands documented in `CLAUDE.md` or `README.md`.

### 5d. Verify the phase

Do not wait for human review to learn whether the work is correct. Build the verification: write the test, probe the endpoint, inspect the build output -- whatever the work requires. If you cannot tell whether a phase is correct, ask "what can I build to verify this?" before reaching for human review.

### 5e. Update the PR description

Tick the phase checkbox. Add verification evidence under that phase. Push.

---

## Step 6 — Acceptance gate

Before leaving draft, walk every acceptance criterion from the plan's Acceptance criteria section, the issue body, and any stakeholder comments. For each criterion, provide one of:

- **Evidence it is met**: file or line reference, test output, screenshot, build artifact
- **Written authorisation to defer it**: link to a comment from the reporter or a maintainer explicitly authorising deferral

If any criterion has neither, stay in draft, finish the work (or obtain written authorisation), and return to this gate. "Filing it as a sub-issue" is not a substitute for delivery -- sub-issues are for items the plan did not anticipate.

Render the gate result as an evidence table in the PR description:

```markdown
## Acceptance evidence
| Criterion | Evidence |
|-----------|----------|
| <criterion> | <link / test / "deferred: <comment-url>"> |
```

---

## Step 7 — Post inline review comments for implementation decisions

Post each implementation-level decision noted during Step 5b as a file/line review comment on the PR, so reviewers see the reasoning alongside the code:

```bash
PR_NUM=<n>
OWNER_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
COMMIT=$(gh pr view $PR_NUM --json commits --jq '.commits[-1].oid')

gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/$OWNER_REPO/pulls/$PR_NUM/comments \
  -f body="<decision reasoning>" \
  -f commit_id="$COMMIT" \
  -f path="path/to/file" \
  -F line=123 \
  -f side=RIGHT
```

Architecturally significant decisions should already be in an ADR from Step 5b -- reference the ADR file in the PR description's "Why these changes" section rather than duplicating it inline.

---

## Step 8 — Self-review, full test suite, mark ready

### 8a. Self-review

Adversarially review your own diff before any external reviewer sees it. For each function or section you touched, ask: how else could this be wrong, bypassed, or miss a case? -- alternate inputs, boundary variants, the same class of bug one step over. Write a failing test for each realistic case and fix it in this pass. Draw the line on the pedantic ones and note why (YAGNI). The bar: an external reviewer should surface a new *class* of issue, not the next adjacent edge of one you just touched.

### 8b. Full test suite

Run the full test suite. All must pass before marking ready. Fix any failures; do not skip or suppress.

### 8c. Check mergeability, finalise, and mark ready

```bash
# Confirm branch merges cleanly
gh pr view <n> --json mergeable,mergeStateStatus
```

`mergeable` must read `MERGEABLE`. If it does not, sync the branch (see "Keeping the branch mergeable" below), re-run the full test suite, and re-check.

```bash
# Finalise PR description
gh pr edit <n> --body-file <final-body-file>

# Mark ready for review
gh pr ready <n>
```

The final PR description:

```markdown
## Summary
Closes #<num>

<2-4 sentences: what shipped and why it matters>

## What changed
- `path/to/file` — <change in user-visible terms>

## Why these changes
<central reasoning, written inline. Reference any updated ADRs here by path.>

## Verification
- Phase 1: <evidence: commands, test output, screenshots>
- Phase 2: <evidence>

## Stumbling points
<honest account of surprises and blind alleys. "None." is a valid entry.>

## Suggested CLAUDE.md updates
<anything that would have saved time if documented. Leave blank if none.>

## Follow-up issues
- #N — <one-liner>

## Acceptance evidence
| Criterion | Evidence |
|-----------|----------|
| <criterion> | <link or "deferred: <comment-url>"> |
```

**Stop here. The skill does not merge the PR.**

---

## Addressing review feedback

After the PR is marked ready, a reviewer may request changes. Fixing only the cited line is a trap: round-trips are costly, and it lets one class of issue consume the whole review budget one adjacent edge per round.

**Rule: resolve the class, not the instance -- within the comment's blast radius.**

Gate every comment through three questions:

1. **One-off or symptom?** A typo or single missing guard → fix literally. "This approach is fragile / can be bypassed / misses cases" → it's a symptom; fix the whole class.
2. **Same blast radius?** The adjacent issue is in the function/section under review → fix it now. Elsewhere in the codebase → file a follow-up, do not touch it.
3. **Robustness or new behaviour?** Hardening the thing under review → proceed. New capability or scope → stop; that is scope creep.

Every proactive fix gets a test. If you cannot write a failing test for the adjacent case, you are speculating -- do not change it.

**Per review round: batch, self-review, push once.** Treat each reviewer pass as a single unit:

1. Collect all findings from the round
2. Resolve by the rule above (resolve the class, one test per fix)
3. Run the self-review loop (Step 8a) over the batched diff
4. Push once, then wait

Do not push comment-by-comment. After pushing, do not prompt the reviewer -- a push triggers re-review automatically. If the loop appears stuck (every thread addressed, no fresh verdict), read the reviewer's recent comments for a status notice and follow it exactly.

---

## Keeping the branch mergeable

Enable conflict-resolution replay once, at the start of the workstream:

```bash
git config rerere.enabled true
```

**Default: rebase onto latest main.** Do this periodically, not only at the end:

```bash
git fetch origin && git rebase origin/main
```

**Escape hatch -- merge when a rebase fights you.** Use `git merge origin/main` when main has moved with changes that interleave deeply with your own re-architecture -- a per-commit rebase produces misleading intermediate states. When merging: take your branch's version as the base and layer main's edits onto it, not the other way around.

Always re-run the full test suite after resolving -- a clean merge is not necessarily a correct one. Note the strategy (rebase or merge) in the PR description with one line.

---

## What this skill commits to the repo

Only code and any new or updated ADR files. No planning artefacts are committed. The plan lives on the issue (posted by `/plan-issue`); implementation decisions live as inline PR review comments or in the ADR.

---

## Red flags

| If you think this... | The reality is... |
|---|---|
| "There's no plan comment, I'll just draft a quick one myself" | Not this skill's job. Stop and ask the user -- point them at `/plan-issue` or let them decide how to proceed. |
| "Let me theorise rather than build" | The plan is a starting point, not a spec. Build to learn; the implementation reveals what the plan cannot. |
| "Phase N (core) is done -- the rest can be sub-issues" | If the plan's acceptance criteria are not all met, Phase N is not done. Qualifiers like "core" or "initial" are a sign you are rationalising a scope cut. |
| "There are conflicts; the merger can sort them" | Conflicts are your responsibility. Sync the branch before marking ready. |
| "Build passed, so the work must be correct" | Build success does not equal feature correctness. Verify. |
| "I'll fix this small adjacent thing while I'm here" | File a follow-up. Exception: hardening the same class within a review comment's blast radius (each fix tested) is done in-pass because it is already under review. |
| "This open question in the plan is minor, I'll just decide" | Unresolved open questions are blocking. Ask the user rather than guessing. |
| "I'll merge the PR myself when verification passes" | Never. Human review and merge is the final gate. |
