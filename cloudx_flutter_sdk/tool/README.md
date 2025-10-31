# CloudX Flutter SDK Tools

This directory contains development and maintenance scripts for the CloudX Flutter SDK.

## Scripts

### `sync_version.sh`

Synchronizes the SDK version from `pubspec.yaml` to all platform-specific files.

**Single Source of Truth:** Version is defined **only** in `pubspec.yaml`.

**Usage:**
```bash
# From SDK root directory
./tool/sync_version.sh
```

**What it does:**
1. Reads version from `pubspec.yaml`
2. Updates `android/build.gradle`
3. Updates `ios/cloudx_flutter.podspec`

**When to use:**
- When updating the SDK version for a new release
- After manually changing version in `pubspec.yaml`

**Example workflow:**
```bash
# 1. Update version in pubspec.yaml
vim pubspec.yaml  # Change version: 0.1.0 → 0.2.0

# 2. Sync to all files
./tool/sync_version.sh

# 3. Commit
git add pubspec.yaml android/build.gradle ios/cloudx_flutter.podspec
git commit -m "Bump version to 0.2.0"
```

## Why `tool/` directory?

The `tool/` directory is the **Dart/Flutter package convention** for development scripts:
- Used by Flutter framework itself
- Expected location by Dart developers
- Keeps root directory clean
- Distinct from user-facing `scripts/` (if any)

## Other Potential Tools

Future scripts that could live here:
- `bump_version.sh` - Interactive version bumping
- `publish_check.sh` - Pre-publication validation
- `generate_changelog.sh` - Auto-generate CHANGELOG entries
- `format_code.sh` - Batch code formatting
