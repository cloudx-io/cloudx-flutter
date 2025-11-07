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
- Publishes to public repository (cloudx-flutter)
- Keeps release branch for historical reference

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
10. **Publishes to public repository**
    - Asks if you want to publish to cloudx-flutter (public repo)
    - Copies all git-tracked files from release branch
    - Creates clean "Release vX.Y.Z" commit
    - Shows diff summary
    - Asks for final confirmation
    - Pushes to public repo main branch
11. Reports completion

## Version Conflict Handling

When merging release → develop, version conflicts are expected:
- develop may have moved ahead (e.g., 0.5.0)
- release branch has older version (e.g., 0.4.0)
- **Agent automatically keeps develop's version** (newer)
- Other conflicts require manual resolution

## After Production

- Release is finalized in private repository (tagged)
- Release branch kept for historical reference
- Tag indicates release is in production
- Published to cloudx-flutter (customer-facing public repo)
- Ready to publish to pub.dev

## Public Repository Publishing

The agent copies all git-tracked files from the release branch to the public repository:
- **Fresh copy each time** - Ensures perfect sync, captures deletions
- **Clean commit history** - Only "Release vX.Y.Z" commits in public repo
- **No internal files** - Only copies files tracked by git (excludes .claude/, etc.)
- **Confirmation gates** - Shows diff before pushing

## Notes

- Follows GitFlow merge-back pattern
- Release branch is kept (not deleted)
- Tag v<version> indicates production status
- Shows all git commands for transparency
- Safe to abort before execution
- Handles merge conflicts gracefully
