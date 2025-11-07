---
description: Apply bug fixes to release branch during QA testing (pre-production)
---

Invoke the release-manager agent to fix bugs found during QA testing on a release branch.

**Usage:** `/qa-fix`

**Note:** No arguments needed - run this while on a release branch.

## What This Does

Helps you commit and push bug fixes to the release branch during QA testing:
- Commits uncommitted changes (if any)
- Updates CHANGELOG.md under current version
- Pushes to remote
- **No version bump** (version stays same throughout QA)

## Pre-flight Checks

The agent validates:
- You're on a `release/*` branch
- Release branch exists on remote
- Branch is up to date with remote
- Release hasn't been promoted yet (no git tag)

## Process

1. Detects uncommitted or unpushed changes
2. Shows what will be committed
3. Asks for commit message (or uses default)
4. Shows preview of changes
5. Asks for confirmation
6. Commits changes
7. Updates CHANGELOG.md under [version] section
8. Pushes to remote
9. Reports completion

## Interactive Workflow

```bash
# 1. Switch to release branch if not already there
git checkout release/0.4.0

# 2. Make your code changes to fix bugs

# 3. Run qa-fix command
/qa-fix

# 4. Follow agent prompts
```

## After QA Fix

- QA can retest the release branch
- Run `/qa-fix` again if more fixes are needed
- Use `/production` when QA approves

## Notes

- Can be run multiple times (multiple QA iterations)
- Version remains the same (standard GitFlow)
- Shows all git commands for transparency
- Safe to abort if you change your mind
- For post-production fixes, use `/hotfix` instead
