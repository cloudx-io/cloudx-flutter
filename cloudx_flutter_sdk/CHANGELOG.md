# Changelog

All notable changes to the CloudX Flutter SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.17.0] - 2025-11-12

### Changed
- **BREAKING**: iOS SDK support temporarily disabled - iOS native SDK not yet ready for production
  - CloudXCore pod dependency removed from iOS plugin
  - iOS plugin now returns failure signals for ad operations (no exceptions thrown)
  - Setters (privacy, targeting) succeed silently on iOS
  - Customers should implement fallback ad solutions for iOS until production-ready
  - Android support unaffected and fully functional

## [0.16.0] - 2025-11-11

### Fixed
- Fixed critical iOS crash when Dart sends null to native privacy methods
- Fixed NSNull handling across all iOS platform channel parameters
- Implemented GPP (Global Privacy Platform) support on iOS matching Android

### Changed
- Removed deprecated NSUserDefaults.synchronize() calls on iOS (iOS 12+)

## [0.12.0] - 2025-11-11

### Changed
- Test release

## [0.11.0] - 2025-11-11

### Changed
- Test release workflow improvements

## [0.10.0] - 2025-11-10

### Changed
- Internal improvements to release workflow and tooling

## [0.9.0] - 2025-11-10

### Changed
- Internal improvements to release workflow and tooling

## [0.8.0] - 2025-11-10

### Changed
- Internal improvements to release workflow and validation

## [0.7.0] - 2025-11-09

### Changed
- Test release to validate release workflow improvements

## [0.6.0] - 2025-11-10

### Changed
- Test release to validate release workflow improvements

## [0.5.0] - 2025-11-09

### Changed
- Internal improvements to release process and documentation

## [0.4.0] - 2025-11-09

### Changed
- Internal improvements to release process and documentation

## [0.3.0] - 2025-11-06

### Changed
- Updated CloudX iOS SDK dependency from 1.1.40 to 1.1.60
- Updated CloudXMetaAdapter to 1.1.68 (optional dependency)

### Fixed
- Removed local pod overrides from demo app for proper CocoaPods integration
- Improved dependency management by separating core SDK from optional adapters

## [0.2.0] - 2025-11-04

### Changed
- **BREAKING**: Ad network adapters are now optional dependencies
  - Choose which ad networks you want to support by adding adapters to your app
  - Reduces SDK size and gives you full control over dependencies
  - See README for simple adapter installation instructions
- Updated to CloudX Android SDK 0.6.1 with latest improvements

### Fixed
- Improved stability and performance across Android and iOS
- Fixed memory leaks that could occur during ad lifecycle management
- Fixed rare crashes when rapidly creating/destroying ads
- Better thread safety for more reliable ad delivery

### Documentation
- Added clear instructions for installing ad network adapters
- Updated all examples to use latest SDK versions

## [0.1.2] - 2025-10-31

### Fixed
- Fixed version sync script regex pattern to work correctly with macOS BSD sed
- Updated all version references in documentation from 0.1.0 to 0.1.2

## [0.1.1] - 2025-10-31

### Fixed
- Fixed demo app imports after package rename from cloudx_flutter_sdk to cloudx_flutter
- Updated tool scripts to reference correct podspec filename (cloudx_flutter.podspec)
- Fixed iOS programmatic banner/MREC positioning and display issues

## [0.1.0] - 2025-10-30

### Added
- **Initial alpha release** of CloudX Flutter SDK
- **Banner Ads** (320x50) with both widget-based and programmatic positioning
- **MREC Ads** (300x250) with both widget-based and programmatic positioning
- **Interstitial Ads** with full lifecycle management
- **Widget Integration**: `CloudXBannerView` and `CloudXMRECView` widgets for easy integration
- **Programmatic Ads**: Create, load, show, hide, and destroy methods for all ad types
- **Auto-Refresh**: Configurable auto-refresh for banner and MREC ads
- **Privacy Compliance**: Support for CCPA, GPP, and COPPA
  - CCPA privacy string support (fully supported in bid requests)
  - GPP (Global Privacy Platform) support with getter/setter methods
  - COPPA age-restricted user flags
- **User Targeting**: First-party data integration
  - User ID management
  - User-level key-value pairs (cleared by privacy regulations)
  - App-level key-value pairs (persistent across privacy changes)
- **Revenue Tracking**: Access to eCPM and winning bidder information via `CloudXAd` metadata
- **Event Listeners**: Comprehensive callback system for all ad lifecycle events
  - `CloudXAdViewListener` for banner/MREC ads
  - `CloudXInterstitialListener` for interstitial ads
- **Platform Support**:
  - ✅ Android: Production-ready (API 21+)
  - ⚠️ iOS: Alpha/Experimental (iOS 14.0+)
- **Ad Positioning**: 8 position options for programmatic ad placement
- **Widget Controllers**: `CloudXAdViewController` for programmatic control of widget-based ads

### Platform Details
- **Android**: CloudX Android SDK 0.6.1
- **iOS**: CloudXCore pod ~> 1.1.40
- **Flutter**: Requires Flutter 3.0.0+ and Dart 3.0.0+

### Known Limitations
- iOS support is experimental and requires explicit opt-in
- GDPR is not supported
- COPPA flags clear user data but are not yet included in bid requests

### Documentation
- Complete README with integration guide
- Code examples for all ad formats
- Privacy compliance documentation
- Best practices and troubleshooting guide

[0.1.0]: https://github.com/cloudx-io/cloudx-flutter/releases/tag/v0.1.0
