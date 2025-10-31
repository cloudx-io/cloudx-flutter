# Changelog

All notable changes to the CloudX Flutter SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- **Privacy Compliance**: Support for CCPA, GPP, GDPR flags, and COPPA
  - CCPA privacy string support (fully supported in bid requests)
  - GPP (Global Privacy Platform) support with getter/setter methods
  - GDPR consent flags (not yet supported by CloudX servers)
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
  - ⚠️ iOS: Alpha/Experimental (iOS 14.0+, requires `allowIosExperimental: true`)
- **Ad Positioning**: 8 position options for programmatic ad placement
- **Widget Controllers**: `CloudXAdViewController` for programmatic control of widget-based ads

### Platform Details
- **Android**: CloudX Android SDK 0.5.0
- **iOS**: CloudXCore pod ~> 1.1.40
- **Flutter**: Requires Flutter 3.0.0+ and Dart 3.0.0+

### Known Limitations
- iOS support is experimental and requires explicit opt-in
- GDPR consent is not yet supported by CloudX servers
- COPPA flags clear user data but are not yet included in bid requests

### Documentation
- Complete README with integration guide
- Code examples for all ad formats
- Privacy compliance documentation
- Best practices and troubleshooting guide

[0.1.0]: https://github.com/cloudx-io/cloudx-flutter/releases/tag/v0.1.0
