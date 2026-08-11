---
name: review-pr
description: Review a GitHub pull request and post feedback as a PR comment. Invoke directly with /review-pr <PR URL>.
argument-hint: "[pr-url]"
disable-model-invocation: true
allowed-tools: Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh pr comment:*), Write
---

## PR context

- Diff: !`gh pr diff $ARGUMENTS`
- Files changed: !`gh pr diff --name-only $ARGUMENTS`
- PR title and description: !`gh pr view $ARGUMENTS --json title,body`

## Before reviewing

If no PR URL or number was supplied, stop and ask which PR to review rather than guessing.

If the diff is empty, or any of the commands above failed (closed or inaccessible PR, `gh` not authenticated), report the problem and stop. Do not post a comment in that case.

## Your task

Review the diff above like a senior engineer doing a thorough code review. Check for:

- Correctness and logic bugs
- Security issues (injection, unsafe input handling, exposed secrets)
- Error handling and edge cases
- Missing or inadequate tests
- Readability and naming
- Performance concerns

Skip or only briefly flag changes to generated files, lockfiles, or vendored/third-party code, and focus review effort on hand-written source. If the diff is too large to review in full, say so explicitly in the posted comment rather than silently covering only part of it.

## Posting the comment

- If you find real issues, list them as concise, actionable bullet points, referencing file and line where possible. No praise, no restating what's already fine, no filler.
- If there is nothing worth raising, post one line approving with no changes needed.
- Start the comment with `**Automated review:**` so it's clearly distinguishable from a human comment.

Write the comment body with the Write tool to `/tmp/review-comment.md`, then post it with `--body-file` rather than inlining the text in the shell command. This avoids breaking the command (or worse, unintended shell expansion) when the review quotes code containing double quotes, backticks, or `$()`:

`gh pr comment $ARGUMENTS --body-file /tmp/review-comment.md`
