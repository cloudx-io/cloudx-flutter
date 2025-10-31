#!/bin/bash
# Sync version from pubspec.yaml to all other files
# Usage: ./sync_version.sh

set -e

# Get version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')

echo "Syncing version: $VERSION"

# Update Android build.gradle
sed -i.bak "s/^version '.*'/version '$VERSION'/" android/build.gradle
rm android/build.gradle.bak

# Update iOS podspec
sed -i.bak "s/s.version.*=.*/s.version          = '$VERSION'/" ios/cloudx_flutter.podspec
rm ios/cloudx_flutter.podspec.bak

# Update README.md (SDK package) - dependency version
sed -i.bak "s/cloudx_flutter: \^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/cloudx_flutter: ^$VERSION/" README.md
# Update README.md (SDK package) - git ref tag
sed -i.bak "s/ref: v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/ref: v$VERSION/" README.md
# Update README.md (SDK package) - version badge
sed -i.bak "s/\*\*Version:\*\* [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/\*\*Version:\*\* $VERSION/" README.md
rm README.md.bak

# Update root README.md - dependency version
sed -i.bak "s/cloudx_flutter: \^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/cloudx_flutter: ^$VERSION/" ../README.md
# Update root README.md - git ref tag
sed -i.bak "s/ref: v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/ref: v$VERSION/" ../README.md
# Update root README.md - version badge
sed -i.bak "s/\*\*Version:\*\* [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/\*\*Version:\*\* $VERSION/" ../README.md
rm ../README.md.bak

echo "✅ Version synced to all files"
echo ""
echo "Files updated:"
echo "  - android/build.gradle: $VERSION"
echo "  - ios/cloudx_flutter.podspec: $VERSION"
echo "  - README.md (dependency): cloudx_flutter: ^$VERSION"
echo "  - README.md (git ref): ref: v$VERSION"
echo "  - README.md (version badge): **Version:** $VERSION"
echo "  - ../README.md (dependency): cloudx_flutter: ^$VERSION"
echo "  - ../README.md (git ref): ref: v$VERSION"
echo "  - ../README.md (version badge): **Version:** $VERSION"
