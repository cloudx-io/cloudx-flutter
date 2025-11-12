library cloudx;

import 'dart:async';
import 'dart:io';

import 'package:cloudx_flutter/listeners/cloudx_ad_listener.dart';
import 'package:cloudx_flutter/listeners/cloudx_ad_view_listener.dart';
import 'package:cloudx_flutter/listeners/cloudx_interstitial_listener.dart';
import 'package:cloudx_flutter/listeners/cloudx_rewarded_interstitial_listener.dart';
import 'package:cloudx_flutter/models/banner_position.dart';
import 'package:cloudx_flutter/models/cloudx_ad.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ==============================================================================
// MARK: - Public API Exports
// ==============================================================================
export 'listeners/cloudx_ad_listener.dart';
export 'listeners/cloudx_ad_view_listener.dart';
export 'listeners/cloudx_interstitial_listener.dart';
export 'listeners/cloudx_rewarded_interstitial_listener.dart';
export 'models/banner_position.dart';
export 'models/cloudx_ad.dart';
export 'widgets/cloudx_ad_view_controller.dart';
export 'widgets/cloudx_banner_view.dart';
export 'widgets/cloudx_mrec_view.dart';

// ignore: avoid_classes_with_only_static_members
/// The main CloudX Flutter SDK class.
///
/// Provides a comprehensive Flutter wrapper for the CloudX Core Objective-C SDK.
class CloudX {
  static const MethodChannel _channel = MethodChannel('cloudx_flutter_sdk');
  static const EventChannel _eventChannel =
      EventChannel('cloudx_flutter_sdk_events');

  // Internal logging control (disabled by default for production)
  static bool _loggingEnabled = false;

  // Listener storage (SRP: separated by type)
  static final Map<String, CloudXAdListener> _listeners = {};

  // Event stream (initialized lazily)
  static StreamSubscription? _eventSubscription;
  static bool _eventStreamInitialized = false;

  /// Flutter plugin registration (required for some plugin registration scenarios)
  static void registerWith() {}

  // ============================================================================
  // MARK: - Core SDK Methods
  // ============================================================================

  /// Initialize the CloudX SDK
  ///
  /// [appKey] - Your CloudX app key
  /// [testMode] - Set to `true` to enable test mode (shows test ads)
  ///
  /// Returns `true` if initialization was successful
  /// Returns `false` if initialization fails or platform is not supported
  ///
  /// **Platform Support:**
  /// - Android: ✅ Production-ready
  /// - iOS: ❌ Not supported (returns false)
  static Future<bool> initialize({
    required String appKey,
    bool testMode = false,
  }) async {
    final arguments = <String, dynamic>{
      'appKey': appKey,
      'testMode': testMode,
    };

    try {
      final result = await _invokeMethod<bool>('initSDK', arguments);

      // Log warning on iOS since it's not supported
      if (Platform.isIOS && (result == null || !result)) {
        debugPrint('⚠️ CloudX iOS SDK is not yet supported.');
        debugPrint('⚠️ Currently only Android is fully supported.');
      }

      await _ensureEventStreamInitialized();
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('❌ CloudX initialization failed: ${e.message}');
      debugPrint('   Error code: ${e.code}');
      if (e.details != null) {
        debugPrint('   Details: ${e.details}');
      }
      return false;
    }
  }

  /// Check if the current platform is supported by CloudX SDK
  ///
  /// Returns `true` if platform is production-ready, `false` otherwise
  ///
  /// Currently:
  /// - Android: Production-ready ✅
  /// - iOS: Not supported ❌
  static bool isPlatformSupported() {
    return !Platform.isIOS;
  }

  /// Get the SDK version
  static Future<String> getVersion() async {
    try {
      return await _invokeMethod<String>('getSDKVersion') ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Set the user ID
  static Future<void> setUserID(String? userID) async {
    await _invokeMethod('setUserID', {'userID': userID});
  }

  /// Set the environment (dev, staging, production)
  /// Must be called BEFORE initialize()
  static Future<void> setEnvironment(String environment) async {
    await _invokeMethod('setEnvironment', {'environment': environment});
  }

  /// Enable or disable SDK logging
  ///
  /// Controls verbose logging output from the SDK. Disabled by default in production.
  /// Call this method early in your app lifecycle, before SDK initialization, to see all logs.
  ///
  /// This controls both Dart-side and native-side logging.
  static Future<void> setLoggingEnabled(bool enabled) async {
    _loggingEnabled = enabled; // Control Dart-side logging
    await _invokeMethod(
      'setLoggingEnabled',
      {'enabled': enabled},
    ); // Control native-side logging
  }

  /// Deinitialize the CloudX SDK
  ///
  /// Cleans up SDK resources and resets initialization state.
  /// Call this when you need to completely tear down the SDK, such as during app logout.
  /// You can reinitialize the SDK afterward by calling initialize() again.
  static Future<void> deinitialize() async {
    // Cancel EventChannel subscription to prevent memory leak
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _eventStreamInitialized = false;

    // Clear listener storage
    _listeners.clear();

    // Call native deinitialize
    await _invokeMethod('deinitialize');
  }

  /// Internal logging helper that respects the logging flag
  ///
  /// Only logs when _loggingEnabled is true. Use this instead of print()
  /// to prevent log pollution in production builds.
  static void _log(String message, {bool isError = false}) {
    if (_loggingEnabled) {
      final prefix = isError ? '❌ [CloudX]' : '🔵 [CloudX]';
      debugPrint('$prefix $message');
    }
  }

  // ============================================================================
  // MARK: - Privacy & Compliance APIs
  // ============================================================================

  /// Set CCPA privacy string (e.g., "1YNN")
  ///
  /// California Consumer Privacy Act compliance.
  /// Format: "1" + version + opt-out-sale + opt-out-sharing + limited-service-provider
  ///
  /// Example: "1YNN" = version 1, opted out of sale, not opted out of sharing, not LSP
  static Future<void> setCCPAPrivacyString(String? ccpaString) async {
    await _invokeMethod('setCCPAPrivacyString', {'ccpaString': ccpaString});
  }

  /// Set whether user has given consent (GDPR)
  ///
  /// ⚠️ Warning: GDPR is not yet supported by CloudX.
  /// Use CCPA for privacy compliance in supported regions.
  static Future<void> setIsUserConsent(bool hasConsent) async {
    await _invokeMethod('setIsUserConsent', {'isUserConsent': hasConsent});
  }

  /// Set whether user is age-restricted (COPPA)
  ///
  /// Children's Online Privacy Protection Act compliance.
  /// Data clearing is implemented but not included in bid requests (server limitation).
  static Future<void> setIsAgeRestrictedUser(bool isAgeRestricted) async {
    await _invokeMethod('setIsAgeRestrictedUser', {
      'isAgeRestrictedUser': isAgeRestricted,
    });
  }

  /// Set GPP (Global Privacy Platform) consent string
  ///
  /// IAB Global Privacy Platform compliance string for comprehensive
  /// privacy management across multiple jurisdictions.
  static Future<void> setGPPString(String? gppString) async {
    await _invokeMethod('setGPPString', {'gppString': gppString});
  }

  /// Get GPP consent string
  ///
  /// Returns the current GPP consent string, or null if not set.
  static Future<String?> getGPPString() async {
    try {
      return await _invokeMethod<String>('getGPPString');
    } catch (e) {
      return null;
    }
  }

  /// Set GPP section IDs
  ///
  /// Array of GPP section IDs indicating applicable privacy frameworks.
  /// Example: [7, 8] for US-National (7) and US-CA/California (8)
  static Future<void> setGPPSid(List<int>? sectionIds) async {
    await _invokeMethod('setGPPSid', {'gppSid': sectionIds});
  }

  /// Get GPP section IDs
  ///
  /// Returns array of GPP section IDs, or null if not set.
  static Future<List<int>?> getGPPSid() async {
    try {
      final result = await _invokeMethod<List>('getGPPSid');
      return result?.cast<int>();
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // MARK: - User Targeting APIs
  // ============================================================================

  /// Set user-level key-value pair for targeting
  ///
  /// User-level key-values are injected into bid requests at server-configured paths.
  /// These values are typically user-specific targeting parameters and will be cleared
  /// if privacy regulations require removing personal data (COPPA).
  static Future<void> setUserKeyValue(String key, String value) async {
    await _invokeMethod('setUserKeyValue', {'key': key, 'value': value});
  }

  /// Set app-level key-value pair for targeting
  ///
  /// App-level key-values are injected into bid requests at server-configured paths.
  /// These values are typically app-specific targeting parameters and are NOT affected
  /// by privacy regulations (persistent across privacy changes).
  static Future<void> setAppKeyValue(String key, String value) async {
    await _invokeMethod('setAppKeyValue', {'key': key, 'value': value});
  }

  /// Clear all user and app-level key-value pairs
  ///
  /// Removes all previously set targeting key-value pairs (both user-level and app-level).
  /// Useful for resetting targeting state or implementing privacy controls.
  static Future<void> clearAllKeyValues() async {
    await _invokeMethod('clearAllKeyValues');
  }

  // ============================================================================
  // MARK: - Banner Ad Methods
  // ============================================================================

  /// Create a banner ad
  ///
  /// If [adId] is not provided, one will be automatically generated.
  /// Returns the adId (either provided or generated) for use with other methods.
  ///
  /// [placementName] - Ad placement name
  /// [adId] - Optional custom ad identifier
  /// [listener] - Optional callback listener for ad events
  /// [position] - Optional position for programmatic banner placement.
  ///   If provided, creates a native overlay banner at the specified position.
  ///   If null, creates a widget-based banner for use with CloudXBannerView.
  static Future<String?> createBanner({
    required String placementName,
    String? adId,
    CloudXAdViewListener? listener,
    AdViewPosition? position,
  }) async {
    await _ensureEventStreamInitialized();

    // Auto-generate adId if not provided
    final id = adId ??
        'banner_${placementName}_${DateTime.now().millisecondsSinceEpoch}';

    final arguments = <String, dynamic>{
      'placementName': placementName,
      'adId': id,
    };

    // Add position if programmatic banner
    if (position != null) {
      arguments['position'] = position.value;
    }

    final success = await _invokeMethod<bool>('createBanner', arguments);

    if (success ?? false) {
      if (listener != null) {
        _listeners[id] = listener;
      }
      return id;
    }

    return null;
  }

  /// Load a banner ad
  static Future<bool> loadBanner({required String adId}) async {
    return await _invokeMethod<bool>('loadAd', {'adId': adId}) ?? false;
  }

  /// Show a banner ad
  static Future<bool> showBanner({required String adId}) async {
    return await _invokeMethod<bool>('showAd', {'adId': adId}) ?? false;
  }

  /// Hide a banner ad temporarily without destroying it
  ///
  /// Use this method to temporarily remove a banner from view while keeping the ad instance alive.
  /// This is useful when you want to hide ads during specific user interactions (e.g., during video playback,
  /// in-app purchases, or other sensitive screens) and show them again later.
  ///
  /// To show the ad again, call [showBanner] with the same [adId].
  ///
  /// **Important**: This does NOT stop auto-refresh if enabled. The ad will continue to refresh in the background.
  /// Call [stopAutoRefresh] if you want to pause refreshing while hidden.
  ///
  /// **When to use [hideBanner] vs [destroyAd]**:
  /// - Use [hideBanner] when you plan to show the ad again later in the same session
  /// - Use [destroyAd] when you're completely done with the ad (e.g., navigating away from the screen)
  ///
  /// Example:
  /// ```dart
  /// // Hide banner during video playback
  /// await CloudX.stopAutoRefresh(adId: bannerId);
  /// await CloudX.hideBanner(adId: bannerId);
  ///
  /// // Show banner again when video ends
  /// await CloudX.showBanner(adId: bannerId);
  /// await CloudX.startAutoRefresh(adId: bannerId);
  /// ```
  static Future<bool> hideBanner({required String adId}) async {
    return await _invokeMethod<bool>('hideAd', {'adId': adId}) ?? false;
  }

  // ============================================================================
  // MARK: - MREC Ad Methods
  // ============================================================================

  /// Create an MREC (Medium Rectangle) ad
  ///
  /// If [adId] is not provided, one will be automatically generated.
  /// Returns the adId (either provided or generated) for use with other methods.
  static Future<String?> createMREC({
    required String placementName,
    String? adId,
    CloudXAdViewListener? listener,
    AdViewPosition? position,
  }) async {
    await _ensureEventStreamInitialized();

    // Auto-generate adId if not provided
    final id = adId ??
        'mrec_${placementName}_${DateTime.now().millisecondsSinceEpoch}';

    final success = await _invokeMethod<bool>('createMREC', {
      'placementName': placementName,
      'adId': id,
      if (position != null) 'position': position.value,
    });

    if (success ?? false) {
      if (listener != null) {
        _listeners[id] = listener;
      }
      return id;
    }

    return null;
  }

  /// Load an MREC ad
  static Future<bool> loadMREC({required String adId}) async {
    return await _invokeMethod<bool>('loadAd', {'adId': adId}) ?? false;
  }

  /// Show an MREC ad
  static Future<bool> showMREC({required String adId}) async {
    return await _invokeMethod<bool>('showAd', {'adId': adId}) ?? false;
  }

  /// Check if MREC ad is ready to show
  static Future<bool> isMRECReady({required String adId}) async {
    return await _invokeMethod<bool>('isAdReady', {'adId': adId}) ?? false;
  }

  /// Start auto-refresh for banner or MREC ad
  ///
  /// Enables automatic ad refresh for the specified banner/MREC ad instance.
  /// The refresh interval is configured server-side in CloudX dashboard.
  static Future<bool> startAutoRefresh({required String adId}) async {
    return await _invokeMethod<bool>('startAutoRefresh', {'adId': adId}) ??
        false;
  }

  /// Stop auto-refresh for banner or MREC ad
  ///
  /// Disables automatic ad refresh for the specified banner/MREC ad instance.
  /// Critical to call this when destroying ads to prevent background timers.
  static Future<bool> stopAutoRefresh({required String adId}) async {
    return await _invokeMethod<bool>('stopAutoRefresh', {'adId': adId}) ??
        false;
  }

  // ============================================================================
  // MARK: - Interstitial Ad Methods
  // ============================================================================

  /// Create an interstitial ad
  ///
  /// If [adId] is not provided, one will be automatically generated.
  /// Returns the adId (either provided or generated) for use with other methods.
  static Future<String?> createInterstitial({
    required String placementName,
    String? adId,
    CloudXInterstitialListener? listener,
  }) async {
    await _ensureEventStreamInitialized();

    // Auto-generate adId if not provided
    final id = adId ??
        'interstitial_${placementName}_${DateTime.now().millisecondsSinceEpoch}';

    final success = await _invokeMethod<bool>('createInterstitial', {
      'placementName': placementName,
      'adId': id,
    });

    if (success ?? false) {
      if (listener != null) {
        _listeners[id] = listener;
      }
      return id;
    }

    return null;
  }

  /// Load an interstitial ad
  static Future<bool> loadInterstitial({required String adId}) async {
    return await _invokeMethod<bool>('loadAd', {'adId': adId}) ?? false;
  }

  /// Show an interstitial ad
  static Future<bool> showInterstitial({required String adId}) async {
    return await _invokeMethod<bool>('showAd', {'adId': adId}) ?? false;
  }

  /// Check if interstitial ad is ready to show
  static Future<bool> isInterstitialReady({required String adId}) async {
    return await _invokeMethod<bool>('isAdReady', {'adId': adId}) ?? false;
  }

  // ============================================================================
  // MARK: - Rewarded Ad Methods
  // ============================================================================

  /// Create a rewarded ad (NOT READY - Internal use only)
  ///
  /// If [adId] is not provided, one will be automatically generated.
  /// Returns the adId (either provided or generated) for use with other methods.
  // ignore: unused_element
  static Future<String?> _createRewarded({
    required String placementName,
    String? adId,
    CloudXRewardedInterstitialListener? listener,
  }) async {
    await _ensureEventStreamInitialized();

    // Auto-generate adId if not provided
    final id = adId ??
        'rewarded_${placementName}_${DateTime.now().millisecondsSinceEpoch}';

    final success = await _invokeMethod<bool>('createRewarded', {
      'placementName': placementName,
      'adId': id,
    });

    if (success ?? false) {
      if (listener != null) {
        _listeners[id] = listener;
      }
      return id;
    }

    return null;
  }

  /// Load a rewarded ad (NOT READY - Internal use only)
  // ignore: unused_element
  static Future<bool> _loadRewarded({required String adId}) async {
    return await _invokeMethod<bool>('loadAd', {'adId': adId}) ?? false;
  }

  /// Show a rewarded ad (NOT READY - Internal use only)
  // ignore: unused_element
  static Future<bool> _showRewarded({required String adId}) async {
    return await _invokeMethod<bool>('showAd', {'adId': adId}) ?? false;
  }

  /// Check if rewarded ad is ready to show (NOT READY - Internal use only)
  // ignore: unused_element
  static Future<bool> _isRewardedReady({required String adId}) async {
    return await _invokeMethod<bool>('isAdReady', {'adId': adId}) ?? false;
  }

  // ============================================================================
  // MARK: - Native Ad Methods
  // ============================================================================

  /// Create a native ad (NOT READY - Internal use only)
  ///
  /// If [adId] is not provided, one will be automatically generated.
  /// Returns the adId (either provided or generated) for use with other methods.
  // ignore: unused_element
  static Future<String?> _createNative({
    required String placementName,
    String? adId,
    CloudXAdViewListener? listener,
  }) async {
    await _ensureEventStreamInitialized();

    // Auto-generate adId if not provided
    final id = adId ??
        'native_${placementName}_${DateTime.now().millisecondsSinceEpoch}';

    final success = await _invokeMethod<bool>('createNative', {
      'placementName': placementName,
      'adId': id,
    });

    if (success ?? false) {
      if (listener != null) {
        _listeners[id] = listener;
      }
      return id;
    }

    return null;
  }

  /// Load a native ad
  ///
  /// NOT READY - Internal use only. Native ads are not ready for public use.
  // ignore: unused_element
  static Future<bool> _loadNative({required String adId}) async {
    return await _invokeMethod<bool>('loadAd', {'adId': adId}) ?? false;
  }

  /// Show a native ad
  ///
  /// NOT READY - Internal use only. Native ads are not ready for public use.
  // ignore: unused_element
  static Future<bool> _showNative({required String adId}) async {
    return await _invokeMethod<bool>('showAd', {'adId': adId}) ?? false;
  }

  /// Check if native ad is ready to show
  ///
  /// NOT READY - Internal use only. Native ads are not ready for public use.
  // ignore: unused_element
  static Future<bool> _isNativeReady({required String adId}) async {
    return await _invokeMethod<bool>('isAdReady', {'adId': adId}) ?? false;
  }

  // ============================================================================
  // MARK: - Generic Ad Methods
  // ============================================================================

  /// Destroy an ad instance and free resources
  ///
  /// Call this when you're done with an ad to prevent memory leaks.
  static Future<bool> destroyAd({required String adId}) async {
    _listeners.remove(adId);
    return await _invokeMethod<bool>('destroyAd', {'adId': adId}) ?? false;
  }

  // ============================================================================
  // MARK: - Internal Methods (DRY Principle)
  // ============================================================================

  /// Centralized method invocation with error handling (DRY)
  static Future<T?> _invokeMethod<T>(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      _log('SDK method "$method" failed: ${e.message}', isError: true);
      rethrow;
    }
  }

  // Completer to track when EventChannel is actually ready on native side
  static Completer<void>? _eventChannelReadyCompleter;

  /// Ensure event stream is initialized (lazy initialization)
  ///
  /// Returns a Future that completes when the event stream subscription is fully established.
  /// Uses a test event to confirm the native side is ready instead of arbitrary delays.
  static Future<void> _ensureEventStreamInitialized() async {
    if (_eventStreamInitialized) {
      _log('Event stream already initialized');
      return;
    }

    _log('Initializing event stream...');
    _eventChannelReadyCompleter = Completer<void>();

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          // Check for ready confirmation
          final eventType = event['event'] as String?;
          if (eventType == '__eventChannelReady__' &&
              _eventChannelReadyCompleter != null &&
              !_eventChannelReadyCompleter!.isCompleted) {
            _log('EventChannel ready confirmation received');
            _eventChannelReadyCompleter!.complete();
          } else {
            _handleEvent(event);
          }
        }
      },
      onError: (error) {
        _log('Event stream error: $error', isError: true);
      },
    );

    _eventStreamInitialized = true;
    _log('Event stream subscription created');

    // Wait with timeout for the native side to be ready
    // If the completer isn't completed within 500ms, proceed anyway
    try {
      await _eventChannelReadyCompleter!.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          _log('EventChannel ready timeout - proceeding anyway', isError: true);
        },
      );
      _log('Event stream fully initialized');
    } catch (e) {
      _log('EventChannel initialization warning: $e', isError: true);
    } finally {
      _eventChannelReadyCompleter = null;
    }
  }

  /// Centralized event handling (DRY)
  static void _handleEvent(Map<Object?, Object?> event) {
    try {
      final adId = event['adId'] as String?;
      final eventType = event['event'] as String?;
      final data = event['data'] as Map<Object?, Object?>?;

      if (adId == null || eventType == null) {
        _log(
          'Event missing adId or eventType, ignoring: $event',
          isError: true,
        );
        return;
      }

      final listener = _listeners[adId];

      if (listener == null) {
        _log(
          'No listener found for adId: $adId (event: $eventType). Registered listeners: ${_listeners.keys.toList()}',
          isError: true,
        );
        return;
      }

      _log('Dispatching $eventType event for adId: $adId');
      _dispatchEventToListener(listener, eventType, data);
    } catch (e) {
      _log('Event handling error: $e', isError: true);
    }
  }

  /// Dispatch events to appropriate listener callbacks (DRY)
  static void _dispatchEventToListener(
    CloudXAdListener listener,
    String eventType,
    Map<Object?, Object?>? data,
  ) {
    // Parse ad data if present
    final adMap = data?['ad'] as Map<Object?, Object?>?;
    final ad = CloudXAd.fromMap(adMap);

    switch (eventType) {
      case 'didLoad':
        listener.onAdLoaded(ad);
        break;
      case 'failToLoad':
        final error = data?['error'] as String? ?? 'Unknown error';
        listener.onAdLoadFailed(error);
        break;
      case 'didShow':
        listener.onAdDisplayed(ad);
        break;
      case 'failToShow':
        final error = data?['error'] as String? ?? 'Unknown error';
        listener.onAdDisplayFailed(error);
        break;
      case 'didHide':
        listener.onAdHidden(ad);
        break;
      case 'didClick':
        listener.onAdClicked(ad);
        break;
      case 'revenuePaid':
        listener.onAdRevenuePaid?.call(ad);
        break;

      // Banner/MREC/Native-specific events
      case 'didExpandAd':
        if (listener is CloudXAdViewListener) {
          listener.onAdExpanded(ad);
        }
        break;
      case 'didCollapseAd':
        if (listener is CloudXAdViewListener) {
          listener.onAdCollapsed(ad);
        }
        break;

      // Rewarded-specific events
      case 'userRewarded':
        if (listener is CloudXRewardedInterstitialListener) {
          listener.onUserRewarded(ad);
        }
        break;
    }
  }
}
