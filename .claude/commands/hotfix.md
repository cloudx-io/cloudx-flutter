---
description: Emergency fix for production release
---

Invoke release-manager agent to create an emergency hotfix for a production release.

**Usage:** `/hotfix` (interactive - agent prompts which version to fix)

**Agent Invocation:**
```
Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Create hotfix following Workflow 3 in .claude/agents/release-manager.md"
```

**What happens:**
- Lists available production tags
- Creates `hotfix/<new-version>` branch from selected tag (e.g., v0.8.0 → hotfix/0.8.1)
- Bumps patch version automatically
- You make code fixes
- Merges hotfix → develop
- Creates new production tag

**Use when:**
- Critical production bug
- Can't wait for normal release cycle
- Don't want unreleased develop features included

See `.claude/agents/release-manager.md` Workflow 3 for full details.
