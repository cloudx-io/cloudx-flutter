---
description: Create emergency fixes for production releases (post-production)
---

Invoke the release-manager agent to create an emergency hotfix for a production release.

**IMPORTANT FOR CLAUDE:** When you see this command, you MUST invoke the release-manager agent using the Task tool. Do NOT manually execute the steps. The agent handles the entire hotfix workflow automatically.

```
Use: Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Create hotfix following the hotfix workflow in .claude/agents/release-manager.md"
```

**Usage:** `/hotfix`

**Note:** No arguments needed - agent will guide you interactively.

## What This Does

Creates a hotfix for a production release following GitFlow hotfix workflow:
- Creates `hotfix/<new-version>` branch from a production tag
- Bumps patch version (e.g., 0.4.0 → 0.4.1)
- Updates CHANGELOG.md with new version section
- You make code fixes
- Commits and pushes changes
- Merges back to develop
- Creates new git tag

## Pre-flight Checks

The agent validates:
- At least one git tag exists (production releases exist)
- Working directory is clean
- You confirm which version to hotfix

## Process

1. Lists available production releases (git tags)
2. Asks which version needs a hotfix
3. Calculates new patch version (0.4.0 → 0.4.1)
4. Shows preview of hotfix plan
5. Creates hotfix branch from tag
6. Updates version and CHANGELOG
7. Waits for you to make code fixes (type 'ready' when done)
8. Commits fixes
9. Merges to develop
10. Creates new tag
11. Reports completion

## Interactive Workflow

```bash
# 1. Run hotfix command
/hotfix

# 2. Select which production version to hotfix
# Agent: "Which version needs a hotfix? [v0.4.0]"

# 3. Review plan and confirm

# 4. Agent creates branch and updates version

# 5. Make your code fixes

# 6. Type 'ready' when fixes are complete

# 7. Follow remaining prompts
```

## After Hotfix

- Deploy hotfix to production
- Copy to public repository
- Notify customers of the hotfix

## Notes

- Creates proper GitFlow hotfix branch
- Automatically bumps patch version
- Merges back to develop (handles version conflicts)
- Creates new git tag for the hotfix
- For QA fixes (pre-production), use `/qa-fix` instead
