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
git clone https://github.com/cloudx-io/cloudx-flutter-private.git
cd cloudx-flutter-private/cloudx_flutter_sdk
flutter pub get
```

---

## Version Management

This project manages three distinct SDK versions:
- **Flutter SDK Version** - The Flutter plugin wrapper (pubspec.yaml, build.gradle, podspec)
- **iOS SDK Version** - Native CloudXCore dependency (podspec)
- **Android SDK Version** - Native Android SDK dependency (build.gradle)

### Intelligent Version Updates (Recommended)

Use the `/update-version` slash command with Claude Code for intelligent, context-aware version updates:

```bash
# Update Flutter SDK version
/update-version flutter-sdk 0.4.0

# Update iOS native SDK version
/update-version ios-sdk 1.1.65

# Update Android native SDK version
/update-version android-sdk 0.7.0
```

**What the agent does:**
1. Searches entire codebase for all version references
2. Categorizes references (code, docs, historical changelog entries, examples)
3. Shows you exactly what will be updated (and what won't be)
4. Updates code files, documentation, and CHANGELOG.md consistently
5. Validates all changes and offers to create a git commit

**Benefits:**
- ✓ Finds all references automatically (including new docs you've added)
- ✓ Understands context (won't update historical CHANGELOG entries)
- ✓ Updates everything consistently
- ✓ No manual file editing needed
- ✓ Comprehensive validation

See `.claude/commands/update-version.md` for full documentation.

### Manual Version Updates (Alternative)

If you prefer manual updates without using the agent:

**Flutter SDK:**
```bash
# 1. Update version in pubspec.yaml
vim pubspec.yaml  # Change: version: 0.1.0 → 0.2.0

# 2. Update platform files
vim android/build.gradle  # Update version variable
vim ios/cloudx_flutter.podspec  # Update s.version

# 3. Update documentation references in README.md files

# 4. Update CHANGELOG.md
```

**iOS SDK:**
```bash
# 1. Update podspec dependency
vim ios/cloudx_flutter.podspec  # Change: s.dependency 'CloudXCore', '~> x.y.z'

# 2. Update documentation (README.md, CLAUDE.md)

# 3. Update CHANGELOG.md with iOS SDK update note
```

**Android SDK:**
```bash
# 1. Update build.gradle dependencies
vim android/build.gradle  # Change: implementation "io.cloudx:sdk:x.y.z"
vim ../cloudx_flutter_demo_app/android/app/build.gradle.kts  # Update all adapters

# 2. Update documentation (README.md)

# 3. Update CHANGELOG.md with Android SDK update note
```

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
# Update Flutter SDK version using intelligent agent (recommended)
/update-version flutter-sdk 0.2.0
# Agent will update pubspec.yaml, build.gradle, podspec, docs, and CHANGELOG

# OR manually update:
vim pubspec.yaml  # Bump version
./tool/sync_version.sh  # Sync to platform files
vim CHANGELOG.md  # Add release notes

# Commit (if not done by agent)
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

1. Go to https://github.com/cloudx-io/cloudx-flutter-private/releases
2. Click "Draft a new release"
3. Select tag `v0.2.0`
4. Title: `v0.2.0 - [Brief Title]`
5. Description: Copy from CHANGELOG.md
6. Publish release

---

## Development Tools

### Intelligent Version Management

The `/update-version` slash command (see Version Management section above) provides automated, context-aware version updates across the entire codebase.

### GitFlow Release Management

Release workflow commands (see Release Process section below):
- `/release <version>` - Create release branch
- `/qa-fix` - Apply bug fixes during QA
- `/production` - Finalize and tag release
- `/hotfix` - Post-production emergency fixes

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

- Check existing issues: https://github.com/cloudx-io/cloudx-flutter-private/issues
- Review CLAUDE.md for AI assistant guidance
- Contact CloudX team

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (Business Source License 1.1).
