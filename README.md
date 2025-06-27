# CloudX Flutter SDK

A complete Flutter SDK wrapper for the CloudX Core Objective-C SDK, including a comprehensive demo app that mirrors the functionality of the native iOS app.

## Project Structure

```
CloudXFlutterSDK/
├── cloudx_flutter_sdk/          # Flutter SDK wrapper
│   ├── lib/
│   │   └── cloudx.dart
│   ├── ios/
│   │   ├── Classes/
│   │   │   ├── CloudXFlutterSdkPlugin.h
│   │   │   └── CloudXFlutterSdkPlugin.m
│   │   └── CloudXFlutter.podspec
│   ├── pubspec.yaml
│   └── README.md
└── cloudx_flutter_host_app/     # Demo Flutter app
    ├── lib/
    │   ├── main.dart
    │   └── screens/
    │       ├── base_ad_screen.dart
    │       ├── init_screen.dart
    │       ├── banner_screen.dart
    │       ├── interstitial_screen.dart
    │       ├── rewarded_screen.dart
    │       ├── mrec_screen.dart
    │       └── native_screen.dart
    ├── ios/
    │   ├── Podfile
    │   └── Runner/
    │       ├── AppDelegate.swift
    │       └── Info.plist
    ├── pubspec.yaml
    └── README.md
```

## Components

### 1. Flutter SDK Wrapper (`cloudx_flutter_sdk/`)

A Flutter plugin that provides a complete wrapper around the CloudX Core Objective-C SDK.

**Features:**
- Full SDK initialization support
- All ad types: Banner, Interstitial, Rewarded, Native, MREC
- Comprehensive event handling
- Error handling and exception management
- Platform-specific iOS implementation

**Key Files:**
- `lib/cloudx.dart`: Main Dart interface
- `ios/Classes/CloudXFlutterSdkPlugin.m`: iOS plugin implementation
- `ios/CloudXFlutter.podspec`: CocoaPods specification

### 2. Demo Flutter App (`cloudx_flutter_host_app/`)

A complete Flutter demo application that demonstrates all SDK features.

**Features:**
- Tab-based navigation for different ad types
- SDK initialization screen
- Real-time status indicators
- Error handling and user feedback
- Mirrors the functionality of CloudXObjCRemotePods

**Key Files:**
- `lib/main.dart`: Main app entry point
- `lib/screens/base_ad_screen.dart`: Base class for ad screens
- Individual ad screen implementations
- iOS configuration files

## Quick Start

### Prerequisites
- Flutter SDK (3.0.0 or later)
- iOS 14.0 or later
- Xcode 12.0 or later
- CocoaPods

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd CloudXFlutterSDK
   ```

2. **Set up the Flutter SDK**:
   ```bash
   cd cloudx_flutter_sdk
   flutter pub get
   ```

3. **Set up the demo app**:
   ```bash
   cd ../cloudx_flutter_host_app
   flutter pub get
   cd ios
   pod install
   cd ..
   ```

4. **Run the demo app**:
   ```bash
   flutter run
   ```

## Usage

### Using the Flutter SDK in Your App

1. **Add the dependency**:
   ```yaml
   dependencies:
     cloudx_flutter_sdk:
       path: ../cloudx_flutter_sdk
   ```

2. **Initialize the SDK**:
   ```dart
   import 'package:cloudx_flutter_sdk/cloudx.dart';
   
   final success = await CloudX.initialize(
     appKey: 'your-app-key',
     hashedUserID: 'user-id',
   );
   ```

3. **Create and show ads**:
   ```dart
   // Create banner ad
   await CloudX.createBanner(
     placement: 'banner-placement',
     adId: 'banner-1',
   );
   
   // Load and show
   await CloudX.loadBanner(adId: 'banner-1');
   await CloudX.showBanner(adId: 'banner-1');
   ```

4. **Handle events**:
   ```dart
   final listener = BannerListener()
     ..onAdLoaded = () => print('Ad loaded')
     ..onAdFailedToLoad = (error) => print('Ad failed: $error');
   
   await CloudX.createBanner(
     placement: 'banner-placement',
     adId: 'banner-1',
     listener: listener,
   );
   ```

## API Reference

### CloudX Class

#### Initialization
- `initialize({required String appKey, String? hashedUserID})`
- `isInitialized()`
- `getVersion()`

#### Ad Creation
- `createBanner({required String placement, required String adId, BannerListener? listener})`
- `createInterstitial({required String placement, required String adId, InterstitialListener? listener})`
- `createRewarded({required String placement, required String adId, RewardedListener? listener})`
- `createNative({required String placement, required String adId, NativeListener? listener})`
- `createMREC({required String placement, required String adId, MRECListener? listener})`

#### Ad Operations
- `loadBanner({required String adId})`
- `showBanner({required String adId})`
- `hideBanner({required String adId})`
- `loadInterstitial({required String adId})`
- `showInterstitial({required String adId})`
- `isInterstitialReady({required String adId})`
- `loadRewarded({required String adId})`
- `showRewarded({required String adId})`
- `isRewardedReady({required String adId})`
- `loadNative({required String adId})`
- `showNative({required String adId})`
- `isNativeReady({required String adId})`
- `loadMREC({required String adId})`
- `showMREC({required String adId})`
- `isMRECReady({required String adId})`
- `destroyAd({required String adId})`

#### Listener Classes
- `BannerListener` - Callbacks for banner ad events
- `InterstitialListener` - Callbacks for interstitial ad events
- `RewardedListener` - Callbacks for rewarded ad events
- `NativeListener` - Callbacks for native ad events
- `MRECListener` - Callbacks for MREC ad events

## Demo App Features

The demo app provides a comprehensive testing environment:

1. **Init Tab**: SDK initialization with status feedback
2. **Banner Tab**: Banner ad testing (320x50)
3. **Interstitial Tab**: Full-screen interstitial testing
4. **Rewarded Tab**: Rewarded ad testing
5. **MREC Tab**: Medium rectangle ad testing (300x250)
6. **Native Tab**: Native ad testing

Each tab includes:
- Load/Show button with dynamic text
- Status indicator with color coding
- Error handling with user-friendly dialogs
- Auto-reload functionality after ad dismissal

## Development

### Building the SDK
```bash
cd cloudx_flutter_sdk
flutter build ios
```

### Testing the Demo App
```bash
cd cloudx_flutter_host_app
flutter test
```

### Adding New Features
1. Update the iOS plugin implementation
2. Add corresponding Dart methods
3. Update the demo app to showcase new features
4. Update documentation

## Dependencies

### Flutter SDK
- Flutter 3.0.0+
- Dart 3.0.0+

### iOS Dependencies
- CloudXCore (Objective-C SDK)
- CloudXTestVastNetworkAdapter
- iOS 14.0+

## License

This project is licensed under the same license as the CloudX Core SDK.

## Support

For issues and questions:
1. Check the demo app for usage examples
2. Review the API documentation
3. Check the CloudX Core SDK documentation
4. Contact CloudX support 