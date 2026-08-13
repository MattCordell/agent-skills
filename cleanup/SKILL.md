---
name: cleanup
description: Tidy up a local git repository after finishing a task, ready for a new one. Deletes local branches already merged into trunk, prunes stale remote-tracking refs, and switches back to trunk with the latest pull. Use this whenever the user runs /cleanup, or asks to "clean up my repo", "tidy up branches", "reset my local for a new task", or similar, after finishing work on a branch.
---

# Cleanup

Tidies the current git repository after a task is finished, so it is ready for the next one.

## Steps

Run these in order. Stop and report to the user if any step fails or produces an unexpected result — do not push through.

### 1. Check for uncommitted changes

```
git status --porcelain
```

If this returns anything (staged, unstaged, or untracked files), **abort immediately**. Report the dirty files to the user and tell them to commit, stash, or discard before running cleanup again. Do not attempt to stash or discard on their behalf.

### 2. Determine the trunk branch

```
git branch --list
```

- If exactly one of `main` or `master` exists, **and it is the only local branch in the repository**, that is trunk. Use it without asking.
- If any other local branch also exists (e.g. `develop`, a feature branch, `trunk`, `release/*`), do not assume — list all local branches to the user and ask them to confirm which one is trunk before proceeding. This applies even if `main` or `master` is present, since the user may be using `develop` or another branch as their actual base.
- If both `main` and `master` exist, or if neither exists, also ask.
- Do not guess silently in any ambiguous case.

### 3. Fetch and prune

```
git fetch --all --prune
```

This prunes remote-tracking refs (`origin/*`) for branches that no longer exist on the remote. It does not touch local branches yet.

### 4. Switch to trunk and update it

```
git checkout <trunk>
git pull
```

If `git pull` fails (diverged history, no upstream, conflicts), stop and report — do not force anything.

### 5. Identify merged local branches

```
git branch --merged <trunk>
```

Exclude `<trunk>` itself and any other branch the user is still actively using (ask if unsure about a specific branch name that looks important, e.g. `release/*` or `hotfix/*` conventions worth double-checking).

### 6. Delete merged local branches

For each remaining candidate:

```
git branch -d <branch>
```

Use `-d` (safe delete), not `-D`. If a branch refuses to delete because git thinks it is not fully merged, do not force it — report it to the user and let them decide, since this usually means the merge was a squash merge that git's `--merged` check cannot see.

### 7. Handle squash-merged branches (common with GitHub PRs)

`git branch --merged` misses branches that were squash-merged on GitHub, since the resulting single commit does not match any commit on the branch. For any local branch not caught by step 5, check whether its PR was merged:

```
git log <trunk>..<branch> --oneline
```

If empty, the branch has no unique commits relative to trunk and is safe to delete with `git branch -d <branch>`.

If the GitHub CLI (`gh`) is available, a faster check is:

```
gh pr list --state merged --head <branch>
```

If this returns a result, the branch was merged via PR and is safe to delete.

### 8. Report a summary

Tell the user:
- Which branch is now checked out (trunk) and that it is up to date
- Which local branches were deleted (safe merges)
- Which local branches were deleted (squash-merged, verified via PR or log check)
- Which branches were left alone, and why (uncommitted work, not merged, or ambiguous)
- That remote-tracking refs were pruned

Keep the summary short and factual, no filler.

## Platform notes

The user works on Windows with PowerShell. The git commands above are identical in PowerShell and bash; no translation is needed. If `gh` is not installed or not authenticated, skip the `gh pr list` check in step 7 and rely on the `git log` diff check instead — mention this to the user rather than silently skipping it.

## Safety principles

- Never force-delete a branch (`-D`) without explicit user confirmation.
- Never stash, commit, or discard changes on the user's behalf.
- Never delete the currently checked-out branch or trunk itself.
- Never push, delete, or otherwise modify anything on the remote — this skill only prunes local remote-tracking refs (bookkeeping), it does not delete remote branches.
- If trunk identification is ambiguous, ask rather than assume.
