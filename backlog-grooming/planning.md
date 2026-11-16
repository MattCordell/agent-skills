# Planning the ready work

Run this after the health groups the user chose, on the current data. If health findings
are still open, say how many and which checks they came from. Missing links and board
drift skew the ranking.

## 1. Build the epic tree

Use the epic mechanism named in the conventions file: sub-issues, labels, or both.

- **An epic is not pickup-able work.** It closes when every child closes. Only its open
  children are candidates.
- **Recurse.** A child can itself be an epic.
- **Near-miss epics** are epics with one open child left. Note them for the output.
- **Done epics** (every child closed, epic still open) belong to health check H6. If
  any remain, list them in the output, not as work.

## 2. Work out what blocks each leaf issue

Collect blockers for every open leaf issue from four sources, and label each with its
source:

- **Native link** - `blockedBy` edges.
- **Stated in body** - the conventions' dependency idioms, and `#N` references in
  acceptance criteria that name a concrete prerequisite.
- **Stated in comments** - decisions such as "we'll do X in #47 instead", or evidence a
  blocker was resolved informally.
- **Inferred from domain context** - dependencies no text states. For example, a
  frontend screen that edits an entity needs that entity's backend model first, and an
  API client needs the OpenAPI document it is generated from. These are hypotheses.
  Say so, so the user can check them.

For each blocker:

- **Closed blocker** - the dependency is satisfied. A prose note naming it is stale.
  Don't let it keep the issue off the ready list.
- **Open blocker** - the issue is blocked. Follow the chain: if the blocker is itself
  blocked, so is this issue.
- **Untracked prerequisite** (from H2) - the issue can't start, but no issue blocks it.
  Keep it out of both "ready" and "blocked", and list it separately.

`Ready` on the board means a plan exists, not that the issue is unblocked. A `Ready`
issue with an open blocker is still blocked.

## 3. Rate Size and Difficulty

Rate every ready and nearly ready issue on two separate axes. A large mechanical change
and a one-line fix to a subtle invariant swap places on each axis. A single blended score
loses the difference that tells you how to schedule and staff the work.

- **Size** - how much there is to touch: files, layers (backend, frontend, docs,
  migrations), and call sites. Use the board's own Size options if it has a Size field.
  Otherwise use `XS`, `S`, `M`, `L`, `XL`. A rename across nine call sites is `L`, even
  though every edit is the same.
- **Difficulty** - how much judgment the work needs:
  - **Low** - mirrors a pattern that already exists in the codebase.
  - **Medium** - new code, but no tricky invariants.
  - **High** - touches an invariant such as locking order, transaction boundaries, or a
    public contract, where a mistake is costly and hard to spot. Also High: a design
    question with no code to write until someone chooses between options. Flag these
    as "needs a decision".

Judge Difficulty from the issue's own text, not from Size. "This is not a drop-in
change" plus a list of invariants is High, however few lines it touches. "Mirror the
existing fix" or "test-only" is Low, however many files it touches.

## 4. Rank the ready set

Leave out anything `In progress` on the board or in flight according to the user. Then
order by:

1. **Unblocking power** - how many open issues closing this one unblocks, counting
   native `blocking` edges, prose, and comments. A foundational issue cited by four
   others usually outranks an independent one.
2. **Board priority** (P0 > P1 > P2, or the board's equivalent), if the field exists
   and looks maintained.
3. **Milestone** - active-milestone work before later milestones, unless the user asked
   to look further ahead.
4. **Correctness risk before new features.** A gap that lets two writers silently
   overwrite each other, or a follow-up that closes a just-merged epic's own invariant,
   usually outranks a new feature of similar Size. It is cheaper to fix while the code
   is fresh, and the cost grows as other code builds on it.
5. **Size and Difficulty break ties.** Clear small, Low-Difficulty wins early, because
   they are cheap. Don't let a long tail of `XS` clean-ups push out a High-Difficulty
   correctness issue.

A follow-up spun off a just-merged PR usually earns a high slot, because the code and
context are still warm. Check it against these criteria anyway.

## 5. Output

A table with one row per ranked issue:

| # | Title | Milestone | Size | Difficulty | Blocked by | Ready now |
|---|---|---|---|---|---|---|

Then these notes, in plain language:

- **Chains** - "Closing #51 unblocks #52, #54, and #55, and then #139." Keep the full
  chain. Don't compress it.
- **Parallel-safe groups** - ready issues that touch separate areas (modules,
  directories, layers) and can go to different people now. Also flag issues that look
  independent but touch the same files, such as two issues adding routes to one router.
  Neither blocks the other, but they will conflict at merge time.
- **Near-miss epics** - epics with one open child left.
- **Decisions pending** - High-Difficulty issues that are design questions. Name who
  owns the decision and the options stated. Keep these apart from issues waiting for
  code, so a design question doesn't look stalled on effort.
- **Untracked prerequisites** - issues that need something no issue tracks.
- **Inferred dependencies** - each with its reasoning, for the user to confirm. Offer
  to add confirmed ones as native `blockedBy` links (a health group in step 5).
- **Stale dependency notes** - prose that names a closed blocker.
