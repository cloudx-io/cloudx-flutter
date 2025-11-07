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
10. **Publishes to public repository via PR**
    - Asks if you want to publish to cloudx-flutter (public repo)
    - Copies all git-tracked files from release branch
    - Creates release/X.Y.Z branch in public repo
    - Pushes branch and creates PR to main
    - Shows PR URL for review (final gate before customers see changes)
    - Asks: "Merge PR now or review later?"
    - If merged: Creates GitHub Release with CHANGELOG notes
    - Deletes release branch after merge
11. Reports completion with links to release

## Version Conflict Handling

When merging release → develop, version conflicts are expected:
- develop may have moved ahead (e.g., 0.5.0)
- release branch has older version (e.g., 0.4.0)
- **Agent automatically keeps develop's version** (newer)
- Other conflicts require manual resolution

## After Production

**Private repo (cloudx-flutter-private):**
- Release is finalized and tagged (v0.4.0)
- Release branch kept for historical reference
- Merged back to develop

**Public repo (cloudx-flutter):**
- PR created for review (or merged if you chose immediate merge)
- GitHub Release created (if PR merged)
- Customers can see release at: https://github.com/cloudx-io/cloudx-flutter/releases

**Next:**
- Review PR if not merged yet
- Publish to pub.dev when ready
- Announce to customers

## Public Repository Publishing

The agent creates a PR in the public repo for final review:

**Process:**
1. **Fresh copy** - All git-tracked files from release branch
2. **Release branch** - Creates release/X.Y.Z in public repo
3. **Pull Request** - PR to main (your final review gate)
4. **Review** - You can see exactly what customers will see
5. **Merge** - Merge now or later (flexible)
6. **GitHub Release** - Automatic creation with CHANGELOG notes
7. **Cleanup** - Release branch deleted after merge

**Benefits:**
- ✅ Final review before customers see changes
- ✅ CI can run on PR (future)
- ✅ Clean commit history in public repo
- ✅ Professional GitHub Release with notes
- ✅ No internal files leaked (only git-tracked files)

## Notes

- Follows GitFlow merge-back pattern
- Release branch is kept (not deleted)
- Tag v<version> indicates production status
- Shows all git commands for transparency
- Safe to abort before execution
- Handles merge conflicts gracefully
