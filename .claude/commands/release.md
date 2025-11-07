---
description: Create a release candidate branch from develop for QA testing
---

Invoke the release-manager agent to prepare a new release following GitFlow standards.

**Usage:** `/release <version>`

**Example:** `/release 0.4.0`

## What This Does

Creates a release candidate branch (`release/<version>`) from develop with:
- Updated version numbers (pubspec.yaml, build.gradle, podspec, docs)
- Updated CHANGELOG.md with release date
- All changes committed and pushed to remote

**Important:** Version stays the same throughout QA testing (standard GitFlow).

## Pre-flight Checks

The agent validates:
- You're on the `develop` branch
- Working directory is clean
- develop is up to date with remote
- Version format is valid (x.y.z)
- Release branch doesn't already exist
- New version is greater than current version
- No other release in progress

## Process

1. Shows preview of all actions
2. Asks for confirmation
3. Creates release branch
4. Updates versions via version-updater agent
5. Updates CHANGELOG.md
6. Commits and pushes changes
7. Reports completion

## After Release Preparation

- QA team tests on `release/<version>` branch
- Use `/qa-fix` for bug fixes found during QA
- Use `/production` when QA approves

## Notes

- Strict validation - stops if any check fails
- Shows all git commands for transparency
- Reminds you to run tests before QA
- Version stays <version> throughout QA (no bumps for fixes)
