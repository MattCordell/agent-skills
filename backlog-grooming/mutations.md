# Write calls

Use these only in step 5 of [SKILL.md](SKILL.md), after the user approves the group.
Re-read each item's current state right before writing, and skip it if it has already
changed. Flags tested against `gh` 2.103. If an older `gh` lacks a flag, use the
GraphQL mutation named next to it.

## Links

```bash
# Blocked by (GraphQL: addBlockedBy / removeBlockedBy)
gh issue edit N --add-blocked-by M
gh issue edit N --remove-blocked-by M

# Parent and child (GraphQL: addSubIssue / removeSubIssue)
gh issue edit CHILD --parent EPIC
gh issue edit EPIC --add-sub-issue CHILD
```

If the child already has a different parent, confirm the move with the user. Then use
`addSubIssue` with `replaceParent: true`:

```bash
gh api graphql -f query='
mutation($issue:ID!,$sub:ID!){ addSubIssue(input:{issueId:$issue, subIssueId:$sub, replaceParent:true}){
  issue{ number } subIssue{ number } } }' -F issue=EPIC_NODE_ID -F sub=CHILD_NODE_ID
```

**Relates to** has no `gh` flag. Use GraphQL:

```bash
# Node IDs
gh api graphql -f query='{ repository(owner:"OWNER", name:"REPO") {
  a: issue(number: N) { id }  b: issue(number: M) { id } } }'

gh api graphql -f query='
mutation($a:ID!,$b:ID!){ addRelatesTo(input:{issueId:$a, relatedIssueId:$b}){ clientMutationId } }' \
  -F a=N_NODE_ID -F b=M_NODE_ID
```

`removeRelatesTo` takes the same input.

## Issue type, labels, milestone

```bash
gh issue edit N --type Bug
gh issue edit N --add-label "bug" --remove-label "enhancement"
gh issue edit N --milestone "P1 - Core catalogue"
```

## Label vocabulary (repo-wide)

```bash
# Rename. Every issue keeps the label under its new name.
gh label edit "Bug" --name "bug"

# Merge into a label that already exists: re-label every issue, then delete the old one.
gh issue list --label "Bug" --state all --limit 1000 --json number --jq '.[].number'
gh issue edit N --add-label "bug" --remove-label "Bug"    # for each number
gh label delete "Bug" --yes                                # confirm this item separately

# Describe
gh label edit "area:api" --description "Backend REST API"
```

Deleting a label removes it from every issue and PR, open and closed. Confirm each
deletion on its own, even inside an approved group.

## Board

```bash
# Project and field IDs
gh project view PROJ_N --owner OWNER --format json --jq .id
gh project field-list PROJ_N --owner OWNER --format json \
  --jq '.fields[] | select(.name=="Status") | {id, options}'

# Add an issue to the board. This prints the new item ID.
gh project item-add PROJ_N --owner OWNER --url ISSUE_URL --format json --jq .id

# Set a single-select field. ITEM_ID comes from projectItems.id in the issue query.
gh project item-edit --id ITEM_ID --project-id PROJECT_ID \
  --field-id FIELD_ID --single-select-option-id OPTION_ID
```

## Comments and body edits

Comments notify people and are public. Show the exact text and get item-level approval.

```bash
gh issue comment N --body-file comment.md
```

To edit a body, fetch it first with `gh issue view N --json body --jq .body`. Make the
change, show the user a diff, then write it:

```bash
gh issue edit N --body-file body.md
```

Keep draft files in the session scratchpad, not in the repo.

## Closing

```bash
# Duplicate: GitHub records the link and the DUPLICATE reason
gh issue close DUP --duplicate-of KEEP

# Not planned (stale work the user has agreed to drop)
gh issue close N --reason "not planned" --comment "Closed during backlog grooming: <reason>"

# Epic whose children are all closed
gh issue close EPIC --reason completed
```

## Duplicate resolution order

Do the steps in this order, because closing the duplicate early loses information:

1. **Comment on the kept issue** with the carried-over information and a link to the
   duplicate.
2. **Copy missing labels, assignees, and milestone** to the kept issue.
3. **Re-point blockers.** For each issue `X` that the duplicate blocks, run
   `gh issue edit X --add-blocked-by KEEP --remove-blocked-by DUP`. Closing `DUP` first
   would mark those edges satisfied, and `X` would look unblocked when it isn't.
4. **Copy the duplicate's own open blockers** to the kept issue:
   `gh issue edit KEEP --add-blocked-by M`.
5. **Move sub-issues** to the kept issue, using `addSubIssue` with `replaceParent: true`.
6. **Set the parent** of the kept issue if only the duplicate had one.
7. **Add `relatesTo` links** that the duplicate had and the kept issue lacks.
8. **Close the duplicate** with `--duplicate-of KEEP`.
