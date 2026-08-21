---
name: backlog-grooming
description: Triage the open GitHub issues backlog for any repo — work out which issues are actually ready to start, which are blocked and by what, which are safe to run in parallel, and produce a ranked "next N issues" list with dependency notes. Use when the user asks to groom the backlog, triage issues, plan what the team should work on next, or asks "what's next" / "what can we parallelise" about a repo's issue tracker. Also trigger when the user wants to understand the current state of a project's work queue, even if they don't use the word "groom."
---

# Backlog grooming

Grooming a GitHub Issues backlog means combining all available signals — board status,
epic/child structure, native graph relationships, issue bodies, and comments — because
any one source alone is misleading: the board's `Status` is hand-maintained and can lag
reality; a `Blocked by #N` badge doesn't update itself if the relationship was added
informally via prose; the epic/child tree only shows decomposition dependencies, not
cross-epic blocked-by relationships.

## Inputs to clarify (ask only if genuinely ambiguous)

- **Repo** (`owner/name`) — infer from `git remote get-url origin` if you have shell
  access and the user hasn't given it.
- **How many issues to surface** — default to 10.
- **Scope filter** — a milestone, a label, or "everything open"? Default to everything
  open.
- **Issues currently in flight** — ask the user if anyone is already mid-work on
  something not yet reflected on the board. Fold this in as an exclusion.

Do not assume anything about how the repo is organised until you've pulled the data.
Project board field names, label conventions, and whether the repo even uses a Projects
v2 board are all things to discover, not presuppose.

## Procedure

### 1. Discover repo structure

Before pulling issues, confirm what tooling the repo uses:

```bash
# Confirm the remote and default branch
git remote get-url origin
git symbolic-ref refs/remotes/origin/HEAD

# Check if a Projects v2 board exists and what fields it has
gh api graphql -f query='
query { repository(owner:"OWNER", name:"REPO") {
  projectsV2(first:5) { nodes { title fields(first:20) { nodes {
    ... on ProjectV2FieldCommon { name }
    ... on ProjectV2SingleSelectField { name options { name } }
  } } } }
} }'
```

If no Projects v2 board exists, note this and fall back to labels and milestones only
for priority/status signals.

### 2. Pull the raw data

Use GraphQL to get open issues with native relationship fields (`blockedBy`, `blocking`,
`parent`, `subIssues`) in one pass. These are first-class fields on the `Issue` type —
not prose parsing.

```bash
# Lightweight first pass: open issues with relationships and body
gh api graphql -f query='
query($owner: String!, $repo: String!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    issues(first: 50, after: $cursor, states: [OPEN]) {
      pageInfo { hasNextPage endCursor }
      nodes {
        number title state body url
        parent { number title state }
        subIssues(first: 20) { nodes { number title state } }
        blockedBy(first: 20) { nodes { number title state } }
        blocking(first: 20) { nodes { number title state } }
        labels(first: 10) { nodes { name } }
        milestone { title }
        projectItems(first: 5) { nodes { fieldValues(first: 20) { nodes {
          ... on ProjectV2ItemFieldSingleSelectValue {
            name field { ... on ProjectV2FieldCommon { name } }
          }
        } } } }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO
```

Paginate with `endCursor` if `hasNextPage` is true.

Also pull recently closed issues (to evaluate whether inferred prose dependencies are
stale):

```bash
gh issue list --state closed --limit 200 --json number,title,state
```

**Windows/git-bash note:** if you shell out to `gh` from Bash and then post-process
with `python3`, check which path each tool resolves `/tmp` to — MSYS and native Windows
Python can disagree, making files invisible across the boundary. Either keep the whole
pipeline in one shell (`jq` in Bash, or `ConvertFrom-Json` in PowerShell), or write to
an absolute Windows path both tools can see.

### 3. Read issue bodies and comments for inferred dependencies

The GraphQL pass above captures native graph relationships. Now scan issue bodies and
comments for additional dependency signals that may not yet be formalised as graph edges:

```bash
# For any issue whose body contains ambiguous or partial dependency language
gh issue view N --json comments --jq '.comments[] | {author: .author.login, body: .body}'
```

Read comments looking for:
- Decisions that change scope or blockers (e.g. "we'll do X in #47 instead")
- Evidence that a stated blocker has been resolved informally
- Parallel work by contributors not reflected on the board

Prioritise this step for older issues and epics, where bodies may be stale.

### 4. Build the epic tree

An issue with a non-empty `subIssues` list is an epic — it is not itself pickup-able
work; it closes when every child closes. For each epic:

- If every child is `CLOSED` but the epic is still `OPEN`, flag it — it's likely just
  waiting for someone to close it. Call this out explicitly; don't silently recommend
  working on it.
- Only **open children** of an epic are candidate work items. Recurse — children can
  themselves be epics.

### 5. Evaluate all dependencies

For every leaf (non-epic) open issue, collect dependencies from two sources:

**Source A — Native graph relationships** (from `blockedBy` field):
- If a blocking issue is `CLOSED`, the dependency is satisfied. Note it as a stale
  graph edge that can be cleaned up.
- If a blocking issue is `OPEN`, this issue is blocked. Chain transitively.

**Source B — Prose and comments** (from bodies and comment threads):
- Idioms: `**Blocked by #N**`, `**Depends on #N**`, `## Blocked by`, `## Dependencies`
  sections, bare `#N` references in acceptance criteria naming a prerequisite.
- Apply the same stale-check: if the referenced issue is closed, the prose is stale.
- Also apply structural inference where the text won't state dependencies outright (a
  frontend screen editing an entity generally needs that entity's backend model merged
  first; an API client generation issue needs the OpenAPI doc it reads from).

**Label every inferred dependency clearly** — distinguish:
- "Native graph relationship (`blockedBy` field)"
- "Stated in issue body"
- "Stated in comments"
- "Inferred from domain context"

The last category is a hypothesis for the user to validate.

### 6. Rank

Order the ready set (no open blockers) by:

1. **Unblocking power** — how many other open issues does closing this one unblock?
   Count references across `blocking` fields, prose, and comments.
2. **Board priority** (P0 > P1 > P2 or equivalent) if the field exists and looks
   trustworthy.
3. **Milestone** — don't recommend lower-milestone work ahead of the active milestone's
   backlog unless the user asked.

Exclude anything already `In progress` per the board or the user.

### 7. Output

Produce a table: issue number, title, blocked-on (or "-"), ready now (yes/no).

Follow with plain-language notes on:

- **Chains** — "closing #51 unblocks #52, #54, and transitively #139" — preserve this
  detail, don't compress it.
- **Parallel-safe groups** — which ready issues touch genuinely separate areas and can
  be assigned concurrently without merge risk, versus which look independent but touch
  the same files (flag the merge risk even if neither blocks the other).
- **Near-miss epics** — epics whose last open child is about to land.
- **Inferred dependencies** — list separately with the reasoning and source for each.
- **Stale dependency notes** — issues whose prose still says "Blocked by #N" but #N is
  closed, or where a native `blockedBy` edge points to a closed issue.

Keep the write-up in plain language: short sentences, one idea per sentence, active
voice.

### 8. Offer to formalise inferred dependencies as native graph relationships

After presenting the analysis, if any inferred prose or domain dependencies were
identified that do not already exist as native graph relationships, ask:

> "I found [N] dependencies that exist only as prose notes or inferences, not as native
> GitHub relationships. Would you like me to add these as `Blocked by` graph edges? This
> creates the relationship you can see in the issue sidebar and means the next grooming
> session reads them directly from the graph rather than re-inferring them."

If the user agrees, for each inferred dependency:

1. Confirm the specific issues and direction (which is blocked, which is the blocker).
2. Get the node IDs needed for the mutation:

```bash
gh api graphql -f query='
query { repository(owner:"OWNER", name:"REPO") {
  blocked: issue(number: BLOCKED_N) { id }
  blocker: issue(number: BLOCKER_N) { id }
} }'
```

3. Create the native graph relationship:

```bash
gh api graphql -f query='
mutation($issueId: ID!, $blockingIssueId: ID!) {
  addBlockedBy(input: { issueId: $issueId, blockingIssueId: $blockingIssueId }) {
    issue { number title }
    blockingIssue { number title }
  }
}' -F issueId=BLOCKED_NODE_ID -F blockingIssueId=BLOCKER_NODE_ID
```

4. Report what was created. Show the user each relationship before applying it and apply
   only after explicit confirmation. Do not batch-apply without per-relationship
   sign-off.

Do not add a relationship that already exists as a native graph edge — check `blockedBy`
in step 2 first.

## What this skill does not do

- It does not re-prioritise, re-label, or close issues unless the user explicitly asks
  after reviewing the grooming report.
- It does not replace a pick-up-issue workflow — once the user selects an issue from
  the ranked list, use a separate skill or workflow to actually implement it.
