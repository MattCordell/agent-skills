---
name: verify-fixes
description: Re-verify that PR review findings were actually addressed at the current head, scan the current diff for newly introduced issues, then post a confirmation comment. Invoke directly with /verify-fixes <PR URL or number>.
argument-hint: "[pr-number]"
disable-model-invocation: true
allowed-tools: Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh pr comment:*), Bash(pytest:*), Bash(ruff:*), Bash(mypy:*), Write
---

## PR context

- Diff: !`gh pr diff $ARGUMENTS`
- Files changed: !`gh pr diff --name-only $ARGUMENTS`
- PR title, body, head commit: !`gh pr view $ARGUMENTS --json headRefOid,title,body`
- Prior review comments: !`gh pr view $ARGUMENTS --comments`

## Before verifying

If no PR number was supplied, stop and ask which PR to verify rather than guessing.

If the diff is empty, or any of the commands above failed (closed or inaccessible PR, `gh` not authenticated), report the problem and stop. Do not post a comment in that case.

## Part 1 — Verify prior findings

For EACH prior finding from the review comments above, read the current file at HEAD and state one of:

- **VERIFIED** — the finding is addressed; cite file:line showing the fix
- **NOT ADDRESSED** — the finding still stands; cite file:line
- **PARTIAL** — some but not all of the finding is addressed; explain what remains

Do not trust the author's claim that something was fixed — read the code. Do not skip a finding because it looks minor.

## Part 2 — Fresh-eyes scan for new issues

A fix can introduce a new bug in the same commit that resolves the old one. Treat the full current diff as a new review target, independent of the prior findings, using the same lens as `review-pr`:

- Correctness and logic bugs
- Security issues (injection, unsafe input handling, exposed secrets)
- Error handling and edge cases
- Missing or inadequate tests
- Readability and naming
- Performance concerns

Pay particular attention to lines adjacent to or touched by the fixes from Part 1 — that is where a fix-introduces-bug pattern shows up. Skip or only briefly flag generated files, lockfiles, or vendored/third-party code.

List each new issue found as a concise, actionable bullet with a file:line citation. If nothing new is found, say so explicitly rather than omitting the section.

## Part 3 — Run local gates

Run `pytest -n auto`, `ruff`, and `mypy`. Report pass/fail for each; include failing output for anything that fails.

## Posting the comment

Write the comment body with the Write tool to `/tmp/verify-fixes-comment.md`, then post it with `--body-file` rather than inlining the text in the shell command — this avoids breaking the command (or unintended shell expansion) when quoting code containing double quotes, backticks, or `$()`.

Structure the comment as:

```markdown
**Automated verification:**

## Prior findings
| Finding | Status | Evidence |
|---|---|---|
| <finding> | VERIFIED / NOT ADDRESSED / PARTIAL | file:line |

## New issues found
- <issue> — file:line
(or: "No new issues found.")

## Local gates
- pytest: pass/fail
- ruff: pass/fail
- mypy: pass/fail

## Merge readiness
<explicit call: ready to merge / not ready, and why>
```

`gh pr comment $ARGUMENTS --body-file /tmp/verify-fixes-comment.md`
