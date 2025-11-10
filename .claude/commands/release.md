---
description: Create a release candidate branch from develop for QA testing
---

Invoke the release-manager agent to prepare a new release following GitFlow standards.

**Usage:** `/release <version>`

**Example:** `/release 0.4.0`

## What This Does

Creates a release candidate branch (`release/<version>`) from develop following GitFlow best practices:
- Validates develop is already at target version (or bumps if needed)
- Creates release branch with CHANGELOG.md update
- Automatically bumps develop to next version (X.Y+1.0)
- All changes committed and pushed to remote

**GitFlow Best Practice:** develop should be at the release version before branching, then immediately bumped to the next version after.

**Important:** Version stays the same throughout QA testing (standard GitFlow).

## Pre-flight Checks

The agent validates:
- You're on the `develop` branch
- Working directory is clean
- develop is up to date with remote
- Version format is valid (x.y.z)
- Release branch doesn't already exist
- Current version on develop matches or is less than target version
- No other release in progress

## Process

1. Shows preview of all actions
2. Asks for confirmation
3. **If needed:** Bumps develop to target version (X.Y.Z)
4. Creates release branch from develop
5. Updates CHANGELOG.md on release branch
6. Commits and pushes release branch
7. **Returns to develop and bumps to next version (X.Y+1.0)**
8. Commits and pushes develop
9. Reports completion

## After Release Preparation

- QA team tests on `release/<version>` branch
- Use `/qa-fix` for bug fixes found during QA
- Use `/production` when QA approves

## Notes

- Strict validation - stops if any check fails
- Shows all git commands for transparency
- Reminds you to run tests before QA
- Version stays <version> throughout QA (no bumps for fixes)
- Follows GitFlow best practice: develop is always ahead of the current release
- After this command, develop will be at version X.Y+1.0, ready for next release
