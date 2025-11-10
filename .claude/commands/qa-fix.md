---
description: Apply bug fixes to release branch during QA testing (pre-production)
---

Invoke the release-manager agent to fix bugs found during QA testing on a release branch.

**IMPORTANT FOR CLAUDE:** When you see this command, you MUST invoke the release-manager agent using the Task tool. Do NOT manually execute the steps. The agent handles the QA fix workflow automatically.

```
Use: Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Apply QA fixes following Workflow 2 in .claude/agents/release-manager.md"
```

**Usage:** `/qa-fix`

**Note:** No arguments needed - run this while on a release branch.

## What This Does

Helps you commit and push bug fixes to the release branch during QA testing:
- ✅ Validates you're on a release branch
- ✅ Commits uncommitted changes (prompts for commit message)
- ✅ Updates CHANGELOG.md under [version] section
- ✅ Pushes to remote
- ✅ Version stays the same (no version bump)

**After this command:**
- QA retests the release branch
- Run `/qa-fix` again if more fixes needed
- Run `/production` when QA approves

## Detailed Workflow

See `.claude/agents/release-manager.md` **Workflow 2: QA Bug Fixes** (lines 212-362) for complete implementation details.
