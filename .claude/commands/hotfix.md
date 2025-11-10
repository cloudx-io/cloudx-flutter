---
description: Create emergency fixes for production releases (post-production)
---

Invoke the release-manager agent to create an emergency hotfix for a production release.

**IMPORTANT FOR CLAUDE:** When you see this command, you MUST invoke the release-manager agent using the Task tool. Do NOT manually execute the steps. The agent handles the entire hotfix workflow automatically.

```
Use: Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Create hotfix following Workflow 4 in .claude/agents/release-manager.md"
```

**Usage:** `/hotfix`

**Note:** No arguments needed - agent will guide you interactively.

## What This Does

Creates a hotfix for a production release (bypasses normal release cycle):
- ✅ Lists available production tags
- ✅ Creates `hotfix/<new-version>` branch from selected tag
- ✅ Increments patch version (0.4.0 → 0.4.1)
- ✅ Updates CHANGELOG and version files
- ✅ You make code fixes
- ✅ Merges hotfix → develop
- ✅ Creates new git tag

**When to use:**
- Critical bug in production
- Can't wait for normal release cycle
- Don't want to include unreleased develop features

**After this command:**
- Deploy hotfix to production
- Manually publish to public repository if needed
- Notify customers

## Detailed Workflow

See `.claude/agents/release-manager.md` **Workflow 4: Post-Production Hotfix** (lines 740-972) for complete implementation details.
