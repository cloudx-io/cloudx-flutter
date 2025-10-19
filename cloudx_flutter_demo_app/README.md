# CloudX Flutter Demo App

A Flutter demo application that demonstrates the integration of the CloudX Flutter SDK. This app mirrors the functionality of the CloudXObjCRemotePods iOS app but uses the Flutter SDK wrapper instead of the native Objective-C SDK directly.

## Features

- **SDK Initialization**: Initialize the CloudX SDK with app key and user ID
- **Banner Ads**: Create and display banner ads (320x50)
- **Interstitial Ads**: Create and show full-screen interstitial ads
- **Rewarded Ads**: Create and show rewarded interstitial ads
- **Native Ads**: Create and display native ads
- **MREC Ads**: Create and display medium rectangle ads (300x250)
- **Tab Navigation**: Easy navigation between different ad types
- **Status Indicators**: Real-time status updates for ad loading and display
- **Error Handling**: Comprehensive error handling and user feedback

## App Structure

The app is organized into the following screens:

1. **Init Screen**: SDK initialization with status indicators
2. **Banner Screen**: Banner ad creation and display
3. **Interstitial Screen**: Interstitial ad creation and display
4. **Rewarded Screen**: Rewarded ad creation and display
5. **MREC Screen**: MREC ad creation and display
6. **Native Screen**: Native ad creation and display

## Architecture

### BaseAdScreen
A base class that provides common functionality for all ad screens:
- Status UI management
- Error handling
- Ad event handling
- Loading state management
- Common UI components

### Individual Ad Screens
Each ad type has its own screen that extends `BaseAdScreen`:
- Implements specific ad creation logic
- Handles ad-specific events
- Provides ad-type-specific UI

## Dependencies

- **cloudx_flutter_sdk**: The Flutter SDK wrapper for CloudX
- **CloudXCore**: The underlying Objective-C SDK (via CocoaPods)
- **CloudXTestVastNetworkAdapter**: Test adapter for development

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or later)
- iOS 14.0 or later
- Xcode 12.0 or later
- CocoaPods

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd CloudXFlutterSDK/cloudx_flutter_demo_app
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Install iOS dependencies**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Usage

### 1. Initialize the SDK
- Navigate to the "Init" tab
- Tap "Initialize SDK" to initialize the CloudX SDK
- Wait for the success confirmation

### 2. Test Different Ad Types
- Navigate to any ad type tab (Banner, Interstitial, Rewarded, MREC, Native)
- Tap "Load Ad" to create and load an ad
- Once loaded, tap "Show Ad" to display the ad
- Monitor the status indicator at the bottom of the screen

### 3. Monitor Ad Events
- The app logs all ad events to the console
- Status indicators show the current state of each ad
- Error dialogs appear for any issues

## Configuration

### App Key
The app uses a test app key: `qT9U-tJ0FRb0x4gXb-pF0`

### Placements
- Banner: `banner11239747913482`
- Interstitial: `interstitial1`
- Rewarded: `rewarded1`
- MREC: `mrec1`
- Native: `native1`

### User ID
The app uses a test user ID: `test-user-123`

## Development

### Adding New Ad Types
1. Create a new screen that extends `BaseAdScreen`
2. Implement the required methods:
   - `getAdIdPrefix()`
   - `_buildMainContent()`
   - `_loadAd()`
   - `_showAd()`
3. Add the screen to the main tab navigation

### Customizing UI
- Modify the `_buildMainContent()` method in each screen
- Update the `BaseAdScreen` for common UI changes
- Customize colors, fonts, and layouts in the theme

### Error Handling
- All errors are displayed in alert dialogs
- Network errors are handled gracefully
- Ad loading failures are reported to the user

## Troubleshooting

### Common Issues

1. **SDK not initialized**:
   - Make sure to initialize the SDK in the Init tab first
   - Check that the app key is correct

2. **Ad loading fails**:
   - Verify network connectivity
   - Check that the placement IDs are correct
   - Ensure the SDK is properly initialized

3. **Build errors**:
   - Run `flutter clean` and `flutter pub get`
   - Run `cd ios && pod install && cd ..`
   - Check that all dependencies are properly installed

### Debug Information

**Verbose Logging**: This demo app has verbose logging enabled by default to help with debugging. The logging is configured in:
- **iOS**: Calls `CloudXCore.setLoggingEnabled(true)` before SDK initialization
- **Android**: Calls `CloudX.setLoggingEnabled(true)` before SDK initialization

Additional debugging tips:
- Check the console for detailed error messages
- Monitor the status indicators for real-time feedback
- iOS logs will appear in Xcode console and device logs
- Android logs can be viewed with `adb logcat | grep CX:`

## License

This project is licensed under the same license as the CloudX SDK. 