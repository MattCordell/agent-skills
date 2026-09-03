---
name: commit
description: Stage, write a conventional commit message with a body explaining why, commit, and push to the current branch. Use when the user asks to commit changes or runs /commit.
---

# Commit Skill
1. Run `git status` and `git diff` to review changes
2. Stage relevant files with `git add`
3. Write a conventional commit message (feat/fix/docs/chore) with a body explaining why
4. Commit, then `git push origin <current-branch>`
5. Verify the push reached origin and report the commit SHA
