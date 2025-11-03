# Contributing to CloudX Flutter SDK

This guide is for developers working on the CloudX Flutter SDK itself.

## Development Setup

### Prerequisites

- Flutter SDK 3.0.0+
- Dart SDK 3.0.0+
- Android Studio / Xcode for platform-specific development
- Git

### Clone and Setup

```bash
git clone https://github.com/cloudx-io/cloudx-flutter.git
cd cloudx-flutter/cloudx_flutter_sdk
flutter pub get
```

---

## Version Management

**Single Source of Truth:** Version is defined **only** in `pubspec.yaml`.

### Updating the SDK Version

When releasing a new version:

```bash
# 1. Update version in pubspec.yaml
vim pubspec.yaml  # Change: version: 0.1.0 → 0.2.0

# 2. Sync to all platform files
./tool/sync_version.sh

# 3. Update CHANGELOG.md
vim CHANGELOG.md  # Add release notes

# 4. Commit all version changes
git add pubspec.yaml android/build.gradle ios/cloudx_flutter.podspec CHANGELOG.md
git commit -m "Bump version to 0.2.0"

# 5. Create and push tag
git tag -a v0.2.0 -m "CloudX Flutter SDK v0.2.0"
git push origin main
git push origin v0.2.0
```

The `sync_version.sh` script automatically updates:
- `android/build.gradle`
- `ios/cloudx_flutter.podspec`

See `tool/README.md` for more details about development tools.

---

## Project Structure

```
cloudx_flutter_sdk/
├── lib/                   # Dart/Flutter code
│   ├── cloudx.dart       # Main SDK class
│   ├── models/           # Data models
│   ├── listeners/        # Event callbacks
│   └── widgets/          # Flutter widgets
├── android/              # Android (Kotlin) implementation
│   ├── src/main/kotlin/
│   └── build.gradle
├── ios/                  # iOS (Objective-C) implementation
│   ├── Classes/
│   └── cloudx_flutter.podspec
├── tool/                 # Development scripts
├── pubspec.yaml          # Package metadata & version
├── README.md             # User documentation
├── CHANGELOG.md          # Release history
└── CONTRIBUTING.md       # This file
```

---

## Making Changes

### Code Style

- **Dart**: Follow official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- **Format code**: Run `dart format .` before committing
- **Analyze**: Run `flutter analyze` to check for issues

### Testing

```bash
# Run the demo app
cd ../cloudx_flutter_demo_app
flutter run

# Test on both platforms
flutter run -d ios
flutter run -d android
```

### Commit Messages

Use clear, descriptive commit messages:

```
Good:
- "Add support for native ads"
- "Fix memory leak in banner auto-refresh"
- "Update Android Gradle to 8.1.0"

Bad:
- "fix bug"
- "updates"
- "wip"
```

---

## Release Process

### 1. Prepare Release

```bash
# Update version
vim pubspec.yaml  # Bump version

# Sync versions
./tool/sync_version.sh

# Update changelog
vim CHANGELOG.md  # Add release notes

# Commit
git add pubspec.yaml android/build.gradle ios/cloudx_flutter.podspec CHANGELOG.md
git commit -m "Release v0.2.0"
```

### 2. Test Release

```bash
# Dry run pub.dev publish
flutter pub publish --dry-run

# Should show: "Package has 0 warnings"
```

### 3. Create Git Tag

```bash
git tag -a v0.2.0 -m "CloudX Flutter SDK v0.2.0 - [brief description]"
git push origin main
git push origin v0.2.0
```

### 4. Publish to pub.dev (when ready)

```bash
flutter pub publish
```

### 5. Create GitHub Release (optional)

1. Go to https://github.com/cloudx-io/cloudx-flutter/releases
2. Click "Draft a new release"
3. Select tag `v0.2.0`
4. Title: `v0.2.0 - [Brief Title]`
5. Description: Copy from CHANGELOG.md
6. Publish release

---

## Development Tools

### `tool/sync_version.sh`

Synchronizes version from `pubspec.yaml` to platform-specific files.

**Usage:**
```bash
./tool/sync_version.sh
```

**What it does:**
- Reads version from `pubspec.yaml`
- Updates `android/build.gradle`
- Updates `ios/cloudx_flutter.podspec`

See `tool/README.md` for more details.

---

## Adding New Features

### 1. Plan

- Check if feature exists in Android SDK
- Check if feature exists in iOS SDK (CloudXCore)
- Ensure API consistency across platforms

### 2. Implement

**Dart Layer** (`lib/cloudx.dart`):
```dart
/// Description of feature
static Future<bool> newFeature({required String param}) async {
  return await _invokeMethod<bool>('newFeature', {'param': param}) ?? false;
}
```

**Android Layer** (`android/.../CloudXFlutterSdkPlugin.kt`):
```kotlin
"newFeature" -> {
    val param = call.argument<String>("param")
    // Implementation
    result.success(true)
}
```

**iOS Layer** (`ios/Classes/CloudXFlutterSdkPlugin.m`):
```objc
if ([@"newFeature" isEqualToString:call.method]) {
    NSString *param = call.arguments[@"param"];
    // Implementation
    result(@YES);
}
```

### 3. Document

- Add to README.md (user docs)
- Add to CHANGELOG.md
- Update API reference section

### 4. Test

- Test on Android
- Test on iOS
- Update demo app with example

---

## Platform-Specific Notes

### Android

- **Language:** Kotlin
- **Min SDK:** API 21 (Android 5.0)
- **Gradle:** 8.1.0
- **Build:** `./gradlew assembleDebug` in demo app

### iOS

- **Language:** Objective-C
- **Min Version:** iOS 14.0
- **Dependency:** CloudXCore pod (~> 1.1.40)
- **Build:** `pod install` then build in Xcode

---

## Troubleshooting

### Version sync not working

Make sure script is executable:
```bash
chmod +x tool/sync_version.sh
```

### pub.dev publish fails

Check requirements:
- Version in pubspec.yaml is updated
- CHANGELOG.md has entry for new version
- No uncommitted changes
- `flutter pub publish --dry-run` passes

### Build errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## Getting Help

- Check existing issues: https://github.com/cloudx-io/cloudx-flutter/issues
- Review CLAUDE.md for AI assistant guidance
- Contact CloudX team

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (Business Source License 1.1).
