# Read queries

All calls here are read-only. Replace `OWNER`, `REPO`, and `N` with real values. Tested
with `gh` 2.103.

GraphQL queries that span several lines are easiest to run from a file:
`gh api graphql -F owner=OWNER -F repo=REPO -F query=@query.graphql`. Keep query files
in the session scratchpad, not in the repo.

## Discovery (step 1)

```bash
# Repo and default branch
git remote get-url origin
gh repo view --json nameWithOwner,defaultBranchRef

# Labels with usage counts (paginate if hasNextPage is true)
gh api graphql -F owner=OWNER -F repo=REPO -f query='
query($owner:String!,$repo:String!){ repository(owner:$owner,name:$repo){
  labels(first:100){ pageInfo{ hasNextPage endCursor } nodes{
    name description
    open: issues(states:OPEN){ totalCount }
    all: issues{ totalCount }
  } }
} }'

# Issue types (an empty list means the repo has none)
gh api graphql -F owner=OWNER -F repo=REPO -f query='
query($owner:String!,$repo:String!){ repository(owner:$owner,name:$repo){
  issueTypes(first:25){ nodes{ name description isEnabled } }
} }'

# Milestones with open and closed counts
gh api "repos/OWNER/REPO/milestones?state=all&per_page=100" \
  --jq '.[] | {title, state, open_issues, closed_issues, due_on}'

# Boards. Repo-linked boards only; org and user boards may be missing from this list.
gh api graphql -F owner=OWNER -F repo=REPO -f query='
query($owner:String!,$repo:String!){ repository(owner:$owner,name:$repo){
  projectsV2(first:10){ nodes{ number title owner{ ... on User{login} ... on Organization{login} } } }
} }'
```

The open-issues query below also returns each issue's board in `projectItems.project`.
Use that list as well, because it catches boards not linked to the repo. Then read each
board's fields:

```bash
gh project field-list N --owner OWNER --format json \
  --jq '.fields[] | {id, name, options: [.options[]?.name]}'
```

## Open issues (step 2)

Save as `issues.graphql`. Paginate with `-F cursor=<endCursor>` until `hasNextPage` is
false. Add a `labels:` or `milestone:` filter argument to `issues(...)` to narrow the
scope.

```graphql
query($owner: String!, $repo: String!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    issues(first: 50, after: $cursor, states: [OPEN], orderBy: {field: CREATED_AT, direction: ASC}) {
      pageInfo { hasNextPage endCursor }
      nodes {
        number title url body createdAt updatedAt
        author { login }
        assignees(first: 10) { nodes { login } }
        issueType { name }
        labels(first: 30) { nodes { name } }
        milestone { title }
        parent { number state }
        subIssues(first: 50) { totalCount nodes { number state } }
        blockedBy(first: 30) { nodes { number state } }
        blocking(first: 30) { nodes { number state } }
        relatesTo(first: 30) { nodes { number state } }
        duplicateOf { number }
        comments { totalCount }
        linkedBranches(first: 5) { nodes { ref { name } } }
        closedByPullRequestsReferences(first: 5, includeClosedPrs: true) { nodes { number state merged } }
        projectItems(first: 5) { nodes {
          id
          project { id number title owner { ... on User { login } ... on Organization { login } } }
          fieldValues(first: 20) { nodes {
            ... on ProjectV2ItemFieldSingleSelectValue { name field { ... on ProjectV2FieldCommon { name } } }
            ... on ProjectV2ItemFieldIterationValue { title field { ... on ProjectV2FieldCommon { name } } }
          } }
        } }
      }
    }
  }
}
```

```bash
gh api graphql -F owner=OWNER -F repo=REPO -F query=@issues.graphql
```

If `subIssues.totalCount` is more than the nodes returned, fetch that issue's sub-issues
separately. The `first:` limits elsewhere are the same: when a list is full, assume it
was cut short.

## Closed issues (duplicate check, H1)

Titles and labels are enough to find candidates. Fetch bodies only for candidates.

```bash
gh issue list --repo OWNER/REPO --state closed --limit 1000 \
  --json number,title,labels,closedAt,stateReason
```

## Mentioned issues by number

Issue bodies mention `#N` numbers that may be closed issues, pull requests, or nothing.
Look them up in one call with aliases:

```bash
gh api graphql -f query='{ repository(owner:"OWNER", name:"REPO") {
  r51: issueOrPullRequest(number: 51) { __typename
    ... on Issue { number state stateReason title }
    ... on PullRequest { number state merged title } }
  r52: issueOrPullRequest(number: 52) { __typename
    ... on Issue { number state stateReason title }
    ... on PullRequest { number state merged title } }
} }'
```

A number that doesn't exist comes back as `null` with a `NOT_FOUND` error, and `gh`
exits with code 1. The other aliases still return data, so read the JSON and don't
treat the exit code as a failure. A `null` usually means a discussion or a reference
to another repo.

## Comments for one issue

Use for prose dependencies, decisions, and plan-comment checks (H5).

```bash
gh issue view N --repo OWNER/REPO --json comments \
  --jq '.comments[] | {author: .author.login, createdAt, plan: (.body | startswith("<!-- plan-issue:v1 -->")), body}'
```

Fetch comments for issues where they matter: issues with `comments.totalCount` above 0
that are candidates for H2, H5, H8, or duplicates. Older issues and epics come first,
because their bodies are most likely to be out of date.

## Security alerts

Issue bodies link alerts as `/security/dependabot/N`, `/security/code-scanning/N`, or
`/security/secret-scanning/N`. Check each alert's state:

```bash
gh api repos/OWNER/REPO/dependabot/alerts/N --jq '{state, severity: .security_advisory.severity}'
gh api repos/OWNER/REPO/code-scanning/alerts/N --jq '{state, severity: .rule.security_severity_level}'
gh api repos/OWNER/REPO/secret-scanning/alerts/N --jq '{state}'
```

A 403 or 404 means alerts are turned off or the token lacks access. Report the alert as
"couldn't check" and move on. For the "every open alert has an issue" rule, list open
alerts with `gh api "repos/OWNER/REPO/dependabot/alerts?state=open&per_page=100"` (and
the same path for code scanning).
