---
description: Publish release to production
---

Invoke the release-manager agent to publish a release to production.

**IMPORTANT FOR CLAUDE:** When you see this command, you MUST invoke the release-manager agent using the Task tool. Do NOT manually execute the steps. The agent handles the entire publish workflow automatically.

```
Use: Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Publish release to production following Workflow 2 in .claude/agents/release-manager.md"
```

**Usage:** `/publish`

**Note:** No arguments needed - agent will find the release branch.

## What This Does

Finalizes a release after QA approval:
- ✅ QA approval gate
- ✅ CHANGELOG review gate
- ✅ Creates git tag (e.g., v0.4.0)
- ✅ Merges release branch back to develop
- ✅ Handles version conflicts (keeps develop's newer version)
- ✅ Deletes release branch (tag preserves release state)
- ✅ Publishes to public repository (cloudx-flutter) via PR
- ✅ Creates GitHub Release with CHANGELOG notes

**After this command:**
- Release is live on GitHub
- Publish to pub.dev when ready
- Announce to customers

## Version Conflict Handling

When merging release → develop, version conflicts are expected and handled automatically:
- develop is ahead (e.g., 0.6.0)
- release has older version (e.g., 0.5.0)
- Agent keeps develop's version (newer)

## Detailed Workflow

See `.claude/agents/release-manager.md` **Workflow 2: Production Release** for complete implementation details.
