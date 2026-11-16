---
name: backlog-grooming
description: Groom a GitHub Issues backlog in any repo - learn the repo's issue conventions, scan backlog health (duplicates, missing links, wrong issue types or labels, board drift, thin issues, stale work), fix it in user-approved batches, and rank what is ready to work on next. Use when the user asks to groom or triage the backlog, tidy or clean up issues, find duplicate issues, link related issues, or asks "what's next" / "what can we parallelise" about a repo's issue tracker.
---

# Backlog grooming

Grooming has two parts, run in this order:

1. **Health** - make the backlog's data true: links, issue types, labels, milestones,
   board status, duplicates, and issues too thin to act on.
2. **Planning** - rank the ready work. Planning reads the links and statuses that the
   health part repairs, so health comes first.

Grooming is **progressive**. Scan, report a menu of next steps, let the user pick, apply
the approved changes, then offer the menu again. A neglected backlog takes several
sessions to clean up. A regularly groomed one takes minutes. Each session only has to
leave the backlog better than it found it.

Combine every signal, because any one alone misleads. Board `Status` is hand-maintained
and lags reality. A prose `Blocked by #N` note doesn't update when `#N` closes. Sub-issue
trees show decomposition, not cross-epic blockers. Labels and sub-issues may both claim
to define an epic, and they can disagree.

## Files in this skill

- [conventions-template.md](conventions-template.md) - the shape of the repo's
  `.github/backlog-conventions.md`, and how to discover each section. Read it in step 1.
- [queries.md](queries.md) - read-only `gh` and GraphQL calls. Read it in step 2.
- [mutations.md](mutations.md) - write calls. Read it before the first write in step 5.
- [planning.md](planning.md) - the planning part. Read it when the user picks planning.

## Inputs (ask only if genuinely ambiguous)

- **Repo** (`owner/name`) - infer from `git remote get-url origin`.
- **Scope** - a milestone, label, epic, or everything open. Default: everything open.
- **Work in flight** - anything the user knows is under way but the board doesn't show.
  Treat it as `In progress`.
- **Planning depth** - how many issues to rank. Default: 10.

## Step 1. Load the conventions

The repo's conventions live in `.github/backlog-conventions.md` in the target repo. The
skill owns that file. Every later step reads its vocabulary from it, never from
assumptions.

**If the file exists:**

1. Read it. Then read `CLAUDE.md` (root and nested), `CONTRIBUTING.md`, and
   `.github/ISSUE_TEMPLATE/*`.
2. Check it for drift against those documents and against live data from
   [queries.md](queries.md) "Discovery". Examples: a label the file names no longer
   exists; `CLAUDE.md` now says epics use sub-issues but the file says labels; a new
   issue type or board status has appeared.
3. Treat each piece of drift as a proposed edit to the conventions file. Show the
   evidence and the edit. A human-written statement in `CLAUDE.md` or `CONTRIBUTING.md`
   that is newer than the conventions file (compare `git log -1 --format=%cs -- <file>`)
   usually wins. Still let the user confirm before changing the file.

**If the file is missing:** discover each section as
[conventions-template.md](conventions-template.md) describes. Present a short summary.
Ask the user to confirm or correct it, then write the file.

Either way, the file is a local change in the repo. Tell the user it is uncommitted.

**Done when:** every section of the template is filled in or marked "not used", and
the user has confirmed any new file or drift edit this session.

## Step 2. Pull the data

Follow [queries.md](queries.md). Collect:

- every open issue in scope, with relationships, issue type, labels, milestone,
  assignees, board fields, `updatedAt`, closing PRs, and plan-comment presence
- the label set with usage counts
- the state of every `#N` an issue mentions that is not in the open set
- the state of any security alert an issue links to

**Done when:** every page is fetched (`hasNextPage` is false everywhere) and every
referenced `#N` and alert has a known state.

**Windows note:** if `gh` runs in Bash and `python3` post-processes the output, they can
resolve `/tmp` to different folders. Keep the pipeline in one shell (`jq` in Bash, or
`ConvertFrom-Json` in PowerShell), or write to the session scratchpad by absolute path.

## Step 3. Scan backlog health

Run every check below against every in-scope issue. Skip anything listed under
"Known exceptions" in the conventions file. Skip candidate duplicate pairs that already
have a `relatesTo` link, because a user has already judged them related, not duplicate.

Record each finding with: the check, the issues, the evidence (a quote or field value),
the proposed action, and whether it needs a person's decision.

| # | Check | What to look for | Usual action |
|---|---|---|---|
| H1 | **Duplicates** | Open issues that overlap. Open issues that restate a closed one. Cluster by title keywords, labels, and epic first, then compare bodies. | Report only. Resolve with the duplicate procedure in step 5. |
| H2 | **Missing links** | See "Link types" below. | Add the native link. |
| H3 | **Type and label mismatches** | Issue type disagrees with the conventions' type-label mapping (for example a `bug` label on a `Task`). No type. No labels. Labels outside the vocabulary. Contradictory labels (`bug` and `enhancement`). | Set the type or labels from whichever side the conventions name as the source of truth. |
| H4 | **Label vocabulary** | Near-duplicate labels (`Bug`/`bug`). Labels with zero uses. Labels with no description. | Rename, merge, describe, or delete. Repo-wide, so always its own group. |
| H5 | **Board drift** | Open issue not on the board. Closed issue not `Done`. `In progress` with no assignee and no linked branch or PR. `In progress` or `In review` whose closing PR has merged. `Ready` with no `<!-- plan-issue:v1 -->` comment, or a plan comment but still `Backlog` (if the conventions use `plan-issue`). | Add to board or move the card. |
| H6 | **Epic hygiene** | Epic open with every child closed. Epic with no children. Epic label with no epic issue, or epic issue with no label, where the conventions require both. | Close the epic (confirm each) or add the missing half. |
| H7 | **Missing milestone** | Open issue with no milestone, where the conventions use milestones. Apply the rules below the table. | Set the recommended milestone. |
| H8 | **Not ready** | Vague title. No background or "why". Empty template sections. No acceptance criteria. Fails the conventions' definition of ready. Rank older issues higher: the longer one sits, the less anyone remembers. | Needs context from a person. See step 5. |
| H9 | **Stale** | No activity past the conventions' threshold. Assignee with no activity on it. Lowest priority. | Ask whether it is still wanted. |

**Link types (H2):**

- **Blocked by** - a prose dependency (the conventions' idioms, in the body or comments)
  on an **open** issue with no native `blockedBy` edge. Mark each one with its source:
  "stated in body", "stated in comments", or "inferred from domain context". Inferred
  ones are hypotheses for the user to check.
- **Parent and child** - an issue that belongs to an epic but has no parent, where the
  conventions use sub-issues. Evidence: the epic label, "part of #N", a title prefix, or
  the epic's own task list. Where the conventions use both labels and sub-issues, flag
  issues where the two disagree.
- **Relates to** - issues that reference each other, or clearly cover the same area,
  with no `relatesTo` link and no stronger link.
- **Security alert** - an issue body linking a Dependabot, code scanning, or secret
  scanning alert. Flag an open issue whose alert is fixed or dismissed. If the conventions
  require every open alert above a severity to have an issue, flag open alerts with none.
- **Untracked prerequisite** - an issue names a prerequisite ("needs the job queue")
  that no issue tracks. It is neither ready nor blocked by an issue. Propose creating the
  prerequisite issue, or ask the user how to fill the gap.

**Milestone rules (H7):**

- **Inherit from the parent epic**, unless the issue's own text argues for a different
  phase.
- **Match the milestone of the work it extends.** A fix to a shipped path belongs with
  that path's milestone, not whichever milestone is open.
- **Use a future milestone** only when the issue says it can't start until that
  milestone's prerequisite lands.
- **Send repo or process housekeeping** (CI, repo docs, admin) to a governance-type
  milestone if one exists.

**Done when:** every check has run against every in-scope issue, and every finding has
a proposed action.

## Step 4. Report and offer next steps

Present, in this order:

1. **Conventions changes** - if step 1 changed or proposed changes to the file, say so
   first.
2. **Health summary** - one line per check with its finding count, including zeros. A
   row of zeros is the sign the backlog is groomed.
3. **Next steps** - a numbered menu of groups. For each, give what it does, the number
   of items, and its kind: *bulk change*, *needs your decision*, *needs information from
   people*, or *report only*.
4. **Recommendation** - a session-sized set of steps. For a large backlog, split big
   groups into batches of about 20 items.

Order the menu like this, because earlier groups change what later groups see:

1. Duplicates (H1) - merging moves links and labels.
2. Links and epic hygiene (H2, H6).
3. Types, labels, and label vocabulary (H3, H4).
4. Board drift (H5) and milestones (H7).
5. Not ready (H8).
6. Stale (H9).
7. **Plan the ready work** - always offered. Say how many open health findings could
   skew the ranking.

Then ask the user which steps to work. Make no writes until they choose.

**Done when:** the user has chosen one or more steps, or has said to stop.

## Step 5. Work the chosen steps

Read [mutations.md](mutations.md) before the first write. Then, for each chosen group:

1. **Show the change set** as a table: issue, current value, proposed value, reason.
2. **Get one approval for the group.** The user can drop items or stop at any point.
3. **Confirm item by item** for actions that are public or hard to undo, even inside an
   approved group: closing an issue, deleting a label, editing someone else's issue
   body, and posting a comment. Show the exact comment text, because comments notify
   people.
4. **Check before each write.** Re-read the item's current state. Skip it if it is
   already done or has changed since the scan.
5. **Report** what was applied, skipped, and failed, with reasons.
6. **Record decisions that should last.** If the user says two issues are related but
   not duplicates, add a `relatesTo` link. Record any other deliberate exception
   ("label `x` is kept on purpose") under "Known exceptions" in the conventions file, so
   the next scan doesn't raise it again.

### Duplicates (H1)

Never close a duplicate on your own judgment.

1. **Report the candidate sets** with the evidence for each.
2. **Ask the user** for each set: is it a duplicate, and which issue is kept?
3. **Inventory unique information** on each issue being closed that the kept issue
   lacks: background, reproduction steps, acceptance criteria, decisions in comments,
   screenshots and links, labels, assignees, milestone, board fields, and every
   relationship (parent, sub-issues, blocked-by, blocking, relates-to).
4. **Carry it over.** Draft a comment on the kept issue that summarises the unique
   information and links back to the duplicate. This keeps the original authorship. Edit
   the kept issue's body instead only if the user prefers. Move the relationships and
   copy missing labels. Show all of this to the user before writing.
5. **Close each duplicate** as a duplicate of the kept issue.
6. **Verify** that the kept issue now holds everything from the inventory in point 3.

### Not ready (H8)

Don't invent missing context.

1. **Show what is missing** from each issue.
2. **Ask the user first** - they often remember. If they supply the context, add it to
   the issue body.
3. **Otherwise**, with approval, comment to ask the author or assignee for it. Also add
   the conventions' "needs info" label if there is one.

### Back to the menu

After each group, return to step 4 with refreshed counts.

**Done when:** the user stops, or every finding is resolved or recorded as an exception.

## Step 6. Plan the ready work

Read [planning.md](planning.md) and follow it on the current data.

## Step 7. Close the session

Summarise in plain language:

- **Changed** - each write, with issue links.
- **Recorded** - exceptions and decisions saved to the conventions file.
- **Remaining** - open findings by group, so the next session can start from them.
- **Uncommitted** - remind the user if `.github/backlog-conventions.md` changed.

## Boundaries

- **Writes need approval** - every write follows a group approval in step 5.
- **Duplicates need a person** - the user confirms each set and picks the issue to keep.
- **No implementation** - once the user picks an issue to work on, hand over to
  `plan-issue` or `pick-up-issue`.
- **No commits** - leave committing the conventions file to the user.
