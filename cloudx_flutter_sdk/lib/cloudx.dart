library cloudx;

import 'dart:async';
import 'package:flutter/services.dart';

/// Custom exception for CloudX SDK errors
class CloudXException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  CloudXException(this.code, this.message, [this.details]);

  @override
  String toString() => 'CloudXException($code): $message';
}

/// The main CloudX Flutter SDK class.
///
/// Provides a comprehensive Flutter wrapper for the CloudX Core Objective-C SDK.
class CloudX {
  static const MethodChannel _channel = MethodChannel('cloudx_flutter_sdk');
  static const EventChannel _eventChannel = EventChannel('cloudx_flutter_sdk_events');

  // Listener storage (SRP: separated by type)
  static final Map<String, BaseAdListener> _listeners = {};

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
  /// [hashedUserID] - Optional hashed user ID for targeting
  ///
  /// Returns `true` if initialization was successful
  /// Throws [CloudXException] if initialization fails
  static Future<bool> initialize({
    required String appKey,
    String? hashedUserID,
  }) async {
    final arguments = <String, dynamic>{
      'appKey': appKey,
      if (hashedUserID != null) 'hashedUserID': hashedUserID,
    };

    try {
      final result = await _invokeMethod<bool>('initSDK', arguments);
      await _ensureEventStreamInitialized();
      return result ?? false;
    } on PlatformException catch (e) {
      throw CloudXException(
        e.code,
        e.message ?? 'Failed to initialize SDK',
        e.details,
      );
    }
  }

  /// Check if the SDK is initialized
  static Future<bool> isInitialized() async {
    try {
      return await _invokeMethod<bool>('isSDKInitialized') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get the SDK version
  static Future<String> getVersion() async {
    try {
      return await _invokeMethod<String>('getSDKVersion') ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get or set the user ID
  static Future<String?> getUserID() async {
    try {
      return await _invokeMethod<String>('getUserID');
    } catch (e) {
      return null;
    }
  }

  /// Set the user ID
  static Future<void> setUserID(String? userID) async {
    await _invokeMethod('setUserID', {'userID': userID});
  }

  /// Get logs data dictionary
  static Future<Map<String, String>> getLogsData() async {
    try {
      final result = await _invokeMethod<Map>('getLogsData');
      return result?.cast<String, String>() ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Track SDK errors for analytics
  static Future<void> trackSDKError(String error) async {
    await _invokeMethod('trackSDKError', {'error': error});
  }

  /// Set the environment (dev, staging, production)
  /// Must be called BEFORE initialize()
  static Future<void> setEnvironment(String environment) async {
    await _invokeMethod('setEnvironment', {'environment': environment});
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
  /// ⚠️ Warning: GDPR is not yet supported by CloudX servers.
  /// Please contact CloudX if you need GDPR support. CCPA is fully supported.
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

  /// Set "do not sell" preference (CCPA)
  ///
  /// Sets the CCPA "do not sell my personal information" flag.
  /// This is converted to CCPA privacy string format internally.
  static Future<void> setIsDoNotSell(bool doNotSell) async {
    await _invokeMethod('setIsDoNotSell', {'isDoNotSell': doNotSell});
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

  /// Provide user details with hashed user ID
  ///
  /// Sets the hashed user ID for ad targeting after initialization.
  /// Can be called multiple times to update the user ID.
  static Future<void> provideUserDetailsWithHashedUserID(String hashedUserID) async {
    await _invokeMethod('provideUserDetails', {'hashedUserID': hashedUserID});
  }

  /// Use hashed key-value pair for targeting
  ///
  /// Sets a single key-value pair for ad targeting.
  /// For multiple pairs, consider using [useKeyValues] for better performance.
  static Future<void> useHashedKeyValue(String key, String value) async {
    await _invokeMethod('useHashedKeyValue', {'key': key, 'value': value});
  }

  /// Use multiple key-value pairs for targeting (batch operation)
  ///
  /// More efficient than calling [useHashedKeyValue] multiple times.
  /// All key-value pairs are sent in a single method channel call.
  static Future<void> useKeyValues(Map<String, String> keyValues) async {
    await _invokeMethod('useKeyValues', {'keyValues': keyValues});
  }

  /// Use bidder-specific key-value pair for targeting
  ///
  /// Sets targeting parameters specific to a particular bidder/ad network.
  static Future<void> useBidderKeyValue(String bidder, String key, String value) async {
    await _invokeMethod('useBidderKeyValue', {
      'bidder': bidder,
      'key': key,
      'value': value,
    });
  }

  // ============================================================================
  // MARK: - Banner Ad Methods
  // ============================================================================

  /// Create a banner ad
  ///
  /// [placement] - The placement name from your CloudX dashboard
  /// [adId] - Unique identifier for this ad instance
  /// [listener] - Optional callback listener for ad events
  /// [tmax] - Optional timeout in milliseconds for bid requests
  static Future<bool> createBanner({
    required String placement,
    required String adId,
    BannerListener? listener,
    int? tmax,
  }) async {
    await _ensureEventStreamInitialized();
    
    final success = await _invokeMethod<bool>('createBanner', {
      'placement': placement,
      'adId': adId,
      if (tmax != null) 'tmax': tmax,
    });

    if (success == true && listener != null) {
      _listeners[adId] = listener;
    }

    return success ?? false;
  }

  /// Load a banner ad
  static Future<bool> loadBanner({required String adId}) async {
    return await _invokeMethod<bool>('loadAd', {'adId': adId}) ?? false;
  }

  /// Show a banner ad
  static Future<bool> showBanner({required String adId}) async {
    return await _invokeMethod<bool>('showAd', {'adId': adId}) ?? false;
  }

  /// Hide a banner ad
  static Future<bool> hideBanner({required String adId}) async {
    return await _invokeMethod<bool>('hideAd', {'adId': adId}) ?? false;
  }

  // ============================================================================
  // MARK: - Interstitial Ad Methods
  // ============================================================================

  /// Create an interstitial ad
  static Future<bool> createInterstitial({
    required String placement,
    required String adId,
    InterstitialListener? listener,
  }) async {
    await _ensureEventStreamInitialized();
    
    final success = await _invokeMethod<bool>('createInterstitial', {
      'placement': placement,
      'adId': adId,
    });

    if (success == true && listener != null) {
      _listeners[adId] = listener;
    }

    return success ?? false;
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

  /// Create a rewarded ad
  static Future<bool> createRewarded({
    required String placement,
    required String adId,
    RewardedListener? listener,
  }) async {
    await _ensureEventStreamInitialized();
    
    final success = await _invokeMethod<bool>('createRewarded', {
      'placement': placement,
      'adId': adId,
    });

    if (success == true && listener != null) {
      _listeners[adId] = listener;
    }

    return success ?? false;
  }

  /// Load a rewarded ad
  static Future<bool> loadRewarded({required String adId}) async {
    return await _invokeMethod<bool>('loadAd', {'adId': adId}) ?? false;
  }

  /// Show a rewarded ad
  static Future<bool> showRewarded({required String adId}) async {
    return await _invokeMethod<bool>('showAd', {'adId': adId}) ?? false;
  }

  /// Check if rewarded ad is ready to show
  static Future<bool> isRewardedReady({required String adId}) async {
    return await _invokeMethod<bool>('isAdReady', {'adId': adId}) ?? false;
  }

  // ============================================================================
  // MARK: - Native Ad Methods
  // ============================================================================

  /// Create a native ad
  static Future<bool> createNative({
    required String placement,
    required String adId,
    NativeListener? listener,
  }) async {
    await _ensureEventStreamInitialized();
    
    final success = await _invokeMethod<bool>('createNative', {
      'placement': placement,
      'adId': adId,
    });

    if (success == true && listener != null) {
      _listeners[adId] = listener;
    }

    return success ?? false;
  }

  /// Load a native ad
  static Future<bool> loadNative({required String adId}) async {
    return await _invokeMethod<bool>('loadAd', {'adId': adId}) ?? false;
  }

  /// Show a native ad
  static Future<bool> showNative({required String adId}) async {
    return await _invokeMethod<bool>('showAd', {'adId': adId}) ?? false;
  }

  /// Check if native ad is ready to show
  static Future<bool> isNativeReady({required String adId}) async {
    return await _invokeMethod<bool>('isAdReady', {'adId': adId}) ?? false;
  }

  // ============================================================================
  // MARK: - MREC Ad Methods
  // ============================================================================

  /// Create an MREC (Medium Rectangle) ad
  static Future<bool> createMREC({
    required String placement,
    required String adId,
    MRECListener? listener,
  }) async {
    await _ensureEventStreamInitialized();
    
    final success = await _invokeMethod<bool>('createMREC', {
      'placement': placement,
      'adId': adId,
    });

    if (success == true && listener != null) {
      _listeners[adId] = listener;
    }

    return success ?? false;
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
  static Future<T?> _invokeMethod<T>(String method, [Map<String, dynamic>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      print('CloudX SDK method "$method" failed: ${e.message}');
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
      print('🔵 [CloudX] Event stream already initialized');
      return;
    }

    print('🔵 [CloudX] Initializing event stream...');
    _eventChannelReadyCompleter = Completer<void>();
    
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        print('🔵 [CloudX] Event received from platform: $event');
        if (event is Map) {
          // Check for ready confirmation
          final eventType = event['event'] as String?;
          if (eventType == '__eventChannelReady__' && _eventChannelReadyCompleter != null && !_eventChannelReadyCompleter!.isCompleted) {
            print('🔵 [CloudX] EventChannel ready confirmation received from native');
            _eventChannelReadyCompleter!.complete();
          } else {
            _handleEvent(event);
          }
        }
      },
      onError: (error) {
        print('CloudX event stream error: $error');
      },
    );

    _eventStreamInitialized = true;
    print('🔵 [CloudX] Event stream subscription created');
    
    // Wait with timeout for the native side to be ready
    // If the completer isn't completed within 500ms, proceed anyway
    try {
      await _eventChannelReadyCompleter!.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          print('⚠️ [CloudX] EventChannel ready timeout - proceeding anyway');
        },
      );
      print('🔵 [CloudX] Event stream fully initialized (confirmed by native)');
    } catch (e) {
      print('⚠️ [CloudX] EventChannel initialization warning: $e');
    } finally {
      _eventChannelReadyCompleter = null;
    }
  }

  /// Centralized event handling (DRY)
  static void _handleEvent(Map<Object?, Object?> event) {
    try {
      print('🔵 [CloudX] _handleEvent called with: $event');
      final adId = event['adId'] as String?;
      final eventType = event['event'] as String?;
      final data = event['data'] as Map<Object?, Object?>?;

      print('🔵 [CloudX] Parsed - adId: $adId, eventType: $eventType, data: $data');

      if (adId == null || eventType == null) {
        print('🔵 [CloudX] ERROR - adId or eventType is null, ignoring event');
        return;
      }

      final listener = _listeners[adId];
      print('🔵 [CloudX] Looking up listener for adId: $adId, found: ${listener != null}');
      print('🔵 [CloudX] All registered listeners: ${_listeners.keys.toList()}');
      
      if (listener == null) {
        print('🔵 [CloudX] ERROR - No listener found for adId: $adId');
        return;
      }

      print('🔵 [CloudX] Dispatching event: $eventType to listener');
      _dispatchEventToListener(listener, eventType, data);
      print('🔵 [CloudX] Event dispatched successfully');
    } catch (e) {
      print('CloudX event handling error: $e');
    }
  }

  /// Dispatch events to appropriate listener callbacks (DRY)
  static void _dispatchEventToListener(BaseAdListener listener, String eventType, Map<Object?, Object?>? data) {
    switch (eventType) {
      case 'didLoad':
        listener.onAdLoaded?.call();
        break;
      case 'failToLoad':
        final error = data?['error'] as String? ?? 'Unknown error';
        listener.onAdFailedToLoad?.call(error);
        break;
      case 'didShow':
        listener.onAdShown?.call();
        break;
      case 'failToShow':
        final error = data?['error'] as String? ?? 'Unknown error';
        listener.onAdFailedToShow?.call(error);
        break;
      case 'didHide':
        listener.onAdHidden?.call();
        break;
      case 'didClick':
        listener.onAdClicked?.call();
        break;
      case 'impression':
        listener.onAdImpression?.call();
        break;
      case 'closedByUserAction':
        listener.onAdClosedByUser?.call();
        break;
      case 'revenuePaid':
        listener.onRevenuePaid?.call();
        break;
      
      // Banner-specific events
      case 'didExpandAd':
        if (listener is BannerListener) {
          listener.onAdExpanded?.call();
        }
        break;
      case 'didCollapseAd':
        if (listener is BannerListener) {
          listener.onAdCollapsed?.call();
        }
        break;

      // Rewarded-specific events
      case 'userRewarded':
        if (listener is RewardedListener) {
          listener.onRewarded?.call();
        }
        break;
      case 'rewardedVideoStarted':
        if (listener is RewardedListener) {
          listener.onRewardedVideoStarted?.call();
        }
        break;
      case 'rewardedVideoCompleted':
        if (listener is RewardedListener) {
          listener.onRewardedVideoCompleted?.call();
        }
        break;
    }
  }
}

// ==============================================================================
// MARK: - Listener Classes (SOLID: Interface Segregation Principle)
// ==============================================================================

/// Base class for all ad listeners
/// Provides common callbacks for all ad types
abstract class BaseAdListener {
  /// Called when ad is loaded and ready to show
  void Function()? onAdLoaded;

  /// Called when ad fails to load
  /// [error] - Error message describing the failure
  void Function(String error)? onAdFailedToLoad;

  /// Called when ad is shown to the user
  void Function()? onAdShown;

  /// Called when ad fails to show
  /// [error] - Error message describing the failure
  void Function(String error)? onAdFailedToShow;

  /// Called when ad is hidden or closed
  void Function()? onAdHidden;

  /// Called when user clicks on the ad
  void Function()? onAdClicked;

  /// Called when ad impression is recorded
  void Function()? onAdImpression;

  /// Called when ad is closed by user action (e.g., close button)
  void Function()? onAdClosedByUser;

  /// Called when revenue is paid for the ad
  /// Triggered after NURL is successfully sent to server
  void Function()? onRevenuePaid;
}

/// Listener for banner ad events
/// Extends [BaseAdListener] with banner-specific callbacks
class BannerListener extends BaseAdListener {
  /// Called when banner ad expands (e.g., MRAID expand)
  void Function()? onAdExpanded;

  /// Called when banner ad collapses back to original size
  void Function()? onAdCollapsed;
}

/// Listener for interstitial ad events
/// Uses only the base callbacks from [BaseAdListener]
class InterstitialListener extends BaseAdListener {}

/// Listener for rewarded ad events
/// Extends [BaseAdListener] with rewarded-specific callbacks
class RewardedListener extends BaseAdListener {
  /// Called when user is rewarded
  ///
  /// Note: The iOS SDK doesn't provide reward type/amount in the callback.
  /// Reward details should be managed on your backend.
  void Function()? onRewarded;

  /// Called when rewarded video starts playing
  void Function()? onRewardedVideoStarted;

  /// Called when rewarded video completes playback
  void Function()? onRewardedVideoCompleted;
}

/// Listener for native ad events
/// Uses only the base callbacks from [BaseAdListener]
class NativeListener extends BaseAdListener {}

/// Listener for MREC ad events
/// Uses only the base callbacks from [BaseAdListener]
class MRECListener extends BaseAdListener {}