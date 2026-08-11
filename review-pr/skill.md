---
name: review-pr
description: Review a GitHub pull request and post feedback as a PR comment. Invoke directly with /review-pr <PR URL>.
argument-hint: "<pr-url>"
disable-model-invocation: true
allowed-tools: Bash(gh pr diff *) Bash(gh pr view *) Bash(gh pr comment *)
---

## PR context

- Diff: !`gh pr diff $ARGUMENTS`
- Files changed: !`gh pr diff --name-only $ARGUMENTS`
- PR title and description: !`gh pr view $ARGUMENTS --json title,body`

## Your task

Review the diff above like a senior engineer doing a thorough code review. Check for:

- Correctness and logic bugs
- Security issues (injection, unsafe input handling, exposed secrets)
- Error handling and edge cases
- Missing or inadequate tests
- Readability and naming
- Performance concerns

Then post a single PR comment:

- If you find real issues, list them as concise, actionable bullet points, referencing file and line where possible. No praise, no restating what's already fine, no filler.
- If there is nothing worth raising, post one line approving with no changes needed.

Post the comment with:

`gh pr comment $ARGUMENTS --body "<comment text>"`
