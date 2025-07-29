# CloudX Flutter SDK

A complete Flutter SDK wrapper for the CloudX Core Objective-C SDK, providing easy integration for banner, interstitial, rewarded, native, and MREC ads.

## Quick Integration Guide

### 1. Add Dependency

Add the CloudX Flutter SDK to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cloudx_flutter_sdk: ^1.0.1
```

### 2. iOS Configuration

Update your `ios/Podfile` to include the minimum iOS version:

```ruby
platform :ios, '14.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

### 3. Install Dependencies

```bash
flutter pub get
cd ios && pod install && cd ..
```

### 4. Enable Flutter Debug Logging (Optional)

To enable detailed SDK logging for debugging purposes in Flutter apps, you can use the `CLOUDX_FLUTTER_VERBOSE_LOG` environment variable. This flag is specifically designed for Flutter development to ensure logs are visible in the Flutter console output.

#### Why a Flutter-specific flag?

The CloudX Core SDK uses `os_log` for system-level logging, which doesn't appear in Flutter's console output by default. The `CLOUDX_FLUTTER_VERBOSE_LOG` flag ensures that important debugging information (like bid requests/responses) is also logged to `NSLog`, making it visible in Flutter's console during development.

#### Option 1: Programmatically in iOS Plugin (Recommended)

The CloudX Flutter SDK automatically sets the environment variables when the plugin is registered. If you need to ensure verbose logging is enabled, you can add this to your iOS plugin code:

```objc
// In your iOS plugin's registerWithRegistrar method
setenv("CLOUDX_FLUTTER_VERBOSE_LOG", "1", 1);
```

#### Option 2: Add to Info.plist

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>CLOUDX_FLUTTER_VERBOSE_LOG</key>
<string>1</string>
```

#### Option 3: Set Environment Variable

Set the environment variable before running your Flutter app:

```bash
export CLOUDX_FLUTTER_VERBOSE_LOG=1
flutter run
```

#### Option 4: Xcode Scheme Environment Variables

1. Open your project in Xcode
2. Go to Product → Scheme → Edit Scheme
3. Select "Run" and go to "Arguments" tab
4. Add Environment Variable: Name: `CLOUDX_FLUTTER_VERBOSE_LOG`, Value: `1`

This will enable comprehensive logging from the CloudX Core SDK, including:
- SDK initialization details
- Ad loading and bidding processes
- Network requests and responses (including full bid request/response JSON)
- Delegate callback events
- Error details and debugging information

#### Viewing Core SDK Logs

To see the Core SDK logs in your terminal, use this essential command:

```bash
xcrun simctl spawn booted log stream --predicate 'process == "Runner"' --style compact | grep -E "(CloudX|🔴|printf|NSLog)"
```

This command filters the iOS simulator logs to show only CloudX-related output, including:
- Core SDK initialization logs
- Ad loading and bidding processes
- Network requests and responses
- Delegate callback events
- Error details and debugging information

**Note**: Flutter verbose logging should only be enabled during development and debugging. Remove this flag for production builds to avoid performance impact and excessive log output.

## SDK Initialization

Initialize the CloudX SDK in your app's main entry point:

```dart
import 'package:cloudx_flutter_sdk/cloudx.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize CloudX SDK
  final success = await CloudX.initialize(
    appKey: 'your-app-key-here',
    hashedUserID: 'user-id-optional',
  );
  
  if (success) {
    print('CloudX SDK initialized successfully');
  } else {
    print('Failed to initialize CloudX SDK');
  }
  
  runApp(MyApp());
}
```

## Ad Types & Implementation

### Banner Ads

```dart
import 'package:cloudx_flutter_sdk/cloudx.dart';

class BannerAdExample extends StatefulWidget {
  @override
  _BannerAdExampleState createState() => _BannerAdExampleState();
}

class _BannerAdExampleState extends State<BannerAdExample> {
  bool isAdLoaded = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _createBannerAd();
  }

  Future<void> _createBannerAd() async {
    try {
      // Create banner ad with listener
      await CloudX.createBanner(
        placement: 'your-banner-placement',
        adId: 'banner-1',
        listener: BannerListener()
          ..onAdLoaded = () {
            setState(() {
              isAdLoaded = true;
              errorMessage = null;
            });
            print('Banner ad loaded successfully');
          }
          ..onAdFailedToLoad = (error) {
            setState(() {
              isAdLoaded = false;
              errorMessage = error;
            });
            print('Banner ad failed to load: $error');
          }
          ..onAdClicked = () {
            print('Banner ad clicked');
          }
          ..onAdImpression = () {
            print('Banner ad impression recorded');
          },
      );

      // Load the banner ad
      await CloudX.loadBanner(adId: 'banner-1');
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (errorMessage != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.red[100],
            child: Text('Error: $errorMessage'),
          ),
        if (isAdLoaded)
          Container(
            width: 320,
            height: 50,
            child: CloudXBannerView(adId: 'banner-1'),
          ),
        ElevatedButton(
          onPressed: isAdLoaded ? _createBannerAd : null,
          child: Text('Reload Banner'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    CloudX.destroyAd(adId: 'banner-1');
    super.dispose();
  }
}
```

### Interstitial Ads

```dart
import 'package:cloudx_flutter_sdk/cloudx.dart';

class InterstitialAdExample extends StatefulWidget {
  @override
  _InterstitialAdExampleState createState() => _InterstitialAdExampleState();
}

class _InterstitialAdExampleState extends State<InterstitialAdExample> {
  bool isAdReady = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _createInterstitialAd();
  }

  Future<void> _createInterstitialAd() async {
    try {
      await CloudX.createInterstitial(
        placement: 'your-interstitial-placement',
        adId: 'interstitial-1',
        listener: InterstitialListener()
          ..onAdLoaded = () {
            setState(() {
              isAdReady = true;
              errorMessage = null;
            });
            print('Interstitial ad loaded successfully');
          }
          ..onAdFailedToLoad = (error) {
            setState(() {
              isAdReady = false;
              errorMessage = error;
            });
            print('Interstitial ad failed to load: $error');
          }
          ..onAdClicked = () {
            print('Interstitial ad clicked');
          }
          ..onAdImpression = () {
            print('Interstitial ad impression recorded');
          }
          ..onAdClosed = () {
            setState(() {
              isAdReady = false;
            });
            print('Interstitial ad closed');
            // Reload for next use
            _createInterstitialAd();
          },
      );

      await CloudX.loadInterstitial(adId: 'interstitial-1');
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _showInterstitial() async {
    if (isAdReady) {
      await CloudX.showInterstitial(adId: 'interstitial-1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (errorMessage != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.red[100],
            child: Text('Error: $errorMessage'),
          ),
        ElevatedButton(
          onPressed: isAdReady ? _showInterstitial : null,
          child: Text(isAdReady ? 'Show Interstitial' : 'Loading...'),
        ),
        ElevatedButton(
          onPressed: _createInterstitialAd,
          child: Text('Reload Interstitial'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    CloudX.destroyAd(adId: 'interstitial-1');
    super.dispose();
  }
}
```

### Rewarded Ads

```dart
import 'package:cloudx_flutter_sdk/cloudx.dart';

class RewardedAdExample extends StatefulWidget {
  @override
  _RewardedAdExampleState createState() => _RewardedAdExampleState();
}

class _RewardedAdExampleState extends State<RewardedAdExample> {
  bool isAdReady = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _createRewardedAd();
  }

  Future<void> _createRewardedAd() async {
    try {
      await CloudX.createRewarded(
        placement: 'your-rewarded-placement',
        adId: 'rewarded-1',
        listener: RewardedListener()
          ..onAdLoaded = () {
            setState(() {
              isAdReady = true;
              errorMessage = null;
            });
            print('Rewarded ad loaded successfully');
          }
          ..onAdFailedToLoad = (error) {
            setState(() {
              isAdReady = false;
              errorMessage = error;
            });
            print('Rewarded ad failed to load: $error');
          }
          ..onAdClicked = () {
            print('Rewarded ad clicked');
          }
          ..onAdImpression = () {
            print('Rewarded ad impression recorded');
          }
          ..onAdClosed = () {
            setState(() {
              isAdReady = false;
            });
            print('Rewarded ad closed');
            _createRewardedAd(); // Reload for next use
          }
          ..onRewarded = (reward) {
            print('User earned reward: ${reward.amount} ${reward.type}');
            // Handle reward here
            _showRewardDialog(reward);
          },
      );

      await CloudX.loadRewarded(adId: 'rewarded-1');
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _showRewarded() async {
    if (isAdReady) {
      await CloudX.showRewarded(adId: 'rewarded-1');
    }
  }

  void _showRewardDialog(Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reward Earned!'),
        content: Text('You earned ${reward.amount} ${reward.type}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (errorMessage != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.red[100],
            child: Text('Error: $errorMessage'),
          ),
        ElevatedButton(
          onPressed: isAdReady ? _showRewarded : null,
          child: Text(isAdReady ? 'Show Rewarded Ad' : 'Loading...'),
        ),
        ElevatedButton(
          onPressed: _createRewardedAd,
          child: Text('Reload Rewarded Ad'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    CloudX.destroyAd(adId: 'rewarded-1');
    super.dispose();
  }
}
```

### Native Ads

```dart
import 'package:cloudx_flutter_sdk/cloudx.dart';

class NativeAdExample extends StatefulWidget {
  @override
  _NativeAdExampleState createState() => _NativeAdExampleState();
}

class _NativeAdExampleState extends State<NativeAdExample> {
  bool isAdReady = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _createNativeAd();
  }

  Future<void> _createNativeAd() async {
    try {
      await CloudX.createNative(
        placement: 'your-native-placement',
        adId: 'native-1',
        listener: NativeListener()
          ..onAdLoaded = () {
            setState(() {
              isAdReady = true;
              errorMessage = null;
            });
            print('Native ad loaded successfully');
          }
          ..onAdFailedToLoad = (error) {
            setState(() {
              isAdReady = false;
              errorMessage = error;
            });
            print('Native ad failed to load: $error');
          }
          ..onAdClicked = () {
            print('Native ad clicked');
          }
          ..onAdImpression = () {
            print('Native ad impression recorded');
          },
      );

      await CloudX.loadNative(adId: 'native-1');
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (errorMessage != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.red[100],
            child: Text('Error: $errorMessage'),
          ),
        if (isAdReady)
          Container(
            width: double.infinity,
            height: 200,
            child: CloudXNativeView(adId: 'native-1'),
          ),
        ElevatedButton(
          onPressed: _createNativeAd,
          child: Text('Reload Native Ad'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    CloudX.destroyAd(adId: 'native-1');
    super.dispose();
  }
}
```

### MREC Ads (Medium Rectangle)

```dart
import 'package:cloudx_flutter_sdk/cloudx.dart';

class MRECAdExample extends StatefulWidget {
  @override
  _MRECAdExampleState createState() => _MRECAdExampleState();
}

class _MRECAdExampleState extends State<MRECAdExample> {
  bool isAdReady = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _createMRECAd();
  }

  Future<void> _createMRECAd() async {
    try {
      await CloudX.createMREC(
        placement: 'your-mrec-placement',
        adId: 'mrec-1',
        listener: MRECListener()
          ..onAdLoaded = () {
            setState(() {
              isAdReady = true;
              errorMessage = null;
            });
            print('MREC ad loaded successfully');
          }
          ..onAdFailedToLoad = (error) {
            setState(() {
              isAdReady = false;
              errorMessage = error;
            });
            print('MREC ad failed to load: $error');
          }
          ..onAdClicked = () {
            print('MREC ad clicked');
          }
          ..onAdImpression = () {
            print('MREC ad impression recorded');
          },
      );

      await CloudX.loadMREC(adId: 'mrec-1');
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (errorMessage != null)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.red[100],
            child: Text('Error: $errorMessage'),
          ),
        if (isAdReady)
          Container(
            width: 300,
            height: 250,
            child: CloudXMRECView(adId: 'mrec-1'),
          ),
        ElevatedButton(
          onPressed: _createMRECAd,
          child: Text('Reload MREC Ad'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    CloudX.destroyAd(adId: 'mrec-1');
    super.dispose();
  }
}
```

## Complete App Example

Here's a complete example showing how to integrate all ad types in a single app:

```dart
import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize CloudX SDK
  final success = await CloudX.initialize(
    appKey: 'your-app-key-here',
    hashedUserID: 'user-id-optional',
  );
  
  if (success) {
    print('CloudX SDK initialized successfully');
  } else {
    print('Failed to initialize CloudX SDK');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudX Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AdDemoScreen(),
    );
  }
}

class AdDemoScreen extends StatefulWidget {
  @override
  _AdDemoScreenState createState() => _AdDemoScreenState();
}

class _AdDemoScreenState extends State<AdDemoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    final initialized = await CloudX.isInitialized();
    setState(() {
      isInitialized = initialized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CloudX Ad Demo'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Banner'),
            Tab(text: 'Interstitial'),
            Tab(text: 'Rewarded'),
            Tab(text: 'Native'),
            Tab(text: 'MREC'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BannerAdExample(),
          InterstitialAdExample(),
          RewardedAdExample(),
          NativeAdExample(),
          MRECAdExample(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

## API Reference

### Core Methods

| Method | Description |
|--------|-------------|
| `CloudX.initialize(appKey, hashedUserID?)` | Initialize the SDK |
| `CloudX.isInitialized()` | Check if SDK is initialized |
| `CloudX.getVersion()` | Get SDK version |

### Ad Creation Methods

| Method | Description |
|--------|-------------|
| `CloudX.createBanner(placement, adId, listener?)` | Create banner ad |
| `CloudX.createInterstitial(placement, adId, listener?)` | Create interstitial ad |
| `CloudX.createRewarded(placement, adId, listener?)` | Create rewarded ad |
| `CloudX.createNative(placement, adId, listener?)` | Create native ad |
| `CloudX.createMREC(placement, adId, listener?)` | Create MREC ad |

### Ad Control Methods

| Method | Description |
|--------|-------------|
| `CloudX.loadBanner(adId)` | Load banner ad |
| `CloudX.showBanner(adId)` | Show banner ad |
| `CloudX.hideBanner(adId)` | Hide banner ad |
| `CloudX.loadInterstitial(adId)` | Load interstitial ad |
| `CloudX.showInterstitial(adId)` | Show interstitial ad |
| `CloudX.isInterstitialReady(adId)` | Check if interstitial is ready |
| `CloudX.loadRewarded(adId)` | Load rewarded ad |
| `CloudX.showRewarded(adId)` | Show rewarded ad |
| `CloudX.isRewardedReady(adId)` | Check if rewarded is ready |
| `CloudX.loadNative(adId)` | Load native ad |
| `CloudX.showNative(adId)` | Show native ad |
| `CloudX.isNativeReady(adId)` | Check if native is ready |
| `CloudX.loadMREC(adId)` | Load MREC ad |
| `CloudX.showMREC(adId)` | Show MREC ad |
| `CloudX.isMRECReady(adId)` | Check if MREC is ready |
| `CloudX.destroyAd(adId)` | Destroy any ad type |

### Listener Events

All ad types support these common events:
- `onAdLoaded` - Ad loaded successfully
- `onAdFailedToLoad` - Ad failed to load
- `onAdClicked` - Ad was clicked
- `onAdImpression` - Ad impression recorded

**Rewarded ads additionally support:**
- `onRewarded` - User earned reward
- `onAdClosed` - Ad was closed

## Demo App

The included demo app (`cloudx_flutter_demo_app/`) provides a complete testing environment with:

- Tab-based navigation for all ad types
- Real-time status indicators
- Error handling and user feedback
- Auto-reload functionality
- Comprehensive event logging

To run the demo:
```bash
cd cloudx_flutter_demo_app
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Requirements

- **Flutter**: 3.0.0 or later
- **Dart**: 3.0.0 or later
- **iOS**: 14.0 or later
- **Xcode**: 12.0 or later
- **CocoaPods**: Latest version

## Support

For support and questions:
- Email: eng@cloudx.io
- Documentation: https://github.com/cloudx-xenoss/CloudXFlutterSDK
- Issues: https://github.com/cloudx-xenoss/CloudXFlutterSDK/issues

## License

This project is licensed under the same license as the CloudX Core SDK. 