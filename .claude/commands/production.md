---
description: Finalize release by tagging and merging back to develop
---

Invoke the release-manager agent to finalize a release and promote it to production.

**Usage:** `/production`

**Note:** No arguments needed - agent will find the release branch.

## What This Does

Finalizes a release after QA approval:
- Creates git tag (e.g., v0.4.0)
- Merges release branch back to develop
- Handles version conflicts (keeps develop's newer version)
- Keeps release branch for historical reference

**Note:** Copying to public repository is handled separately (next phase).

## Pre-flight Checks

The agent validates:
- A release branch exists
- Release branch is up to date with remote
- Working directory is clean
- Git tag doesn't already exist
- You confirm QA has approved

## Process

1. Identifies release branch
2. **QA Approval Gate** - Asks "Has QA approved?"
3. Shows preview of production plan
4. Asks for confirmation
5. Creates git tag on release branch
6. Pushes tag to remote
7. Merges release → develop
8. Handles version conflicts automatically (keeps develop's version)
9. Pushes develop
10. Reports completion

## Version Conflict Handling

When merging release → develop, version conflicts are expected:
- develop may have moved ahead (e.g., 0.5.0)
- release branch has older version (e.g., 0.4.0)
- **Agent automatically keeps develop's version** (newer)
- Other conflicts require manual resolution

## After Production

- Release is finalized in this repository (tagged)
- Release branch kept for historical reference
- Tag indicates release is in production
- Next: Copy to public repository (separate workflow)
- Optionally: Publish to pub.dev

## Notes

- Follows GitFlow merge-back pattern
- Release branch is kept (not deleted)
- Tag v<version> indicates production status
- Shows all git commands for transparency
- Safe to abort before execution
- Handles merge conflicts gracefully
