# CloudX Flutter SDK

A Flutter plugin that provides a comprehensive wrapper around the CloudX Core Objective-C SDK, exposing all ad types (banner, interstitial, rewarded, native, MREC) and SDK initialization.

## Features

- **Full SDK Integration**: Complete wrapper for CloudX Core Objective-C SDK
- **All Ad Types**: Banner, Interstitial, Rewarded, Native, and MREC ads
- **Listener Pattern**: Callback-based events for ad lifecycle management
- **Error Handling**: Comprehensive error handling and user feedback
- **Type Safety**: Strongly typed Dart interfaces
- **Platform Support**: iOS support with Objective-C backend

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
    ..onAdLoaded = () => print('Banner loaded')
    ..onAdFailedToLoad = (error) => print('Banner failed: $error')
    ..onAdShown = () => print('Banner shown')
    ..onAdClicked = () => print('Banner clicked'),
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
    ..onAdLoaded = () => print('Interstitial loaded')
    ..onAdFailedToLoad = (error) => print('Interstitial failed: $error')
    ..onAdShown = () => print('Interstitial shown')
    ..onAdHidden = () => print('Interstitial hidden'),
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
    ..onAdLoaded = () => print('Rewarded loaded')
    ..onAdFailedToLoad = (error) => print('Rewarded failed: $error')
    ..onAdShown = () => print('Rewarded shown')
    ..onAdHidden = () => print('Rewarded hidden')
    ..onRewarded = (rewardType, rewardAmount) => 
        print('User earned $rewardAmount $rewardType'),
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
    ..onAdLoaded = () => print('Native loaded')
    ..onAdFailedToLoad = (error) => print('Native failed: $error')
    ..onAdShown = () => print('Native shown')
    ..onAdClicked = () => print('Native clicked'),
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
    ..onAdLoaded = () => print('MREC loaded')
    ..onAdFailedToLoad = (error) => print('MREC failed: $error')
    ..onAdShown = () => print('MREC shown')
    ..onAdClicked = () => print('MREC clicked'),
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
  void Function()? onAdLoaded;
  void Function(String error)? onAdFailedToLoad;
  void Function()? onAdShown;
  void Function(String error)? onAdFailedToShow;
  void Function()? onAdHidden;
  void Function()? onAdClicked;
}
```

### InterstitialListener
```dart
abstract class InterstitialListener {
  void Function()? onAdLoaded;
  void Function(String error)? onAdFailedToLoad;
  void Function()? onAdShown;
  void Function(String error)? onAdFailedToShow;
  void Function()? onAdHidden;
  void Function()? onAdClicked;
}
```

### RewardedListener
```dart
abstract class RewardedListener {
  void Function()? onAdLoaded;
  void Function(String error)? onAdFailedToLoad;
  void Function()? onAdShown;
  void Function(String error)? onAdFailedToShow;
  void Function()? onAdHidden;
  void Function()? onAdClicked;
  void Function(String rewardType, int rewardAmount)? onRewarded;
}
```

### NativeListener
```dart
abstract class NativeListener {
  void Function()? onAdLoaded;
  void Function(String error)? onAdFailedToLoad;
  void Function()? onAdShown;
  void Function(String error)? onAdFailedToShow;
  void Function()? onAdHidden;
  void Function()? onAdClicked;
}
```

### MRECListener
```dart
abstract class MRECListener {
  void Function()? onAdLoaded;
  void Function(String error)? onAdFailedToLoad;
  void Function()? onAdShown;
  void Function(String error)? onAdFailedToShow;
  void Function()? onAdHidden;
  void Function()? onAdClicked;
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
      ..onAdFailedToLoad = (error) {
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

## Platform Support

- **iOS**: Full support via Objective-C backend
- **Android**: Not yet supported

## Requirements

- iOS 14.0+
- Flutter 3.0+
- Dart 2.17+

## License

This project is licensed under the Business Source License 1.1 - see the LICENSE file for details.

## Support

For support and questions, please contact the CloudX team. 