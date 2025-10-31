# CloudX Flutter SDK

[![pub package](https://img.shields.io/pub/v/cloudx_flutter.svg)](https://pub.dev/packages/cloudx_flutter)
[![GitHub](https://img.shields.io/badge/github-cloudx--flutter-blue)](https://github.com/cloudx-io/cloudx-flutter)

A Flutter plugin for the CloudX Mobile Ads platform. Monetize your Flutter apps with banner, MREC, and interstitial ads across iOS and Android.

## Features

- **Banner Ads** (320x50) - Widget-based and programmatic positioning
- **MREC Ads** (300x250) - Medium Rectangle ads with flexible placement
- **Interstitial Ads** - Full-screen ads for natural transition points
- **Privacy Compliance** - Built-in support for CCPA, GPP, GDPR, and COPPA
- **Auto-Refresh** - Automatic ad refresh with server-side configuration
- **Revenue Tracking** - Access to eCPM and winning bidder information
- **User Targeting** - First-party data integration via key-value pairs

## Platform Support

| Platform | Status | Minimum Version |
|----------|--------|-----------------|
| **Android** | ✅ Production Ready | API 21 (Android 5.0) |
| **iOS** | ⚠️ Alpha/Experimental | iOS 14.0 |

**Note:** iOS support requires setting `allowIosExperimental: true` during initialization.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  cloudx_flutter: ^0.1.0
```

Then run:
```bash
flutter pub get
```

**Alternative: Git Dependency**

For the latest development version from GitHub:

```yaml
dependencies:
  cloudx_flutter:
    git:
      url: https://github.com/cloudx-io/cloudx-flutter.git
      ref: v0.1.0  # Use specific version tag
      path: cloudx_flutter_sdk
```

### iOS Setup

The SDK requires iOS 14.0+. Update your `ios/Podfile`:

```ruby
platform :ios, '14.0'
```

Then install pods:
```bash
cd ios && pod install
```

### Android Setup

No additional configuration required. Minimum SDK is automatically set to API 21.

## Quick Start

### 1. Initialize the SDK

Initialize CloudX before creating any ads:

```dart
import 'package:cloudx_flutter/cloudx.dart';

// Optional: Enable verbose logging (development only)
await CloudX.setLoggingEnabled(true);

// Optional: Set environment (default: production)
await CloudX.setEnvironment('production'); // 'dev', 'staging', or 'production'

// Initialize the SDK
final success = await CloudX.initialize(
  appKey: 'YOUR_APP_KEY',
  allowIosExperimental: true, // Required for iOS
);

if (success) {
  print('CloudX SDK initialized successfully');
} else {
  print('Failed to initialize CloudX SDK');
}
```

### 2. Banner Ads

**Option A: Widget-Based (Recommended)**

Embed banner ads directly in your widget tree:

```dart
import 'package:cloudx_flutter/cloudx.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My App')),
      body: Column(
        children: [
          Expanded(child: Text('Your content here')),

          // Banner ad at the bottom
          CloudXBannerView(
            placementName: 'home_banner',
            listener: CloudXAdViewListener(
              onAdLoaded: (ad) => print('Banner loaded: ${ad.bidder}'),
              onAdLoadFailed: (error) => print('Banner failed: $error'),
              onAdDisplayed: (ad) => print('Banner displayed'),
              onAdDisplayFailed: (error) => print('Display failed: $error'),
              onAdClicked: (ad) => print('Banner clicked'),
              onAdHidden: (ad) => print('Banner hidden'),
              onAdExpanded: (ad) => print('Banner expanded'),
              onAdCollapsed: (ad) => print('Banner collapsed'),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Option B: Programmatic Positioning**

Create banners that overlay your content at specific screen positions:

```dart
// Create a banner ad
final adId = await CloudX.createBanner(
  placementName: 'home_banner',
  adId: 'banner_1', // Optional: auto-generated if not provided
  listener: CloudXAdViewListener(
    onAdLoaded: (ad) => print('Loaded: ${ad.revenue}'),
    onAdLoadFailed: (error) => print('Failed: $error'),
    onAdDisplayed: (ad) => print('Displayed'),
    onAdDisplayFailed: (error) => print('Failed to display'),
    onAdClicked: (ad) => print('Clicked'),
    onAdHidden: (ad) => print('Hidden'),
    onAdExpanded: (ad) => print('Expanded'),
    onAdCollapsed: (ad) => print('Collapsed'),
  ),
  position: AdViewPosition.bottomCenter, // Optional: for overlay banners
);

// Load the banner
await CloudX.loadBanner(adId: adId!);

// Show the banner (if using programmatic positioning)
await CloudX.showBanner(adId: adId);

// Hide when needed
await CloudX.hideBanner(adId: adId);

// Always destroy when done
await CloudX.destroyAd(adId: adId);
```

**Auto-Refresh Control:**

```dart
// Start auto-refresh (refresh interval configured server-side)
await CloudX.startAutoRefresh(adId: adId);

// Stop auto-refresh (IMPORTANT: call before destroying)
await CloudX.stopAutoRefresh(adId: adId);
```

### 3. MREC Ads (300x250)

Medium Rectangle ads work just like banners but with a larger size.

**Widget-Based:**

```dart
CloudXMRECView(
  placementName: 'home_mrec',
  listener: CloudXAdViewListener(
    onAdLoaded: (ad) => print('MREC loaded'),
    onAdLoadFailed: (error) => print('MREC failed: $error'),
    onAdDisplayed: (ad) => print('MREC displayed'),
    onAdDisplayFailed: (error) => print('Display failed'),
    onAdClicked: (ad) => print('MREC clicked'),
    onAdHidden: (ad) => print('MREC hidden'),
    onAdExpanded: (ad) => print('MREC expanded'),
    onAdCollapsed: (ad) => print('MREC collapsed'),
  ),
)
```

**Programmatic:**

```dart
final adId = await CloudX.createMREC(
  placementName: 'home_mrec',
  listener: CloudXAdViewListener(...),
  position: AdViewPosition.centered,
);

await CloudX.loadMREC(adId: adId!);
await CloudX.showMREC(adId: adId);

// Check if ready
final isReady = await CloudX.isMRECReady(adId: adId);

// Always destroy when done
await CloudX.destroyAd(adId: adId);
```

### 4. Interstitial Ads

Full-screen ads shown at natural transition points:

```dart
// Create the interstitial
final adId = await CloudX.createInterstitial(
  placementName: 'level_complete',
  listener: CloudXInterstitialListener(
    onAdLoaded: (ad) => print('Interstitial ready'),
    onAdLoadFailed: (error) => print('Load failed: $error'),
    onAdDisplayed: (ad) => print('Interstitial showing'),
    onAdDisplayFailed: (error) => print('Show failed: $error'),
    onAdClicked: (ad) => print('Interstitial clicked'),
    onAdHidden: (ad) => print('Interstitial closed'),
  ),
);

// Load the interstitial
await CloudX.loadInterstitial(adId: adId!);

// Check if ready before showing
final isReady = await CloudX.isInterstitialReady(adId: adId);
if (isReady) {
  await CloudX.showInterstitial(adId: adId);
}

// Always destroy after showing
await CloudX.destroyAd(adId: adId);
```

## Event Listeners

All ad types use listener objects with callback functions.

### CloudXAdViewListener

Used for Banner and MREC ads:

```dart
CloudXAdViewListener(
  onAdLoaded: (CloudXAd ad) {
    // Ad successfully loaded
    print('Bidder: ${ad.bidder}');
    print('Revenue: \$${ad.revenue}');
  },
  onAdLoadFailed: (String error) {
    // Failed to load ad
  },
  onAdDisplayed: (CloudXAd ad) {
    // Ad is now visible to user
  },
  onAdDisplayFailed: (String error) {
    // Failed to display ad
  },
  onAdClicked: (CloudXAd ad) {
    // User clicked the ad
  },
  onAdHidden: (CloudXAd ad) {
    // Ad was hidden
  },
  onAdRevenuePaid: (CloudXAd ad) {
    // Revenue tracking (optional)
  },
  onAdExpanded: (CloudXAd ad) {
    // User expanded the ad
  },
  onAdCollapsed: (CloudXAd ad) {
    // User collapsed the ad
  },
)
```

### CloudXInterstitialListener

Used for Interstitial ads:

```dart
CloudXInterstitialListener(
  onAdLoaded: (CloudXAd ad) {
    // Interstitial ready to show
  },
  onAdLoadFailed: (String error) {
    // Failed to load
  },
  onAdDisplayed: (CloudXAd ad) {
    // Interstitial is showing
  },
  onAdDisplayFailed: (String error) {
    // Failed to show
  },
  onAdClicked: (CloudXAd ad) {
    // User clicked
  },
  onAdHidden: (CloudXAd ad) {
    // User closed interstitial
  },
  onAdRevenuePaid: (CloudXAd ad) {
    // Revenue tracking (optional)
  },
)
```

### CloudXAd Model

All callbacks receive a `CloudXAd` object with ad metadata:

```dart
class CloudXAd {
  final String? placementName;       // Your placement name
  final String? placementId;         // CloudX internal ID
  final String? bidder;              // Winning network (e.g., "meta", "admob")
  final String? externalPlacementId; // Network-specific ID
  final double? revenue;             // eCPM revenue in USD
}
```

## Ad Positioning

When using programmatic positioning, specify where ads should appear:

```dart
enum AdViewPosition {
  topCenter,
  topRight,
  centered,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}
```

Example:
```dart
await CloudX.createBanner(
  placementName: 'banner',
  position: AdViewPosition.bottomCenter,
);
```

## Privacy & Compliance

CloudX provides comprehensive privacy APIs to comply with regulations.

### CCPA (California Consumer Privacy Act)

Fully supported in bid requests:

```dart
// Set CCPA privacy string (format: "1YNN")
// 1 = version, Y/N = opt-out-sale, Y/N = opt-out-sharing, Y/N = LSPA
await CloudX.setCCPAPrivacyString('1YNN');
```

### GDPR (General Data Protection Regulation)

⚠️ **Warning:** Not yet supported by CloudX servers. Contact CloudX for GDPR support.

```dart
await CloudX.setIsUserConsent(true); // true = user consented
```

### COPPA (Children's Online Privacy Protection Act)

Clears user data but not yet included in bid requests (server limitation):

```dart
await CloudX.setIsAgeRestrictedUser(true); // true = age-restricted
```

### GPP (Global Privacy Platform)

Comprehensive privacy framework (fully supported):

```dart
// Set GPP string
await CloudX.setGPPString('DBABMA~CPXxRfAPXxRfAAfKABENB...');

// Set section IDs (e.g., [7, 8] for US-National and US-CA)
await CloudX.setGPPSid([7, 8]);

// Get current values
final gppString = await CloudX.getGPPString();
final gppSid = await CloudX.getGPPSid();
```

## User Targeting

Enhance ad targeting with first-party data.

### User ID

```dart
// Set user ID (should be hashed for privacy)
await CloudX.setUserID('hashed-user-id');
```

### Key-Value Targeting

**User-Level Targeting** (cleared by privacy regulations):

```dart
await CloudX.setUserKeyValue('age', '25');
await CloudX.setUserKeyValue('interests', 'gaming');
```

**App-Level Targeting** (persistent across privacy changes):

```dart
await CloudX.setAppKeyValue('app_version', '1.2.0');
await CloudX.setAppKeyValue('build_type', 'release');
```

**Clear All:**

```dart
await CloudX.clearAllKeyValues();
```

## Lifecycle Management

### Widget Lifecycle

For widget-based ads (`CloudXBannerView`, `CloudXMRECView`), the SDK automatically handles lifecycle.

### Programmatic Lifecycle

For programmatically created ads, **always call `destroyAd()`** to prevent memory leaks:

```dart
class MyAdScreen extends StatefulWidget {
  @override
  _MyAdScreenState createState() => _MyAdScreenState();
}

class _MyAdScreenState extends State<MyAdScreen> {
  String? _adId;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    _adId = await CloudX.createInterstitial(
      placementName: 'my_interstitial',
      listener: CloudXInterstitialListener(...),
    );
    await CloudX.loadInterstitial(adId: _adId!);
  }

  @override
  void dispose() {
    // CRITICAL: Always destroy ads
    if (_adId != null) {
      CloudX.destroyAd(adId: _adId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

## SDK Information

```dart
// Check platform support
final isSupported = await CloudX.isPlatformSupported();

// Get SDK version
final version = await CloudX.getVersion();
```

## Advanced Features

### Widget Controllers

Control banner/MREC widgets programmatically:

```dart
final controller = CloudXAdViewController();

CloudXBannerView(
  placementName: 'home_banner',
  controller: controller,
  listener: CloudXAdViewListener(...),
)

// Control auto-refresh
await controller.startAutoRefresh();
await controller.stopAutoRefresh();

// Check if controller is attached
if (controller.isAttached) {
  // Controller is ready
}
```

## Best Practices

### 1. Always Destroy Ads

Memory leaks occur if you don't destroy ads:

```dart
@override
void dispose() {
  CloudX.destroyAd(adId: myAdId);
  super.dispose();
}
```

### 2. Stop Auto-Refresh Before Destroying

For banner/MREC ads:

```dart
await CloudX.stopAutoRefresh(adId: adId);
await CloudX.destroyAd(adId: adId);
```

### 3. Check Ad Readiness

For interstitials, always check before showing:

```dart
final isReady = await CloudX.isInterstitialReady(adId: adId);
if (isReady) {
  await CloudX.showInterstitial(adId: adId);
}
```

### 4. Disable Logging in Production

```dart
// Only enable during development
if (kDebugMode) {
  await CloudX.setLoggingEnabled(true);
}
```

### 5. Handle Initialization Errors

```dart
final success = await CloudX.initialize(appKey: 'YOUR_KEY');
if (!success) {
  // Handle initialization failure
  // - Check network connection
  // - Verify app key is correct
  // - Check platform support (iOS requires experimental flag)
}
```

## Common Issues

### iOS: "Experimental API" Error

**Solution:** Set `allowIosExperimental: true` during initialization:

```dart
await CloudX.initialize(
  appKey: 'YOUR_KEY',
  allowIosExperimental: true,
);
```

### Banner Not Showing

**Checklist:**
1. Did you call `loadBanner()`?
2. For programmatic banners, did you call `showBanner()`?
3. Is the ad view added to the widget tree?
4. Check the `onAdLoadFailed` callback for errors

### Memory Leaks

**Solution:** Always call `destroyAd()` in your widget's `dispose()` method.

### Auto-Refresh Not Stopping

**Solution:** Explicitly call `stopAutoRefresh()` before destroying:

```dart
await CloudX.stopAutoRefresh(adId: adId);
await CloudX.destroyAd(adId: adId);
```

## Example App

A complete demo app is available in the [GitHub repository](https://github.com/cloudx-io/cloudx-flutter) under `cloudx_flutter_demo_app/`. It demonstrates:

- SDK initialization with environment selection
- All ad format implementations
- Widget-based and programmatic approaches
- Privacy compliance integration
- User targeting setup
- Proper lifecycle management
- Event logging and debugging

Clone the repository and run the demo:

```bash
git clone https://github.com/cloudx-io/cloudx-flutter.git
cd cloudx-flutter/cloudx_flutter_demo_app
flutter pub get
flutter run
```

## Requirements

### Flutter
- Flutter SDK: 3.0.0 or higher
- Dart SDK: 3.0.0 or higher

### iOS
- iOS: 14.0 or higher
- CocoaPods for dependency management
- CloudXCore pod: ~> 1.1.40

### Android
- Android API: 21 (Android 5.0) or higher
- Gradle: 8.0+
- CloudX Android SDK: 0.5.0

## API Reference

### Initialization
- `initialize({required String appKey, bool allowIosExperimental})` → `Future<bool>`
- `isPlatformSupported()` → `Future<bool>`
- `getVersion()` → `Future<String>`
- `setEnvironment(String environment)` → `Future<void>`
- `setLoggingEnabled(bool enabled)` → `Future<void>`

### Banner Ads
- `createBanner({required String placementName, String? adId, CloudXAdViewListener? listener, AdViewPosition? position})` → `Future<String?>`
- `loadBanner({required String adId})` → `Future<bool>`
- `showBanner({required String adId})` → `Future<bool>`
- `hideBanner({required String adId})` → `Future<bool>`
- `startAutoRefresh({required String adId})` → `Future<bool>`
- `stopAutoRefresh({required String adId})` → `Future<bool>`

### MREC Ads
- `createMREC({required String placementName, String? adId, CloudXAdViewListener? listener, AdViewPosition? position})` → `Future<String?>`
- `loadMREC({required String adId})` → `Future<bool>`
- `showMREC({required String adId})` → `Future<bool>`
- `isMRECReady({required String adId})` → `Future<bool>`

### Interstitial Ads
- `createInterstitial({required String placementName, String? adId, CloudXInterstitialListener? listener})` → `Future<String?>`
- `loadInterstitial({required String adId})` → `Future<bool>`
- `showInterstitial({required String adId})` → `Future<bool>`
- `isInterstitialReady({required String adId})` → `Future<bool>`

### Ad Lifecycle
- `destroyAd({required String adId})` → `Future<bool>`

### Privacy
- `setCCPAPrivacyString(String? ccpaString)` → `Future<void>`
- `setIsUserConsent(bool hasConsent)` → `Future<void>`
- `setIsAgeRestrictedUser(bool isAgeRestricted)` → `Future<void>`
- `setGPPString(String? gppString)` → `Future<void>`
- `getGPPString()` → `Future<String?>`
- `setGPPSid(List<int>? sectionIds)` → `Future<void>`
- `getGPPSid()` → `Future<List<int>?>`

### User Targeting
- `setUserID(String? userID)` → `Future<void>`
- `setUserKeyValue(String key, String value)` → `Future<void>`
- `setAppKeyValue(String key, String value)` → `Future<void>`
- `clearAllKeyValues()` → `Future<void>`

## Roadmap (Future Versions)

The following features are planned for future releases:

- ✅ Rewarded Ads (implementation exists, needs public API)
- ✅ Native Ads with multiple sizes (implementation exists, needs public API)
- ✅ Structured error handling with error codes
- ✅ Granular log level control
- ✅ App Open Ads

## Support

For questions, issues, or feature requests:
- Contact the CloudX team
- Check the demo app for implementation examples

## License

This project is licensed under the Business Source License 1.1. See the LICENSE file for details.

---

**Version:** 0.1.0 (Alpha)

**Last Updated:** 2025
