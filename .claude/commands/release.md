---
description: Prepare release branch for QA testing
---

Invoke release-manager agent to prepare a new release following GitFlow.

**Usage:** `/release <version>` (e.g., `/release 0.8.0`)

**Agent Invocation:**
```
Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Prepare release <version> following Workflow 1 in .claude/agents/release-manager.md"
```

**What happens:**
- Creates `release/<version>` branch from develop (version already correct)
- Pushes release branch to remote
- Bumps develop to next version (e.g., 0.8.0 → 0.9.0)
- Commits and pushes develop

**After this:**
- ⚠️ **Manually update CHANGELOG.md** on release branch with all changes since last release
- QA tests on release branch
- Fix bugs directly on release branch (commit and push normally)
- Run `/publish` when QA approves

See `.claude/agents/release-manager.md` Workflow 1 for full details.
