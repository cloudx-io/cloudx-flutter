# CloudX Flutter SDK

A Flutter plugin that provides a comprehensive wrapper around the CloudX native SDKs (iOS and Android), exposing all ad types (banner, interstitial, rewarded, native, MREC) with full privacy compliance support.

## Features

- **Full SDK Integration**: Complete wrapper for CloudX Core (iOS) and CloudX Android SDK
- **Cross-Platform**: Single Dart API works on both iOS and Android
- **All Ad Types**: Banner, Interstitial, Rewarded, Native, and MREC ads
- **Privacy Compliance**: Built-in CCPA, GDPR, COPPA, and GPP support
- **Listener Pattern**: Callback-based events for ad lifecycle management
- **Error Handling**: Comprehensive error handling and user feedback
- **Type Safety**: Strongly typed Dart interfaces
- **DRY & SOLID**: Architecture following best practices for maintainability
- **Platform Support**: iOS (Objective-C) and Android (Kotlin) backends

## Installation

Add the CloudX Flutter SDK to your `pubspec.yaml`:

```yaml
dependencies:
  cloudx_flutter_sdk:
    path: ../cloudx_flutter_sdk
```

## Quick Start

### 1. Initialize the SDK

```dart
import 'package:cloudx_flutter_sdk/cloudx.dart';

// Initialize the SDK with your app key
final success = await CloudX.initialize(
  appKey: 'YOUR_APP_KEY',
  hashedUserID: 'OPTIONAL_HASHED_USER_ID', // Optional
);

if (success) {
  print('CloudX SDK initialized successfully');
} else {
  print('Failed to initialize CloudX SDK');
}
```

### 2. Create and Load Ads

#### Banner Ads

```dart
// Create a banner ad
final success = await CloudX.createBanner(
  placement: 'banner1',
  adId: 'unique_banner_id',
  listener: BannerListener()
    ..onAdLoaded = (ad) => print('Banner loaded: ${ad?.placementName}')
    ..onAdFailedToLoad = (error, ad) => print('Banner failed: $error')
    ..onAdShown = (ad) => print('Banner shown')
    ..onAdClicked = (ad) => print('Banner clicked'),
);

if (success) {
  // Load the banner
  await CloudX.loadBanner(adId: 'unique_banner_id');
}
```

#### Interstitial Ads

```dart
// Create an interstitial ad
final success = await CloudX.createInterstitial(
  placement: 'interstitial1',
  adId: 'unique_interstitial_id',
  listener: InterstitialListener()
    ..onAdLoaded = (ad) => print('Interstitial loaded')
    ..onAdFailedToLoad = (error, ad) => print('Interstitial failed: $error')
    ..onAdShown = (ad) => print('Interstitial shown')
    ..onAdHidden = (ad) => print('Interstitial hidden'),
);

if (success) {
  // Load the interstitial
  await CloudX.loadInterstitial(adId: 'unique_interstitial_id');
  
  // Show when ready
  await CloudX.showInterstitial(adId: 'unique_interstitial_id');
}
```

#### Rewarded Ads

```dart
// Create a rewarded ad
final success = await CloudX.createRewarded(
  placement: 'rewarded1',
  adId: 'unique_rewarded_id',
  listener: RewardedListener()
    ..onAdLoaded = (ad) => print('Rewarded loaded')
    ..onAdFailedToLoad = (error, ad) => print('Rewarded failed: $error')
    ..onAdShown = (ad) => print('Rewarded shown')
    ..onAdHidden = (ad) => print('Rewarded hidden')
    ..onRewarded = (ad) => print('User earned reward!'),
);

if (success) {
  // Load the rewarded ad
  await CloudX.loadRewarded(adId: 'unique_rewarded_id');
  
  // Show when ready
  await CloudX.showRewarded(adId: 'unique_rewarded_id');
}
```

#### Native Ads

```dart
// Create a native ad
final success = await CloudX.createNative(
  placement: 'native1',
  adId: 'unique_native_id',
  listener: NativeListener()
    ..onAdLoaded = (ad) => print('Native loaded')
    ..onAdFailedToLoad = (error, ad) => print('Native failed: $error')
    ..onAdShown = (ad) => print('Native shown')
    ..onAdClicked = (ad) => print('Native clicked'),
);

if (success) {
  // Load the native ad
  await CloudX.loadNative(adId: 'unique_native_id');
  
  // Show when ready
  await CloudX.showNative(adId: 'unique_native_id');
}
```

#### MREC Ads

```dart
// Create an MREC ad
final success = await CloudX.createMREC(
  placement: 'mrec1',
  adId: 'unique_mrec_id',
  listener: MRECListener()
    ..onAdLoaded = (ad) => print('MREC loaded')
    ..onAdFailedToLoad = (error, ad) => print('MREC failed: $error')
    ..onAdShown = (ad) => print('MREC shown')
    ..onAdClicked = (ad) => print('MREC clicked'),
);

if (success) {
  // Load the MREC ad
  await CloudX.loadMREC(adId: 'unique_mrec_id');
  
  // Show when ready
  await CloudX.showMREC(adId: 'unique_mrec_id');
}
```

### 3. Ad Management

```dart
// Check if an ad is ready
final isReady = await CloudX.isInterstitialReady(adId: 'unique_interstitial_id');

// Hide an ad (for banner/MREC)
await CloudX.hideBanner(adId: 'unique_banner_id');

// Destroy an ad instance
await CloudX.destroyAd(adId: 'unique_ad_id');

// Get SDK version
final version = await CloudX.getVersion();
```

## Listener Interfaces

### BannerListener
```dart
abstract class BannerListener {
  void Function(CloudXAd? ad)? onAdLoaded;
  void Function(String error, CloudXAd? ad)? onAdFailedToLoad;
  void Function(CloudXAd? ad)? onAdShown;
  void Function(String error, CloudXAd? ad)? onAdFailedToShow;
  void Function(CloudXAd? ad)? onAdHidden;
  void Function(CloudXAd? ad)? onAdClicked;
  void Function(CloudXAd? ad)? onAdImpression;
  void Function(CloudXAd? ad)? onAdClosedByUser;
  void Function(CloudXAd? ad)? onRevenuePaid;
  void Function(CloudXAd? ad)? onAdExpanded;
  void Function(CloudXAd? ad)? onAdCollapsed;
}
```

### InterstitialListener
```dart
abstract class InterstitialListener {
  void Function(CloudXAd? ad)? onAdLoaded;
  void Function(String error, CloudXAd? ad)? onAdFailedToLoad;
  void Function(CloudXAd? ad)? onAdShown;
  void Function(String error, CloudXAd? ad)? onAdFailedToShow;
  void Function(CloudXAd? ad)? onAdHidden;
  void Function(CloudXAd? ad)? onAdClicked;
  void Function(CloudXAd? ad)? onAdImpression;
  void Function(CloudXAd? ad)? onAdClosedByUser;
  void Function(CloudXAd? ad)? onRevenuePaid;
}
```

### RewardedListener
```dart
abstract class RewardedListener {
  void Function(CloudXAd? ad)? onAdLoaded;
  void Function(String error, CloudXAd? ad)? onAdFailedToLoad;
  void Function(CloudXAd? ad)? onAdShown;
  void Function(String error, CloudXAd? ad)? onAdFailedToShow;
  void Function(CloudXAd? ad)? onAdHidden;
  void Function(CloudXAd? ad)? onAdClicked;
  void Function(CloudXAd? ad)? onAdImpression;
  void Function(CloudXAd? ad)? onAdClosedByUser;
  void Function(CloudXAd? ad)? onRevenuePaid;
  void Function(CloudXAd? ad)? onRewarded;
  void Function(CloudXAd? ad)? onRewardedVideoStarted;
  void Function(CloudXAd? ad)? onRewardedVideoCompleted;
}
```

### NativeListener
```dart
abstract class NativeListener {
  void Function(CloudXAd? ad)? onAdLoaded;
  void Function(String error, CloudXAd? ad)? onAdFailedToLoad;
  void Function(CloudXAd? ad)? onAdShown;
  void Function(String error, CloudXAd? ad)? onAdFailedToShow;
  void Function(CloudXAd? ad)? onAdHidden;
  void Function(CloudXAd? ad)? onAdClicked;
  void Function(CloudXAd? ad)? onAdImpression;
  void Function(CloudXAd? ad)? onAdClosedByUser;
  void Function(CloudXAd? ad)? onRevenuePaid;
}
```

### MRECListener
```dart
abstract class MRECListener {
  void Function(CloudXAd? ad)? onAdLoaded;
  void Function(String error, CloudXAd? ad)? onAdFailedToLoad;
  void Function(CloudXAd? ad)? onAdShown;
  void Function(String error, CloudXAd? ad)? onAdFailedToShow;
  void Function(CloudXAd? ad)? onAdHidden;
  void Function(CloudXAd? ad)? onAdClicked;
  void Function(CloudXAd? ad)? onAdImpression;
  void Function(CloudXAd? ad)? onAdClosedByUser;
  void Function(CloudXAd? ad)? onRevenuePaid;
}
```

## Error Handling

The SDK provides comprehensive error handling through:

1. **Return Values**: All methods return `bool` or `Future<bool>` to indicate success/failure
2. **Listener Callbacks**: Error details are passed to listener callbacks
3. **Exception Handling**: Platform exceptions are caught and handled gracefully

```dart
try {
  final success = await CloudX.createBanner(
    placement: 'banner1',
    adId: 'banner_id',
    listener: BannerListener()
      ..onAdFailedToLoad = (error, ad) {
        print('Banner failed to load: $error');
        // Handle the error appropriately
      },
  );
  
  if (!success) {
    print('Failed to create banner ad');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## Privacy & Compliance

The SDK provides comprehensive privacy compliance features:

```dart
// CCPA Privacy String
await CloudX.setCCPAPrivacyString('1YNN');

// GDPR Consent
await CloudX.setIsUserConsent(true);

// COPPA (Age-Restricted Users)
await CloudX.setIsAgeRestrictedUser(false);

// Do Not Sell (CCPA)
await CloudX.setIsDoNotSell(false);

// Global Privacy Platform (GPP)
await CloudX.setGPPString('DBACNYA~CPXxRfAPXxRfAAfKABENB...');
await CloudX.setGPPSid([7, 8]); // US-National (7), US-CA (8)
```

## User Targeting

```dart
// Set hashed user ID
await CloudX.provideUserDetailsWithHashedUserID('hashed-email-here');

// Set single key-value pair (generic)
await CloudX.useHashedKeyValue('age', '25');

// Set multiple key-values (more efficient)
await CloudX.useKeyValues({
  'gender': 'male',
  'location': 'US',
  'interests': 'gaming',
});

// Set user-level targeting (cleared when privacy regulations require removing personal data)
await CloudX.setUserKeyValue('age', '25');
await CloudX.setUserKeyValue('interests', 'gaming');

// Set app-level targeting (NOT affected by privacy regulations)
await CloudX.setAppKeyValue('app_version', '1.2.0');
await CloudX.setAppKeyValue('build_type', 'release');

// Clear all user and app-level key-value pairs
await CloudX.clearAllKeyValues();
```

## Platform Support

- **iOS**: Full support via Objective-C backend (iOS 14.0+)
- **Android**: Full support via Kotlin backend (API 21+)

## Requirements

### iOS
- iOS 14.0 or higher
- CocoaPods

### Android
- Android API 21 (Android 5.0) or higher
- Gradle 8.0+

### Flutter
- Flutter 3.0+
- Dart 3.0+

## Documentation

- **[Integration Guide](INTEGRATION_GUIDE.md)**: Step-by-step guide for iOS and Android integration
- **[Architecture Review](ARCHITECTURE_REVIEW.md)**: Deep dive into SDK architecture and design principles

## License

This project is licensed under the Business Source License 1.1 - see the LICENSE file for details.

## Support

For support and questions, please contact the CloudX team. 