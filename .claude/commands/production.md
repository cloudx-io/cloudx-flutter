---
description: Finalize release by tagging and merging back to develop
---

Invoke the release-manager agent to finalize a release and promote it to production.

**IMPORTANT FOR CLAUDE:** When you see this command, you MUST invoke the release-manager agent using the Task tool. Do NOT manually execute the steps. The agent handles the entire production workflow automatically.

```
Use: Task tool with subagent_type="general-purpose"
Prompt: "You are the release-manager agent. Finalize production release following the production workflow in .claude/agents/release-manager.md"
```

**Usage:** `/production`

**Note:** No arguments needed - agent will find the release branch.

## What This Does

Finalizes a release after QA approval:
- Creates git tag (e.g., v0.4.0)
- Merges release branch back to develop
- Handles version conflicts (keeps develop's newer version)
- Deletes release branch (tag preserves release state)
- Publishes to public repository (cloudx-flutter)

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
3. **CHANGELOG Review Gate** - Shows [X.Y.Z] release notes and asks "CHANGELOG ready to publish?"
4. Shows preview of production plan
5. Asks for confirmation
6. Creates git tag on release branch
7. Pushes tag to remote
8. Merges release → develop
9. Handles version conflicts automatically (keeps develop's version)
10. Pushes develop
11. **Publishes to public repository via PR**
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
- Release branch deleted (tag preserves release state)
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

**Technical Implementation:**
```bash
# 1. Clone public repo to temp location
cd /tmp && rm -rf cloudx-flutter-public
git clone git@github.com:cloudx-io/cloudx-flutter.git cloudx-flutter-public

# 2. Export all git-tracked files from private repo release branch
cd /path/to/private-repo
git archive release/X.Y.Z | tar -x -C /tmp/cloudx-flutter-public/

# 3. Create release branch in public repo
cd /tmp/cloudx-flutter-public
git checkout -b release/X.Y.Z

# 4. Commit and push
git add -A
git commit -m "Release X.Y.Z\n\n<CHANGELOG content>"
git push -u origin release/X.Y.Z

# 5. Create PR
gh pr create --repo cloudx-io/cloudx-flutter \
  --title "Release X.Y.Z" \
  --body "<CHANGELOG content>" \
  --base main \
  --head release/X.Y.Z

# 6. After PR is merged, create GitHub Release
gh release create vX.Y.Z --repo cloudx-io/cloudx-flutter \
  --title "Release X.Y.Z" \
  --notes "<CHANGELOG content>"
```

**Benefits:**
- ✅ Final review before customers see changes
- ✅ CI can run on PR (future)
- ✅ Clean commit history in public repo
- ✅ Professional GitHub Release with notes
- ✅ No internal files leaked (only git-tracked files)

**Important:** Always use PR workflow (never push directly to main)

**Validation Checklist:**
- [ ] Cloned public repo to /tmp
- [ ] Used `git archive` to export files
- [ ] Created release/X.Y.Z branch (not main)
- [ ] Created PR (verify PR URL returned)
- [ ] PR targets main branch
- [ ] If PR merge approved: GitHub Release created
- [ ] Deleted release branch in public repo (after merge)
- [ ] Deleted release branch in private repo (after merge to develop)
- [ ] Cleanup: /tmp directory removed

## Notes

- Follows GitFlow merge-back pattern
- Release branch is deleted after merge (tag preserves release state)
- Tag v<version> indicates production status
- Shows all git commands for transparency
- Safe to abort before execution
- Handles merge conflicts gracefully

## CHANGELOG Review Gate

This project follows [Keep a Changelog](https://keepachangelog.com/) format.

**During this command:**
- Agent shows the [X.Y.Z] release notes from CHANGELOG
- Review for accuracy, completeness, and professionalism
- These notes will appear in GitHub Release (public-facing)
- If CHANGELOG needs updates, abort and use `/qa-fix` to update it

**What to check:**
- All features/fixes documented?
- Proper categories used (Added/Changed/Deprecated/Removed/Fixed/Security)?
- No internal jargon or references?
- Professional tone for customers?
- No typos or formatting issues?

**Reference:** https://keepachangelog.com/
