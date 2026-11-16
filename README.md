# Agent Skills

A curated collection of skills for Claude Code (CLI and VS Code extension). This repository serves as the single source of truth for agent skills, with junctions configured in your local Claude Code installation for automatic discovery.

## What's Inside

| Skill | Purpose |
|-------|---------|
| **backlog-grooming** | Groom a GitHub Issues backlog in any repo. Learns the repo's issue conventions and saves them to `.github/backlog-conventions.md`, scans backlog health (duplicates, missing links, wrong issue types or labels, board drift, thin or stale issues), applies fixes in user-approved groups, and ranks the ready work. |
| **cleanup** | Tidy up a local git repository after finishing a task, ready for a new one. Deletes local branches already merged into trunk, prunes stale remote-tracking refs, and switches back to trunk with the latest pull. |
| **commit** | Review changes with `git status` and `git diff`, stage files, write conventional commit messages with explanatory body, and push to origin. Reports the commit SHA after pushing. |
| **conference-submission-review** | Conduct structured peer reviews of academic conference or journal submissions in health informatics, biomedical informatics, and related fields. Also supports self-checking your own paper before submitting. |
| **plan-issue** | Research a GitHub issue and post a detailed implementation plan as an issue comment, under Claude Code's plan mode. Invoked with `/plan-issue <issue URL or #N>`. Writes no code. |
| **pick-up-issue** | Execute a GitHub issue that already has a plan comment from `plan-issue`: branch, open a draft PR, implement in phases, verify, and mark ready for review. Stops and asks if no plan is found. Invoked with `/pick-up-issue <issue URL or #N>`. Never merges. |
| **review-pr** | Review GitHub pull requests and post feedback as a PR comment. Analyzes diffs for correctness, security, error handling, tests, readability, and performance. Invoked with `/review-pr <PR URL>`. |
| **to-tickets** | Break a plan, spec, or conversation into tracer-bullet tickets with blocking relationships. Publishes to your configured issue tracker with dependencies declared. |
| **verify-fixes** | Re-verify that PR review findings were addressed at the current head, scan the diff for newly introduced issues, run local gates, and post a merge-readiness comment. Invoked with `/verify-fixes <PR URL or number>`. |
| **writing-great-skills** | Reference for writing and editing skills well — principles for predictability, information hierarchy, failure modes, and structural patterns that make skills reliable and maintainable. |

## How It Works

This repository uses **git junctions** to link skills into your Claude Code installation. When you clone this repo and set up junctions:

```
C:\Repos\agent-skills\<skill>     <- Skills live here (source of truth)
           ↓ (junction)
~\.claude\skills\<skill>           <- Claude Code reads from here
```

When you update a skill in the repository and pull changes, Claude Code discovers the updated version automatically on the next invocation—no restart needed.

## Usage

### Invoking Skills

Skills are invoked differently depending on their type:

**User-invoked skills** (requires you to type the skill name):
- Type the skill name directly: `/commit`, `/to-tickets`, `/writing-great-skills`
- These are not automatically suggested; you control when to fire them

**Direct-argument skills**:
- `/review-pr <PR URL>` — pass the URL or PR number as an argument

All skills are available in:
- **Claude Code CLI**: Type the skill name in any conversation
- **VS Code Extension**: Same as CLI, within the VS Code integration

## Adding New Skills

To create a new skill, follow this structure:

```
agent-skills/
└── my-skill/
    ├── SKILL.md                 (required)
    └── [supporting files]       (optional)
```

### SKILL.md Template

Minimal example:

```markdown
---
name: my-skill
description: One-line summary of what the skill does
disable-model-invocation: true
---

## Overview
What the skill does and why.

## Process
Steps or reference material for the skill.
```

**Key frontmatter fields:**
- `name` — Identifier for the skill (must match directory name)
- `description` — One-line summary (shown to users when the skill is listed)
- `disable-model-invocation: true` — Marks skill as user-invoked only (no auto-trigger)

For more guidance on skill design, see the `writing-great-skills` skill in this repository.

### Linking the New Skill

Adding a skill directory to the repo is **not** enough on its own — Claude Code only discovers skills that have a corresponding link in `~/.claude/skills/`, and that link is not created automatically when you add a new folder here. You must create it yourself, once, for each new skill:

```powershell
cd ~/.claude/skills
New-Item -ItemType Junction -Path <skill-name> -Target C:\Repos\agent-skills\<skill-name>
```

(From Git Bash, `ln -s /c/Repos/agent-skills/<skill-name> ~/.claude/skills/<skill-name>` works too.)

Without this step the skill will exist in the repo and in git history, but Claude Code won't list it or respond to it. This only needs to be done once per skill per machine — after that, edits and pulls flow through automatically (see "How It Works").

## Updating Skills

1. **Edit the skill** locally in its directory:
   ```powershell
   cd C:\Repos\agent-skills\<skill-name>
   # Edit SKILL.md or supporting files
   ```

2. **Test in Claude Code** — changes are immediately visible to the CLI/extension via junctions

3. **Commit and push**:
   ```powershell
   cd C:\Repos\agent-skills
   git add <skill-name>/
   git commit -m "feat(skill-name): description of change"
   git push origin main
   ```

4. **Pull updates** when working across machines:
   ```powershell
   cd C:\Repos\agent-skills
   git pull origin main
   ```

## Repository Structure

```
agent-skills/
├── README.md                    (this file)
├── LICENSE
├── backlog-grooming/            (auto-triggered skill)
│   ├── SKILL.md
│   ├── conventions-template.md
│   ├── mutations.md
│   ├── planning.md
│   └── queries.md
├── cleanup/                     (user-invoked skill)
│   └── SKILL.md
├── commit/                      (user-invoked skill)
│   └── SKILL.md
├── conference-submission-review/ (auto-triggered skill)
│   └── SKILL.md
├── plan-issue/                  (auto-triggered skill)
│   └── SKILL.md
├── pick-up-issue/                (auto-triggered skill)
│   └── SKILL.md
├── review-pr/                   (direct-argument skill)
│   └── SKILL.md
├── to-tickets/                  (user-invoked skill)
│   └── SKILL.md
├── verify-fixes/                (direct-argument skill)
│   └── SKILL.md
└── writing-great-skills/        (reference skill)
    ├── SKILL.md
    └── GLOSSARY.md
```

Currently, skills are organized flat at the repository root. As the collection grows, they may be organized into categories (e.g., `software-dev/`, `documentation/`) — this structure is flexible and can be refactored without breaking junctions, as long as the junction targets are updated.

## Tips

- **Skill discovery**: Pulling a new skill directory is not enough — you must also create its junction in `~/.claude/skills/` (see "Linking the New Skill" above) before Claude Code will discover it
- **Broken junctions**: If a junction becomes stale, you can recreate it: `Remove-Item <junction>; New-Item -ItemType Junction -Path <target> -Target <source>`
- **Version control**: Keep your skills versioned in git so you can track changes and revert if needed
- **Documentation**: Add a `GLOSSARY.md` or other supporting files if your skill is complex — keep the main `SKILL.md` lean by disclosing reference behind pointers
