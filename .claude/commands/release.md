---
description: Create a release candidate branch from develop for QA testing
---

Invoke the release-manager agent to prepare a new release following GitFlow standards.

**IMPORTANT FOR CLAUDE:** When you see this command, you MUST invoke the release-manager agent using the Task tool. Do NOT manually execute the steps. The agent is defined in `.claude/agents/release-manager.md` and handles the entire workflow automatically.

```
Use: Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Prepare release <version> following Workflow 1 in .claude/agents/release-manager.md"
```

**Usage:** `/release <version>`

**Example:** `/release 0.4.0`

## What This Does

Creates a release candidate branch (`release/<version>`) from develop following GitFlow:
- ✅ Validates pre-flight checks (clean working directory, up to date, etc.)
- ✅ Shows CHANGELOG review gate
- ✅ Creates release branch with CHANGELOG update
- ✅ Clears [Unreleased] on develop for next version
- ✅ Bumps develop to next version (X.Y+1.0)
- ✅ All changes committed and pushed

**After this command:**
- QA team tests on `release/<version>` branch
- Use `/qa-fix` for bug fixes found during QA
- Use `/production` when QA approves

## Detailed Workflow

See `.claude/agents/release-manager.md` **Workflow 1: Release Preparation** (lines 41-210) for complete implementation details.
