# Agent Skills

A curated collection of skills for Claude Code (CLI and VS Code extension). This repository serves as the single source of truth for agent skills, with junctions configured in your local Claude Code installation for automatic discovery.

## What's Inside

| Skill | Purpose |
|-------|---------|
| **commit** | Review changes with `git status` and `git diff`, stage files, write conventional commit messages with explanatory body, and push to origin. Reports the commit SHA after pushing. |
| **review-pr** | Review GitHub pull requests and post feedback as a PR comment. Analyzes diffs for correctness, security, error handling, tests, readability, and performance. Invoked with `/review-pr <PR URL>`. |
| **to-tickets** | Break a plan, spec, or conversation into tracer-bullet tickets with blocking relationships. Publishes to your configured issue tracker with dependencies declared. |
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
├── commit/                      (user-invoked skill)
│   └── SKILL.md
├── review-pr/                   (direct-argument skill)
│   └── SKILL.md
├── to-tickets/                  (user-invoked skill)
│   └── SKILL.md
└── writing-great-skills/        (reference skill)
    ├── SKILL.md
    └── GLOSSARY.md
```

Currently, skills are organized flat at the repository root. As the collection grows, they may be organized into categories (e.g., `software-dev/`, `documentation/`) — this structure is flexible and can be refactored without breaking junctions, as long as the junction targets are updated.

## Tips

- **Skill discovery**: If you add a new skill directory to the repo and pull, Claude Code will discover it on the next invocation
- **Broken junctions**: If a junction becomes stale, you can recreate it: `Remove-Item <junction>; New-Item -ItemType Junction -Path <target> -Target <source>`
- **Version control**: Keep your skills versioned in git so you can track changes and revert if needed
- **Documentation**: Add a `GLOSSARY.md` or other supporting files if your skill is complex — keep the main `SKILL.md` lean by disclosing reference behind pointers
