# Backlog conventions: template and discovery

The skill writes `.github/backlog-conventions.md` in the target repo from the template at
the end of this file. Fill each section from evidence, not assumptions. If a repo doesn't
use something, write "not used" rather than deleting the section, so the next run knows
it was checked.

## How to discover each section

Run the "Discovery" calls in [queries.md](queries.md) first. Then:

- **Sources of truth** - read `CLAUDE.md` (root and nested), `CONTRIBUTING.md`, and
  `.github/ISSUE_TEMPLATE/*`. A rule stated there beats a pattern inferred from data.
- **Epic convention** - work out which mechanism groups issues into epics:
  - *Sub-issues*: count open issues with `subIssues` and with a `parent`.
  - *Labels*: look for labels such as `epic`, `epic:*`, `area:*`, `feature:*`, or
    labels whose descriptions say "epic" or "theme".
  - *Milestones*: milestones named after features rather than phases or dates.
  - *Both*: if label-grouped issues also share a parent, the repo uses both. Record which
    mechanism is the source of truth and whether the other must mirror it.
- **Issue types** - list the repo's enabled issue types. Compare types with labels on
  existing issues to infer the type-label mapping (for example, most `bug`-labelled
  issues have type `Bug`). Record which side wins when they disagree. If the repo has
  no issue types, write "not used".
- **Labels** - group the label set by role: kind (`bug`, `enhancement`), area or
  component, priority, triage state (`needs-info`, `ready-for-agent`), and other. Note
  near-duplicates and unused labels, but don't fix them here. That is check H4.
- **Board** - find the board(s) the issues sit on. Record each field that grooming uses
  (Status, Priority, Size, and similar) with its options. Note what each status means.
  If the repo uses `plan-issue`, `Ready` means a `<!-- plan-issue:v1 -->` plan comment
  exists.
- **Milestones** - list them with open and closed counts. Record whether they are
  phases, releases, dates, or epics. The milestone with the most recent activity is
  usually the active one.
- **Dependency idioms** - sample 20 or more issue bodies. Record the phrases used for
  dependencies (`Blocked by #N`, `Depends on #N`, a `## Dependencies` section), and
  whether native `blockedBy` links are used at all.
- **Definition of ready** - take it from `CONTRIBUTING.md` or the issue templates'
  required sections. If neither states one, propose: a clear title, why the work
  matters, and acceptance criteria. Let the user adjust it.
- **Stale threshold** - default 90 days with no activity, unless the user says
  otherwise.
- **Security alerts** - record whether alerts are tracked as issues, and the minimum
  severity that needs one. Default: "not tracked as issues".

## Template

Copy everything below the line into `.github/backlog-conventions.md`.

---

```markdown
# Backlog conventions

<!-- Maintained by the backlog-grooming skill. Edit freely; the skill re-checks this
file against CLAUDE.md, CONTRIBUTING.md, and live repo data each run. -->

Last confirmed: YYYY-MM-DD

## Sources of truth

- Rules documented in: <CLAUDE.md / CONTRIBUTING.md / issue templates / none>

## Epics

- Mechanism: <sub-issues | labels | milestones | both: ...>
- Source of truth when they disagree: <...>
- Epic labels: <pattern, e.g. `epic:*`, or "not used">
- An epic issue is identified by: <issue type `Epic` / label `epic` / has sub-issues>

## Issue types

- Types in use: <Bug, Feature, Task, ... or "not used">
- Type-label mapping:
  | Label | Issue type |
  |---|---|
  | `bug` | Bug |
- Source of truth when they disagree: <type | label>

## Labels

- Kind: <...>
- Area / component: <...>
- Priority: <... or "on the board instead">
- Triage: <needs-info label, ready label, ...>
- Required on every issue: <e.g. one kind label, or "none">

## Board

- Project: <title> (owner `<login>`, number <N>)
- Fields used in grooming:
  | Field | Options | Meaning |
  |---|---|---|
  | Status | Backlog, Ready, In progress, In review, Done | Ready = plan comment posted |
- Every open issue must be on the board: <yes / no>

## Milestones

- Meaning: <phases / releases / dates / not used>
- Active milestone: <title>
- Housekeeping milestone: <title or "none">

## Dependencies

- Native `blockedBy` links used: <yes / no / partly>
- Prose idioms: <`Blocked by #N`, `Depends on #N`, `## Dependencies`>

## Definition of ready

- <a clear title>
- <why the work matters>
- <acceptance criteria>

## Staleness

- Stale after: <90> days with no activity

## Security alerts

- Tracked as issues: <yes, severity high and above / no>

## Known exceptions

<!-- Decisions from past grooming sessions, so they are not raised again. -->
- <#12 and #40 are not duplicates: different components (YYYY-MM-DD)>
```
