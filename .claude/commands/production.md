---
description: Finalize release by tagging and merging back to develop
---

Invoke the release-manager agent to finalize a release and promote it to production.

**IMPORTANT FOR CLAUDE:** When you see this command, you MUST invoke the release-manager agent using the Task tool. Do NOT manually execute the steps. The agent handles the entire production workflow automatically.

```
Use: Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Finalize production release following Workflow 3 in .claude/agents/release-manager.md"
```

**Usage:** `/production`

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

See `.claude/agents/release-manager.md` **Workflow 3: Production Release** (lines 364-738) for complete implementation details.
