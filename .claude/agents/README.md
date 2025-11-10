# CloudX Flutter SDK - Claude Code Agents

This directory contains specialized Claude Code subagents for the CloudX Flutter SDK project.

## Available Agents

### 🔧 **SDK Maintenance Agents**

#### `cloudx-flutter-agent-maintainer`
**When to use:** After making Flutter SDK API changes to sync agent documentation in cloudx-sdk-agents repo
- **Autonomous detection** of version changes and API modifications
- Auto-syncs agent docs with SDK changes
- Updates SDK_VERSION.yaml tracking file
- No manual specification of changes needed

**Example invocation:**
```
Sync cloudx-sdk-agents with latest Flutter SDK changes
@cloudx-flutter-agent-maintainer
```

**Key features:**
- Detects version bumps by comparing pubspec.yaml with SDK_VERSION.yaml
- Detects API changes by diffing lib/cloudx.dart and widget files
- Automatically determines what needs updating (version strings, API references, or both)
- Generates comprehensive sync reports
- Runs validation scripts

**Related agents:** version-updater (updates this SDK), release-manager (for releases)

---

### 🎯 **Core Development Agents**

#### `flutter-expert`
**When to use:** Flutter SDK development, widget composition, state management, testing
- Flutter 3+ architecture patterns
- Cross-platform development
- Performance optimization
- Widget testing strategies
- Platform-specific implementations

**Example invocation:**
```
Can you review the CloudX banner widget implementation for performance issues?
@flutter-expert
```

#### `swift-expert`
**When to use:** iOS plugin development, Objective-C/Swift interop, CloudX iOS SDK integration
- iOS platform channel implementation
- CloudX iOS SDK wrapper code
- Swift/Objective-C best practices
- Memory management review
- iOS-specific API implementations

**Example invocation:**
```
Review the iOS plugin CloudXFlutterSdkPlugin.m for delegate callback handling
@swift-expert
```

#### `kotlin-specialist`
**When to use:** Android plugin development, CloudX Android SDK integration
- Android platform channel implementation
- Kotlin coroutines and lifecycle
- CloudX Android SDK wrapper code
- Android-specific API implementations
- Gradle configuration

**Example invocation:**
```
Help implement deinitialize method in Android plugin with proper cleanup
@kotlin-specialist
```

#### `code-reviewer`
**When to use:** PR reviews, code quality checks, security audits
- Cross-platform consistency checks
- Security vulnerability detection
- Best practices enforcement
- Performance analysis
- Technical debt identification

**Example invocation:**
```
Review PR #10 for code quality, security issues, and platform consistency
@code-reviewer
```

## Usage Guidelines

### When to Use Agents

1. **Complex Feature Development**: Use domain-specific agents (flutter-expert, swift-expert) for implementing new ad types or SDK features

2. **Platform-Specific Issues**: Use swift-expert or kotlin-specialist when debugging native platform issues

3. **Code Reviews**: Use code-reviewer for systematic PR reviews before merging

4. **Architecture Decisions**: Use flutter-expert for Flutter SDK architecture patterns and state management decisions

5. **Performance Optimization**: Use flutter-expert or swift-expert for platform-specific performance tuning

### Best Practices

- **One agent per task**: Don't invoke multiple agents simultaneously for the same task
- **Provide context**: Give agents specific files, PRs, or issues to review
- **Clear objectives**: State what you want the agent to focus on
- **Sequential workflow**: Use agents in sequence (flutter-expert → code-reviewer → merge)

## Workflow Examples

### PR Review Workflow
```
1. Initial review: "Review PR #11 for functionality" @code-reviewer
2. Platform check: "Check iOS implementation" @swift-expert
3. Flutter layer: "Verify Dart API exposure" @flutter-expert
4. Final approval: Merge after all agents approve
```

### New Feature Development
```
1. Design: "Help design privacy API for GDPR compliance" @flutter-expert
2. iOS impl: "Implement iOS privacy methods" @swift-expert
3. Android impl: "Implement Android privacy methods" @kotlin-specialist
4. Review: "Review complete privacy implementation" @code-reviewer
```

### Bug Investigation
```
1. Reproduce: Describe the issue with logs
2. Platform diagnosis: Use @swift-expert or @kotlin-specialist
3. Flutter layer check: Use @flutter-expert if needed
4. Fix review: Use @code-reviewer for the fix
```

## Agent Customization

You can customize agents by editing their .md files:
- Add project-specific patterns
- Add CloudX SDK API references
- Customize checklists for your workflow
- Add integration points with CI/CD

## Future Agents to Consider

Based on project needs, consider adding:
- **test-automator**: For Flutter integration tests and platform-specific test automation
- **performance-engineer**: For detailed performance profiling and optimization
- **documentation-engineer**: For maintaining SDK documentation and API docs
- **mobile-developer**: For general cross-platform mobile architecture guidance

## Resources

- [Awesome Claude Code Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- [CloudX Flutter SDK CLAUDE.md](/CLAUDE.md)
- [Flutter Documentation](https://docs.flutter.dev)
