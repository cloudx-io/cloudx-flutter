# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CloudX Flutter SDK is a Flutter plugin wrapper for the CloudX Core native SDK (iOS Objective-C and Android Kotlin). It provides comprehensive ad monetization capabilities including banner, interstitial, rewarded, native, and MREC ads, with full privacy compliance (CCPA/GDPR/COPPA/GPP) and targeting APIs.

**Repository Structure:**
- `cloudx_flutter_sdk/` - The Flutter plugin SDK package
- `cloudx_flutter_demo_app/` - Full-featured demo app showcasing all ad types

## Development Commands

### Setup
```bash
# Install Flutter dependencies
cd cloudx_flutter_sdk
flutter pub get

# Install iOS pods (required for iOS development)
cd ios && pod install && cd ..

# Setup demo app
cd cloudx_flutter_demo_app
flutter pub get
cd ios && pod install && cd ..
```

### Running the Demo App
```bash
cd cloudx_flutter_demo_app
flutter run                    # Run on connected device/emulator
flutter run -d ios             # Run on iOS specifically
flutter run -d android         # Run on Android specifically
```

### Linting & Analysis
```bash
cd cloudx_flutter_sdk
flutter analyze                # Run static analysis
dart format lib/ --set-exit-if-changed  # Check formatting
dart format lib/ -w            # Format code
```

### iOS Development
```bash
cd cloudx_flutter_sdk/ios
pod install                    # Install/update iOS dependencies
pod update CloudXCore          # Update CloudX Core dependency
```

The iOS plugin depends on `CloudXCore` (~> 1.1.40) which is the native Objective-C SDK.

### Android Development
```bash
cd cloudx_flutter_demo_app/android
./gradlew assembleDebug        # Build Android debug APK
./gradlew assembleRelease      # Build Android release APK
```

## Architecture

### Flutter Plugin Architecture (Platform Channels)

The SDK uses Flutter's platform channels to bridge between Dart and native code:

**MethodChannel** (`cloudx_flutter_sdk`): Bidirectional method calls for SDK initialization, ad creation, loading, showing, etc.

**EventChannel** (`cloudx_flutter_sdk_events`): Streams ad lifecycle events (load, show, click, impression) from native to Dart.

**PlatformView**: Embeds native UIView (iOS) or View (Android) for banner/MREC/native ads.

### Dart Layer (cloudx_flutter_sdk/lib/)

**Entry Point:** `lib/cloudx.dart` - Main CloudX class with static methods for all SDK operations

**Models:** `lib/models/clx_ad.dart` - CLXAd model representing ad metadata (placement, bidder, revenue)

**Listeners:** `lib/listeners/` - Ad lifecycle callbacks using composition pattern:
- `base_ad_listener.dart` - Common callbacks (onAdLoaded, onAdFailedToLoad, onAdClicked, etc.)
- `banner_listener.dart` - Banner-specific (onAdExpanded, onAdCollapsed)
- `rewarded_listener.dart` - Rewarded-specific (onRewarded, onRewardedVideoStarted/Completed)
- `interstitial_listener.dart`, `native_listener.dart`, `mrec_listener.dart`

### Native iOS Layer (cloudx_flutter_sdk/ios/)

**Bridge:** `Classes/CloudXFlutterSdkPlugin.m` - Objective-C plugin implementing:
- MethodChannel handler for SDK calls
- EventChannel stream handler for sending events to Dart
- PlatformView factories (CloudXBannerPlatformViewFactory, CloudXNativePlatformViewFactory, etc.)
- CLXAdDelegate implementations for all ad types

**State Management:** Plugin maintains dictionaries:
- `adInstances` - Maps adId (Flutter string) to native ad instances
- `placementToAdIdMap` - Maps CloudX internal placement IDs to Flutter adIds (critical for event routing)
- `pendingResults` - Stores FlutterResult callbacks for async operations

**Dependency:** CloudXCore pod (~> 1.1.40) provides the native iOS SDK

### Native Android Layer (cloudx_flutter_sdk/android/)

**Bridge:** `src/main/kotlin/io/cloudx/flutter/CloudXFlutterSdkPlugin.kt` - Kotlin plugin implementing:
- MethodCallHandler for SDK calls
- EventChannel.StreamHandler for event streaming
- Ad instance lifecycle management

**PlatformViews:** `CloudXAdViewFactory.kt` - Factory for banner/MREC/native views

### Demo App Architecture (cloudx_flutter_demo_app/)

**Entry:** `lib/main.dart` - SDK initialization with environment selection (dev/staging/production)

**Configuration:** `lib/config/demo_config.dart` - Environment configs with app keys and placement names for iOS/Android

**Screens:** `lib/screens/` - One screen per ad type (BannerScreen, MRECScreen, InterstitialScreen, RewardedScreen, NativeScreen)

**Base Screen:** `lib/screens/base_ad_screen.dart` - Abstract base with common ad management logic

**Logs Viewer:** `lib/screens/logs_modal_screen.dart` - Displays delegate callback logs with CLXAd metadata for debugging

## Key Implementation Patterns

### Ad Lifecycle Pattern

All ad types follow this lifecycle:
1. **Create** - `CloudX.createBanner(placement, adId, listener)` - Registers listener, creates native instance
2. **Load** - `CloudX.loadBanner(adId)` - Initiates bid request
3. **Show** - `CloudX.showBanner(adId)` or auto-render for banner/MREC/native via PlatformView widget
4. **Destroy** - `CloudX.destroyAd(adId)` - Cleanup when done (critical to prevent memory leaks)

### Event Flow (Native → Dart)

1. Native ad delegate callback fires (e.g., CLXBannerDelegate's `adDidLoad:`)
2. Plugin sends event via EventChannel: `@{@"event": @"didLoad", @"adId": adId, @"data": @{@"ad": adDict}}`
3. Dart CloudX._handleEvent receives event, looks up listener by adId
4. CloudX._dispatchEventToListener calls appropriate callback (e.g., `listener.onAdLoaded?.call(ad)`)

### AdId Mapping Critical Detail

CloudX SDK uses internal placement IDs, but Flutter uses string `adId` parameters. The `placementToAdIdMap` in the native plugin is essential:
- When creating an ad, store: `placementToAdIdMap[internalPlacementId] = flutterAdId`
- When delegate callback fires with `internalPlacementId`, look up the corresponding `flutterAdId` to route events correctly

### Privacy Compliance APIs

The SDK provides comprehensive privacy controls that affect bid requests:
- **CCPA**: `setCCPAPrivacyString()`, `setIsDoNotSell()` - Fully supported, included in bid requests
- **GPP**: `setGPPString()`, `setGPPSid()` - Global Privacy Platform support
- **COPPA**: `setIsAgeRestrictedUser()` - Clears user data but not yet included in bid requests (server limitation)
- **GDPR**: `setIsUserConsent()` - Not yet supported by CloudX servers, contact CloudX for GDPR needs

### Auto-Refresh for Banner/MREC

Banner and MREC ads support server-controlled auto-refresh:
- `CloudX.startAutoRefresh(adId)` - Enables periodic reloading
- `CloudX.stopAutoRefresh(adId)` - Must be called when destroying ads to prevent background timers
- Refresh interval configured server-side in CloudX dashboard

## Common Pitfalls

1. **Not destroying ads**: Always call `CloudX.destroyAd(adId)` in Widget dispose() to prevent memory leaks and orphaned timers
2. **Missing event stream initialization**: The plugin uses lazy initialization of EventChannel - listeners may be missed if not properly awaited
3. **AdId mapping bugs**: If native delegate callbacks aren't reaching Dart listeners, check that `placementToAdIdMap` is correctly populated
4. **iOS minimum version**: Plugin requires iOS 14.0+ (set in Podfile: `platform :ios, '14.0'`)
5. **Logging in production**: `CloudX.setLoggingEnabled(true)` should only be used during development - disable for production builds

## Testing

The SDK currently has no automated test suite. Testing is done via the demo app:

```bash
cd cloudx_flutter_demo_app
flutter run
# Test each ad type through the UI tabs
# Check console logs for delegate callbacks
# View "Logs" screen in app to see delegate callback history with CLXAd metadata
```

For iOS system logs with full detail:
```bash
xcrun simctl spawn booted log stream --predicate 'subsystem == "io.cloudx.sdk"' --level=debug
```

For Android logcat:
```bash
adb logcat | grep "CX:"
```

## API Alignment

The Flutter SDK API is designed to fully match the iOS SDK public API surface. When adding features:
1. Check the iOS CloudXCore SDK header for the authoritative API
2. Implement the Android equivalent if needed
3. Expose via Dart with matching semantics
4. Update demo app to showcase the new feature

## Environment Configuration

The demo app supports three environments (dev/staging/production) with different app keys and placements configured in `demo_config.dart`. iOS and Android use separate configurations.

**iOS**: Environment set via `CloudX.setEnvironment()` before initialization
**Android**: Environment set via CloudXInitializationServer enum

## Debugging Tips

1. Enable verbose logging early: `await CloudX.setLoggingEnabled(true)` before `CloudX.initialize()`
2. Check EventChannel ready state - native side sends `__eventChannelReady__` event to confirm stream is active
3. Use demo app's Logs screen to see delegate callback timeline with full CLXAd metadata
4. Banner/MREC/Native ads render via PlatformView - check native view hierarchy if not displaying
5. Interstitial/Rewarded ads are full-screen modal - check view controller hierarchy if not showing

## Release Management & CHANGELOG

This project follows GitFlow and maintains a CHANGELOG using the [Keep a Changelog](https://keepachangelog.com/) format.

### CHANGELOG Guidelines

**Format Standard:** [Keep a Changelog 1.0.0](https://keepachangelog.com/)

**Categories (use exactly these):**
- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Vulnerability fixes

**Best Practices:**
1. **Customer-facing only** - CHANGELOG is for customers. Only document changes that affect SDK users (new features, bug fixes, API changes). Do NOT include internal changes (refactoring, CI/CD updates, documentation improvements, tooling changes)
2. **Update continuously** - Add entries to [Unreleased] as you develop, don't wait until release time
3. **Be specific** - "Added support for rewarded video ads" not "Added features"
4. **User-focused** - "Fixed crash when loading ads" not "Fixed null pointer exception in AdManager.java:142"
5. **One change per line** - Each bullet should describe a single change
6. **Link issues/PRs** - Reference GitHub issues when relevant

**Workflow Integration:**
- `/release` command reviews CHANGELOG before creating release branch (Gate 1)
- `/production` command reviews CHANGELOG before publishing (Gate 2)
- CHANGELOG content appears in GitHub Releases for customers

**Example Entry:**
```markdown
## [Unreleased]

### Added
- Support for rewarded video ads with completion callbacks (#123)
- New `setUserAge()` method for age-based targeting

### Changed
- Updated CloudX iOS SDK from 1.1.60 to 1.1.65
- Improved ad loading performance by 15%

### Fixed
- Fixed crash when rapidly loading/destroying interstitial ads (#145)
- Resolved memory leak in banner ad auto-refresh
```

**What NOT to include:**
- ❌ "Updated release workflow documentation"
- ❌ "Refactored internal event handling"
- ❌ "Added CHANGELOG review gates"
- ❌ "Improved CI/CD pipeline"
- ❌ "Updated CLAUDE.md with best practices"

These are internal changes that don't affect SDK users.

**Reference:** See `cloudx_flutter_sdk/CHANGELOG.md` for the project's CHANGELOG file.
