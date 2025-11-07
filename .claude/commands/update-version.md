---
description: Intelligently update SDK version numbers across the codebase
---

Invoke the version-updater agent to update the {{arg1}} SDK to version {{arg2}}.

The agent will:
1. Search the entire codebase for all references to the current version
2. Categorize each reference by context (code, docs, historical, examples)
3. Present a detailed plan showing what will and won't be updated
4. Ask for your confirmation before making changes
5. Execute the updates using context-aware replacements
6. Validate that all references are consistent
7. Show git diff of changes
8. Offer to create a properly formatted git commit

## Usage

```bash
/update-version <sdk-type> <new-version>
```

## SDK Types

- `flutter-sdk` - Updates the Flutter plugin wrapper version (pubspec.yaml, build.gradle, podspec)
- `ios-sdk` - Updates the native iOS CloudXCore SDK version (podspec dependency)
- `android-sdk` - Updates the native Android SDK version (build.gradle dependencies)

## Examples

Update iOS SDK to 1.1.65:
```bash
/update-version ios-sdk 1.1.65
```

Update Flutter SDK to 0.4.0:
```bash
/update-version flutter-sdk 0.4.0
```

Update Android SDK to 0.7.0:
```bash
/update-version android-sdk 0.7.0
```

## What Gets Updated

The agent understands context and will:

✓ Update version declarations in code files (pubspec.yaml, build.gradle, podspec)
✓ Update documentation references (README.md, CLAUDE.md)
✓ Update CHANGELOG.md [Unreleased] section or create new version entry
✓ Preserve formatting, prefixes (~>, ^), and code structure

⊘ Never update historical CHANGELOG entries
⊘ Never update git tag URLs or release links
⊘ Never update unrelated version numbers

## Smart Features

- **Context-aware**: Distinguishes between active versions, documentation, and historical references
- **Comprehensive**: Finds all references across the entire codebase
- **Safe**: Shows you exactly what will change before making edits
- **Consistent**: Ensures all references are updated together
- **Validated**: Checks for missed references after updates

## Notes

- The agent will ask for confirmation before making any changes
- You'll see a git diff of all modifications before committing
- If ambiguous references are found, the agent will ask for guidance
- CHANGELOG updates are included automatically
