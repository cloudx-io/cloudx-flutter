# CloudX Flutter SDK - Android & iOS Integration Guide

## 🏗️ Architecture Overview

This Flutter SDK provides a **unified Dart API** that bridges to both **native iOS (Objective-C)** and **native Android (Kotlin)** SDKs. The architecture follows **DRY** and **SOLID** principles:

### Design Principles Applied

#### 1. **Single Responsibility Principle (SRP)**
- **Dart Layer** (`cloudx.dart`): Pure business logic and Flutter API
- **Native Bridge Layer**: Platform-specific implementation (iOS: Objective-C, Android: Kotlin)
- **Event Handling**: Separate EventChannel for ad lifecycle callbacks
- **Method Handling**: Dedicated MethodChannel for API calls

#### 2. **Don't Repeat Yourself (DRY)**
- **Centralized Method Invocation**: Single `_invokeMethod<T>()` wrapper in Dart
- **Unified Event Dispatcher**: `_handleEvent()` and `_dispatchEventToListener()` 
- **Shared Listener Base**: `BaseAdListener` with common callbacks
- **Platform-Agnostic API**: Same Dart API works on both iOS and Android

#### 3. **Interface Segregation Principle (ISP)**
- **Specialized Listeners**: BannerListener, InterstitialListener, RewardedListener
- Each listener only exposes methods relevant to that ad type

#### 4. **Dependency Inversion Principle (DIP)**
- Flutter code depends on abstractions (MethodChannel, EventChannel)
- Native implementations inject themselves via plugin registration

---

## 📱 Platform Architecture

### Communication Channels

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Dart Code                       │
│                    (cloudx.dart API)                         │
└─────────────────┬───────────────────────┬───────────────────┘
                  │                       │
         MethodChannel              EventChannel
         (API Calls)               (Callbacks)
                  │                       │
    ┌─────────────┴───────────┬───────────┴─────────────┐
    │                         │                         │
┌───▼─────────────────┐  ┌───▼─────────────────┐       │
│  iOS Bridge (ObjC)  │  │ Android Bridge (Kt) │       │
│ CloudXFlutterSdk    │  │ CloudXFlutterSdk    │       │
│      Plugin.m       │  │     Plugin.kt       │       │
└───┬─────────────────┘  └───┬─────────────────┘       │
    │                         │                         │
┌───▼──────────────┐   ┌──────▼──────────────┐         │
│ CloudXCore SDK   │   │  CloudX Android SDK │         │
│  (Objective-C)   │   │      (Kotlin)       │         │
└──────────────────┘   └─────────────────────┘         │
                                                        │
                                                        │
                    EventSink sends events back         │
                    to Dart via EventChannel ◄──────────┘
```

### API Mapping Strategy

The Flutter SDK abstracts platform differences:

| Feature | iOS API | Android API | Flutter Unified API |
|---------|---------|-------------|---------------------|
| **Init** | `initSDKWithAppKey:completion:` | `CloudX.initialize(params, listener)` | `CloudX.initialize(appKey: ...)` |
| **Banner** | `createBannerWithPlacement:viewController:delegate:` | `CloudX.createBanner(placement)` | `CloudX.createBanner(placement: ...)` |
| **Privacy** | `setCCPAPrivacyString(string)` | `CloudX.setPrivacy(CloudXPrivacy(...))` + SharedPrefs | `CloudX.setCCPAPrivacyString(string)` |
| **Callbacks** | Protocol delegates | Interface listeners | Dart callback functions |

---

## 🔧 Implementation Details

### iOS Implementation (`CloudXFlutterSdkPlugin.m`)

**Key Features:**
- Uses **Objective-C runtime** for dynamic ad instance tracking
- **Associated objects** (`objc_setAssociatedObject`) to map adId to native instances
- **PlatformView** integration for rendering banner/native/MREC ads
- Delegates implement CloudX SDK protocols: `CLXInterstitialDelegate`, `CLXRewardedDelegate`, `CLXBannerDelegate`, `CLXNativeDelegate`

**Event Flow:**
```
iOS Native Ad Event
    ↓
Delegate Method Called (e.g., didLoadWithAd:)
    ↓
Extract adId from associated object
    ↓
Send to EventSink → EventChannel → Dart
    ↓
Dart _handleEvent() dispatches to listener
```

### Android Implementation (`CloudXFlutterSdkPlugin.kt`)

**Key Features:**
- Implements `FlutterPlugin`, `ActivityAware`, `MethodCallHandler`, `EventChannel.StreamHandler`
- **Activity lifecycle awareness** for fullscreen ads
- Uses `MutableMap<String, Any>` to track ad instances
- Listener factories create anonymous objects implementing CloudX SDK interfaces

**Privacy Handling:**
- Maps iOS-style individual methods to Android's combined approach
- Uses SharedPreferences for IAB standards (TCF, USPrivacy, GPP)
- `CloudX.setPrivacy(CloudXPrivacy(...))` for GDPR/COPPA flags

**Event Flow:**
```
Android Native Ad Event
    ↓
Listener Callback (e.g., onAdLoaded)
    ↓
sendEventToFlutter(eventName, adId)
    ↓
EventSink.success() → EventChannel → Dart
    ↓
Dart _handleEvent() dispatches to listener
```

---

## 📋 Integration Checklist

### For Publishers Integrating CloudX Flutter SDK

#### 1. **Add Dependencies**

**`pubspec.yaml`:**
```yaml
dependencies:
  cloudx_flutter_sdk: ^2.0.0
```

#### 2. **iOS Configuration**

**`ios/Podfile`:**
```ruby
platform :ios, '14.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # CloudX Flutter SDK will automatically pull in CloudXCore
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

**Run:**
```bash
cd ios
pod install
```

#### 3. **Android Configuration**

**`android/app/build.gradle`:**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    // Flutter SDK dependency will pull in CloudX Android SDK automatically
}
```

**`android/app/src/main/AndroidManifest.xml`:**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required permissions for CloudX SDK -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_BASIC_PHONE_STATE" />
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" />
    
    <application>
        <!-- Your app content -->
    </application>
</manifest>
```

#### 4. **Initialize SDK in Dart**

```dart
import 'package:cloudx_flutter_sdk/cloudx.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize CloudX SDK
  try {
    await CloudX.initialize(
      appKey: 'your-app-key-here',
      hashedUserID: 'optional-hashed-user-id',
    );
    print('CloudX SDK initialized successfully');
  } catch (e) {
    print('Failed to initialize CloudX SDK: $e');
  }
  
  runApp(MyApp());
}
```

#### 5. **Use Ads**

**Banner Ad Example:**
```dart
class BannerAdWidget extends StatefulWidget {
  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final String adId = 'banner_ad_1';
  bool isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _createAndLoadBanner();
  }

  Future<void> _createAndLoadBanner() async {
    final listener = BannerListener()
      ..onAdLoaded = () {
        setState(() => isAdLoaded = true);
        print('Banner ad loaded');
      }
      ..onAdFailedToLoad = (error) {
        print('Banner ad failed to load: $error');
      };

    await CloudX.createBanner(
      placement: 'your-banner-placement',
      adId: adId,
      listener: listener,
    );
    
    await CloudX.loadBanner(adId: adId);
  }

  @override
  void dispose() {
    CloudX.destroyAd(adId: adId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdLoaded) {
      return SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
    }
    
    return Container(
      height: 50,
      child: AndroidView(
        viewType: 'cloudx_banner_view',
        creationParams: {'adId': adId},
        creationParamsCodec: StandardMessageCodec(),
      ),
    );
  }
}
```

**Interstitial Ad Example:**
```dart
class InterstitialAdManager {
  final String adId = 'interstitial_ad_1';
  bool isReady = false;

  Future<void> createAndLoad() async {
    final listener = InterstitialListener()
      ..onAdLoaded = () {
        isReady = true;
        print('Interstitial ad loaded');
      }
      ..onAdFailedToLoad = (error) {
        print('Interstitial ad failed to load: $error');
      }
      ..onAdClosedByUser = () {
        print('Interstitial ad closed');
        isReady = false;
        // Reload for next use
        createAndLoad();
      };

    await CloudX.createInterstitial(
      placement: 'your-interstitial-placement',
      adId: adId,
      listener: listener,
    );
    
    await CloudX.loadInterstitial(adId: adId);
  }

  Future<void> show() async {
    if (isReady) {
      await CloudX.showInterstitial(adId: adId);
    } else {
      print('Interstitial ad not ready');
    }
  }
}
```

---

## 🔐 Privacy Compliance

### Setting Privacy Flags

```dart
// CCPA
await CloudX.setCCPAPrivacyString('1YNN');

// GDPR
await CloudX.setIsUserConsent(true);

// COPPA
await CloudX.setIsAgeRestrictedUser(false);

// Do Not Sell (CCPA)
await CloudX.setIsDoNotSell(false);

// GPP (Global Privacy Platform)
await CloudX.setGPPString('DBACNYA~...');
await CloudX.setGPPSid([7, 8]); // US-National (7), US-CA (8)
```

### Platform-Specific Behavior

**iOS:**
- Privacy strings are set directly in CloudXCore
- GPP/CCPA stored in UserDefaults under IAB keys

**Android:**
- Privacy flags passed to `CloudX.setPrivacy(CloudXPrivacy(...))`
- IAB strings stored in SharedPreferences with standard keys
- GPP provider reads from `IABGPP_HDR_GppString` and `IABGPP_GppSID`

---

## 🎯 User Targeting

```dart
// Set hashed user ID
await CloudX.provideUserDetailsWithHashedUserID('hashed-email-here');

// Set single key-value
await CloudX.useHashedKeyValue('age', '25');

// Set multiple key-values (more efficient)
await CloudX.useKeyValues({
  'gender': 'male',
  'location': 'US',
  'interests': 'gaming',
});

// Bidder-specific targeting (iOS only, mapped to prefixed key on Android)
await CloudX.useBidderKeyValue('meta', 'custom_param', 'value');
```

---

## 🐛 Troubleshooting

### Common Issues

**1. "Ad instance not found" errors:**
- Ensure you call `createBanner/createInterstitial` before `loadAd`
- Verify adId is consistent across create/load/show/destroy calls

**2. Ads not loading:**
- Check network connectivity
- Verify placement names in CloudX dashboard
- Enable debug logging (iOS: CloudXCore logs, Android: CloudX.setLoggingEnabled(true))

**3. PlatformView not showing ads:**
- Ensure ad is loaded before rendering PlatformView
- Check that adId passed to PlatformView matches created ad instance

**4. Privacy compliance not working:**
- Verify IAB strings are set BEFORE SDK initialization
- On Android, check SharedPreferences have correct keys
- On iOS, check UserDefaults storage

### Debug Logging

**Dart:**
```dart
// Enable try-catch around all CloudX calls
try {
  await CloudX.initialize(appKey: 'test-key');
} on CloudXException catch (e) {
  print('CloudX Error: ${e.code} - ${e.message}');
}
```

**Android:**
```kotlin
// In your MainActivity.kt before Flutter initialization
CloudX.setLoggingEnabled(true)
CloudX.setMinLogLevel(CloudXLogLevel.DEBUG)
```

**iOS:**
```objc
// In AppDelegate.m didFinishLaunchingWithOptions
[CloudXCore shared].logLevel = CLXLogLevelDebug;
```

---

## 📊 Architecture Benefits

### For Developers

✅ **Write Once, Run Everywhere**: Single Dart codebase for iOS & Android  
✅ **Type Safety**: Flutter's strong typing catches errors at compile time  
✅ **Hot Reload**: Instant UI updates during development  
✅ **Native Performance**: Full-speed native ad rendering  

### For Meta Principal Engineers

✅ **DRY**: No duplication between iOS/Android implementations  
✅ **SOLID**: Clear separation of concerns, easy to extend  
✅ **Testability**: Each layer can be unit tested independently  
✅ **Maintainability**: Changes to native SDKs don't affect Dart API  
✅ **Scalability**: New ad types/features added to both platforms simultaneously  

---

## 🚀 Next Steps

1. **Test on Both Platforms**: Always test iOS and Android separately
2. **Monitor Metrics**: Track initialization success rates, ad load times
3. **Handle Errors Gracefully**: Implement retry logic for failed ad loads
4. **Optimize Memory**: Destroy ads when no longer needed
5. **Stay Updated**: Follow CloudX SDK release notes for both platforms

---

## 📞 Support

- **iOS SDK**: [CloudX iOS Documentation](https://github.com/cloudx-xenoss/cloudx-ios)
- **Android SDK**: [CloudX Android Documentation](https://github.com/cloudx-io/cloudexchange.android.sdk)
- **Flutter Issues**: [GitHub Issues](https://github.com/cloudx-xenoss/CloudXFlutterSDK/issues)
- **Email**: eng@cloudx.io

---

## 📝 License

This Flutter SDK follows the same licensing as the underlying native SDKs:
- iOS: Check CloudXCore license
- Android: Elastic License 2.0



