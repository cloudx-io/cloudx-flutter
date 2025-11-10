---
description: Update SDK version numbers across codebase
---

Invoke version-updater agent to intelligently update SDK version numbers.

**Usage:** `/update-version <sdk-type> <new-version>`

**Agent Invocation:**
```
Task tool with subagent_type="general-purpose"
Prompt: "You are the version-updater agent. Update {{arg1}} to version {{arg2}}."
```

**SDK Types:**
- `flutter-sdk` - Flutter plugin version (pubspec.yaml, build.gradle, podspec)
- `ios-sdk` - Native iOS CloudXCore dependency version
- `android-sdk` - Native Android SDK dependency version

**Examples:**
```bash
/update-version flutter-sdk 0.9.0
/update-version ios-sdk 1.1.65
/update-version android-sdk 1.1.40
```

**What happens:**
- Searches entire codebase for version references
- Categorizes by context (code, docs, historical)
- Shows detailed plan of what will/won't be updated
- Asks for confirmation
- Updates files with context-aware replacements
- Validates consistency
- Shows git diff
- Offers to create commit

**Smart behavior:**
- ✓ Updates version declarations in code files
- ✓ Updates documentation references
- ✓ Preserves formatting and structure
- ✗ Never updates historical CHANGELOG entries
- ✗ Never updates git tag URLs or release links

See version-updater agent for implementation details.
