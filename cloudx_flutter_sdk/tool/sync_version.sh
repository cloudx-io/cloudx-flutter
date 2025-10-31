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

echo "✅ Version synced to all files"
echo ""
echo "Files updated:"
echo "  - android/build.gradle: $VERSION"
echo "  - ios/cloudx_flutter.podspec: $VERSION"
