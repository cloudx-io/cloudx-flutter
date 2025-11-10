---
description: Publish release to production
---

Invoke release-manager agent to publish the release after QA approval.

**Usage:** `/publish` (no arguments - automatically finds release branch)

**Agent Invocation:**
```
Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Publish release to production following Workflow 2 in .claude/agents/release-manager.md"
```

**What happens:**
- QA approval gate
- CHANGELOG review gate (ensures release notes are ready)
- Creates git tag (e.g., v0.8.0)
- Merges release branch → develop (handles version conflicts automatically)
- Deletes release branch (tag preserves release state)
- Publishes to public repo via PR (git archive + squash merge)
- Creates GitHub Release with CHANGELOG notes

**After this:**
- Release is live on GitHub
- Publish to pub.dev when ready
- Announce to customers

See `.claude/agents/release-manager.md` Workflow 2 for full details.
