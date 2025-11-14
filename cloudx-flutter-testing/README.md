# CloudX Flutter Demo App

A Flutter demo application that demonstrates the integration of the CloudX Flutter SDK with support for banner, MREC, and interstitial ads.

## Features

- **SDK Initialization**: Initialize the CloudX SDK with app key and environment selection
- **Banner Ads**: Create and display banner ads (320x50) with widget-based and programmatic approaches
- **Interstitial Ads**: Create and show full-screen interstitial ads
- **MREC Ads**: Create and display medium rectangle ads (300x250)
- **Tab Navigation**: Easy navigation between different ad types
- **Event Logging**: Comprehensive event logs showing all ad lifecycle callbacks
- **Status Indicators**: Real-time status updates for ad loading and display
- **Error Handling**: Comprehensive error handling and user feedback

## App Structure

The app is organized into the following screens:

1. **Home Screen**: SDK initialization with environment selection (dev/staging/production)
2. **Banner Screen**: Banner ad creation and display with widget and programmatic examples
3. **Interstitial Screen**: Interstitial ad creation and display
4. **MREC Screen**: MREC ad creation and display
5. **Logs Modal**: View all ad lifecycle events with CLXAd metadata

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

- **cloudx_flutter_sdk**: The Flutter SDK wrapper for CloudX (local path dependency)
- **CloudXCore**: The underlying iOS Objective-C SDK (~> 1.1.40 via CocoaPods)
- **CloudX Android SDK**: The underlying Android SDK (0.5.0 via Maven Central)

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or later)
- Dart SDK (3.0.0 or later)
- iOS 14.0 or later (for iOS development)
- Xcode 12.0 or later (for iOS development)
- CocoaPods (for iOS development)
- Android API 21+ (for Android development)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/cloudx-io/cloudx-flutter.git
   cd cloudx-flutter/cloudx_flutter_demo_app
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
   # Run on any connected device/simulator
   flutter run

   # Or specify platform
   flutter run -d ios
   flutter run -d android
   ```

## Usage

### 1. Initialize the SDK
- On app launch, select your environment (dev/staging/production)
- The SDK will automatically initialize
- Wait for the success confirmation before testing ads

### 2. Test Different Ad Types
- Navigate to any ad type tab (Banner, Interstitial, MREC)
- **Banner/MREC**: Ads load automatically when you navigate to the tab
- **Interstitial**: Tap "Load Ad" then "Show Ad" when ready
- Monitor the status indicator at the bottom of the screen

### 3. Monitor Ad Events
- Tap the "Logs" button to view all ad lifecycle events
- Each event shows timestamp, event type, and CLXAd metadata (bidder, revenue, etc.)
- Console logs provide additional debugging information
- Status indicators show the current state of each ad

## Configuration

All configuration is centralized in `lib/config/demo_config.dart`:

### Environment Support
- **Development**: For testing with dev servers
- **Staging**: For pre-production testing
- **Production**: For production CloudX servers

### Platform-Specific Configuration
Each environment has separate configurations for iOS and Android:
- **App Keys**: Platform-specific CloudX app keys
- **Placement Names**: Ad unit identifiers (banner, interstitial, MREC)

To modify configurations, edit `lib/config/demo_config.dart`.

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

**Verbose Logging**: This demo app has verbose logging enabled by default to help with debugging:
- Calls `CloudX.setLoggingEnabled(true)` before SDK initialization
- All ad lifecycle events are logged to the console
- Use the in-app Logs viewer to see event history with metadata

Additional debugging tips:
- Check the console for detailed error messages
- Use the Logs button to view all ad events in the app
- Monitor the status indicators for real-time feedback
- iOS logs will appear in Xcode console and device logs
- Android logs can be viewed with `adb logcat | grep CX:`

## License

This project is licensed under the same license as the CloudX SDK. 