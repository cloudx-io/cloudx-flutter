library cloudx;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// The main CloudX Flutter SDK class.
/// 
/// Provides a comprehensive Flutter wrapper for the CloudX Core Objective-C SDK.
class CloudX {
  static const MethodChannel _channel = MethodChannel('cloudx_flutter_sdk');
  static const EventChannel _eventChannel = EventChannel('cloudx_flutter_sdk_events');

  /// Flutter plugin registration (required for some plugin registration scenarios)
  static void registerWith() {}

  /// Initialize the CloudX SDK
  /// 
  /// [appKey] - Your CloudX app key
  /// [hashedUserID] - Optional hashed user ID for targeting
  /// 
  /// Returns `true` if initialization was successful
  static Future<bool> initialize({
    required String appKey,
    String? hashedUserID,
  }) async {
    print('CloudX Flutter SDK: Starting initialization...');
    print('CloudX Flutter SDK: AppKey: $appKey');
    print('CloudX Flutter SDK: HashedUserID: $hashedUserID');
    
    // Ensure event stream is initialized
    _ensureInitialized();
    
    try {
      final arguments = {
        'appKey': appKey,
        if (hashedUserID != null) 'hashedUserID': hashedUserID,
      };
      
      print('CloudX Flutter SDK: Calling native initSDK with arguments: $arguments');
      print('CloudX Flutter SDK: Method channel: $_channel');
      
      // Check environment variables on Flutter side
      final envVars = Platform.environment;
      print('CloudX Flutter SDK: CLOUDX_VERBOSE_LOG = ${envVars['CLOUDX_VERBOSE_LOG']}');
      print('CloudX Flutter SDK: CLOUDX_FLUTTER_VERBOSE_LOG = ${envVars['CLOUDX_FLUTTER_VERBOSE_LOG']}');
      print('CloudX Flutter SDK: All environment variables: $envVars');
      
      // Test if the method channel is working at all
      print('CloudX Flutter SDK: Testing method channel...');
      try {
        final testResult = await _channel.invokeMethod('testMethod');
        print('CloudX Flutter SDK: Test method returned: $testResult');
      } catch (e) {
        print('CloudX Flutter SDK: Test method failed (expected): $e');
      }
      
      final result = await _channel.invokeMethod('initSDK', arguments);
      print('CloudX Flutter SDK: Native initSDK returned: $result (type: ${result.runtimeType})');
      
      // Add a small delay to see if there are any async callbacks
      await Future.delayed(Duration(milliseconds: 100));
      print('CloudX Flutter SDK: Initialization completed');
      
      return result;
    } on PlatformException catch (e) {
      print('CloudX Flutter SDK: PlatformException during initialization:');
      print('CloudX Flutter SDK: Code: ${e.code}');
      print('CloudX Flutter SDK: Message: ${e.message}');
      print('CloudX Flutter SDK: Details: ${e.details}');
      return false;
    } catch (e) {
      print('CloudX Flutter SDK: Unexpected error during initialization: $e');
      print('CloudX Flutter SDK: Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Check if the SDK is initialized
  static Future<bool> isInitialized() async {
    try {
      return await _channel.invokeMethod('isSDKInitialized');
    } on PlatformException catch (e) {
      print('CloudX SDK status check failed: ${e.message}');
      return false;
    }
  }

  /// Get the SDK version
  static Future<String> getVersion() async {
    try {
      return await _channel.invokeMethod('getSDKVersion');
    } on PlatformException catch (e) {
      print('CloudX SDK version check failed: ${e.message}');
      return 'Unknown';
    }
  }

  // Banner Ad Methods

  /// Create a banner ad
  /// 
  /// [placement] - The placement name from your CloudX dashboard
  /// [adId] - Unique identifier for this ad instance
  /// [listener] - Callback listener for ad events
  static Future<bool> createBanner({
    required String placement,
    required String adId,
    double? width,
    double? height,
  }) async {
    print('[CloudX Flutter SDK] createBanner called with adId: $adId, placement: $placement, width: $width, height: $height');
    final result = await _channel.invokeMethod('createBanner', {
      'adId': adId,
      'placement': placement,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
    print('[CloudX Flutter SDK] createBanner result: $result');
    return result == true;
  }

  /// Load a banner ad
  /// 
  /// [adId] - The unique identifier of the ad to load
  static Future<bool> loadBanner({required String adId}) async {
    try {
      return await _channel.invokeMethod('loadAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX banner load failed: ${e.message}');
      return false;
    }
  }

  /// Show a banner ad
  /// 
  /// [adId] - The unique identifier of the ad to show
  static Future<bool> showBanner({required String adId}) async {
    try {
      return await _channel.invokeMethod('showAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX banner show failed: ${e.message}');
      return false;
    }
  }

  /// Hide a banner ad
  /// 
  /// [adId] - The unique identifier of the ad to hide
  static Future<bool> hideBanner({required String adId}) async {
    try {
      return await _channel.invokeMethod('hideAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX banner hide failed: ${e.message}');
      return false;
    }
  }

  // Interstitial Ad Methods

  /// Create an interstitial ad
  /// 
  /// [placement] - The placement name from your CloudX dashboard
  /// [adId] - Unique identifier for this ad instance
  /// [listener] - Callback listener for ad events
  static Future<bool> createInterstitial({
    required String placement,
    required String adId,
    InterstitialListener? listener,
  }) async {
    try {
      print('🔍 [Flutter SDK] createInterstitial START - placement: $placement, adId: $adId');
      
      final arguments = {
        'placement': placement,
        'adId': adId,
      };
      
      print('🔍 [Flutter SDK] createInterstitial - About to call _channel.invokeMethod with arguments: $arguments');
      
      final success = await _channel.invokeMethod('createInterstitial', arguments);
      
      print('🔍 [Flutter SDK] createInterstitial - _channel.invokeMethod returned: $success (type: ${success.runtimeType})');
      
      if (success && listener != null) {
        print('🔍 [Flutter SDK] createInterstitial - Setting listener for adId: $adId');
        _setInterstitialListener(adId, listener);
      }
      
      print('🔍 [Flutter SDK] createInterstitial END - returning: $success');
      return success;
    } on PlatformException catch (e) {
      print('🔍 [Flutter SDK] createInterstitial ERROR - PlatformException: ${e.message}');
      print('CloudX interstitial creation failed: ${e.message}');
      return false;
    } catch (e) {
      print('🔍 [Flutter SDK] createInterstitial ERROR - Unexpected error: $e');
      return false;
    }
  }

  /// Load an interstitial ad
  /// 
  /// [adId] - The unique identifier of the ad to load
  static Future<bool> loadInterstitial({required String adId}) async {
    try {
      return await _channel.invokeMethod('loadAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX interstitial load failed: ${e.message}');
      return false;
    }
  }

  /// Show an interstitial ad
  /// 
  /// [adId] - The unique identifier of the ad to show
  static Future<bool> showInterstitial({required String adId}) async {
    try {
      return await _channel.invokeMethod('showAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX interstitial show failed: ${e.message}');
      return false;
    }
  }

  /// Check if interstitial is ready to show
  /// 
  /// [adId] - The unique identifier of the ad to check
  static Future<bool> isInterstitialReady({required String adId}) async {
    try {
      return await _channel.invokeMethod('isAdReady', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX interstitial ready check failed: ${e.message}');
      return false;
    }
  }

  // Rewarded Ad Methods

  /// Create a rewarded ad
  /// 
  /// [placement] - The placement name from your CloudX dashboard
  /// [adId] - Unique identifier for this ad instance
  /// [listener] - Callback listener for ad events
  static Future<bool> createRewarded({
    required String placement,
    required String adId,
    RewardedListener? listener,
  }) async {
    try {
      final arguments = {
        'placement': placement,
        'adId': adId,
      };
      
      final success = await _channel.invokeMethod('createRewarded', arguments);
      if (success && listener != null) {
        _setRewardedListener(adId, listener);
      }
      return success;
    } on PlatformException catch (e) {
      print('CloudX rewarded creation failed: ${e.message}');
      return false;
    }
  }

  /// Load a rewarded ad
  /// 
  /// [adId] - The unique identifier of the ad to load
  static Future<bool> loadRewarded({required String adId}) async {
    try {
      return await _channel.invokeMethod('loadAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX rewarded load failed: ${e.message}');
      return false;
    }
  }

  /// Show a rewarded ad
  /// 
  /// [adId] - The unique identifier of the ad to show
  static Future<bool> showRewarded({required String adId}) async {
    try {
      return await _channel.invokeMethod('showAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX rewarded show failed: ${e.message}');
      return false;
    }
  }

  /// Check if rewarded ad is ready to show
  /// 
  /// [adId] - The unique identifier of the ad to check
  static Future<bool> isRewardedReady({required String adId}) async {
    try {
      return await _channel.invokeMethod('isAdReady', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX rewarded ready check failed: ${e.message}');
      return false;
    }
  }

  // Native Ad Methods

  /// Create a native ad
  /// 
  /// [placement] - The placement name from your CloudX dashboard
  /// [adId] - Unique identifier for this ad instance
  /// [listener] - Callback listener for ad events
  static Future<bool> createNative({
    required String placement,
    required String adId,
    NativeListener? listener,
  }) async {
    try {
      final arguments = {
        'placement': placement,
        'adId': adId,
      };
      
      final success = await _channel.invokeMethod('createNative', arguments);
      if (success && listener != null) {
        _setNativeListener(adId, listener);
      }
      return success;
    } on PlatformException catch (e) {
      print('CloudX native creation failed: ${e.message}');
      return false;
    }
  }

  /// Load a native ad
  /// 
  /// [adId] - The unique identifier of the ad to load
  static Future<bool> loadNative({required String adId}) async {
    try {
      return await _channel.invokeMethod('loadAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX native load failed: ${e.message}');
      return false;
    }
  }

  /// Show a native ad
  /// 
  /// [adId] - The unique identifier of the ad to show
  static Future<bool> showNative({required String adId}) async {
    try {
      return await _channel.invokeMethod('showAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX native show failed: ${e.message}');
      return false;
    }
  }

  /// Check if native ad is ready to show
  /// 
  /// [adId] - The unique identifier of the ad to check
  static Future<bool> isNativeReady({required String adId}) async {
    try {
      return await _channel.invokeMethod('isAdReady', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX native ready check failed: ${e.message}');
      return false;
    }
  }

  // MREC Ad Methods

  /// Create an MREC ad
  /// 
  /// [placement] - The placement name from your CloudX dashboard
  /// [adId] - Unique identifier for this ad instance
  /// [listener] - Callback listener for ad events
  static Future<bool> createMREC({
    required String placement,
    required String adId,
    MRECListener? listener,
  }) async {
    try {
      final arguments = {
        'placement': placement,
        'adId': adId,
      };
      
      final success = await _channel.invokeMethod('createMREC', arguments);
      if (success && listener != null) {
        _setMRECListener(adId, listener);
      }
      return success;
    } on PlatformException catch (e) {
      print('CloudX MREC creation failed: ${e.message}');
      return false;
    }
  }

  /// Load an MREC ad
  /// 
  /// [adId] - The unique identifier of the ad to load
  static Future<bool> loadMREC({required String adId}) async {
    try {
      return await _channel.invokeMethod('loadAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX MREC load failed: ${e.message}');
      return false;
    }
  }

  /// Show an MREC ad
  /// 
  /// [adId] - The unique identifier of the ad to show
  static Future<bool> showMREC({required String adId}) async {
    try {
      return await _channel.invokeMethod('showAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX MREC show failed: ${e.message}');
      return false;
    }
  }

  /// Check if MREC ad is ready to show
  /// 
  /// [adId] - The unique identifier of the ad to check
  static Future<bool> isMRECReady({required String adId}) async {
    try {
      return await _channel.invokeMethod('isAdReady', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX MREC ready check failed: ${e.message}');
      return false;
    }
  }

  // Generic Ad Methods

  /// Destroy an ad
  /// 
  /// [adId] - The unique identifier of the ad to destroy
  static Future<bool> destroyAd({required String adId}) async {
    try {
      return await _channel.invokeMethod('destroyAd', {'adId': adId});
    } on PlatformException catch (e) {
      print('CloudX ad destroy failed: ${e.message}');
      return false;
    }
  }

  // Listener Management

  static final Map<String, BannerListener> _bannerListeners = {};
  static final Map<String, InterstitialListener> _interstitialListeners = {};
  static final Map<String, RewardedListener> _rewardedListeners = {};
  static final Map<String, NativeListener> _nativeListeners = {};
  static final Map<String, MRECListener> _mrecListeners = {};

  static void _setBannerListener(String adId, BannerListener listener) {
    _bannerListeners[adId] = listener;
  }

  static void _setInterstitialListener(String adId, InterstitialListener listener) {
    _interstitialListeners[adId] = listener;
  }

  static void _setRewardedListener(String adId, RewardedListener listener) {
    _rewardedListeners[adId] = listener;
  }

  static void _setNativeListener(String adId, NativeListener listener) {
    _nativeListeners[adId] = listener;
  }

  static void _setMRECListener(String adId, MRECListener listener) {
    _mrecListeners[adId] = listener;
  }

  static void _removeListener(String adId) {
    _bannerListeners.remove(adId);
    _interstitialListeners.remove(adId);
    _rewardedListeners.remove(adId);
    _nativeListeners.remove(adId);
    _mrecListeners.remove(adId);
  }

  // Event Handling

  static void _handleEvent(Map<Object?, Object?> event) {
    print('🔍 [Flutter SDK] _handleEvent START - event: $event');
    
    try {
      final adId = event['adId'] as String?;
      final eventType = event['event'] as String?;
      final eventData = event['data'] as Map<Object?, Object?>?;
      
      print('🔍 [Flutter SDK] _handleEvent - parsed adId: $adId, eventType: $eventType, eventData: $eventData');
      
      if (adId == null || eventType == null) {
        print('🔍 [Flutter SDK] _handleEvent ERROR - adId or eventType is null');
        return;
      }
      
      print('🔍 [Flutter SDK] _handleEvent - Looking for listener for adId: $adId');
      
      // Check all listener types for the adId
      BannerListener? bannerListener = _bannerListeners[adId];
      InterstitialListener? interstitialListener = _interstitialListeners[adId];
      RewardedListener? rewardedListener = _rewardedListeners[adId];
      NativeListener? nativeListener = _nativeListeners[adId];
      MRECListener? mrecListener = _mrecListeners[adId];
      
      // Find the first available listener
      dynamic listener;
      if (bannerListener != null) {
        listener = bannerListener;
      } else if (interstitialListener != null) {
        listener = interstitialListener;
      } else if (rewardedListener != null) {
        listener = rewardedListener;
      } else if (nativeListener != null) {
        listener = nativeListener;
      } else if (mrecListener != null) {
        listener = mrecListener;
      }
      
      if (listener == null) {
        print('🔍 [Flutter SDK] _handleEvent ERROR - No listener found for adId: $adId');
        print('🔍 [Flutter SDK] _handleEvent - Available banner listeners: ${_bannerListeners.keys}');
        print('🔍 [Flutter SDK] _handleEvent - Available interstitial listeners: ${_interstitialListeners.keys}');
        print('🔍 [Flutter SDK] _handleEvent - Available rewarded listeners: ${_rewardedListeners.keys}');
        print('🔍 [Flutter SDK] _handleEvent - Available native listeners: ${_nativeListeners.keys}');
        print('🔍 [Flutter SDK] _handleEvent - Available mrec listeners: ${_mrecListeners.keys}');
        return;
      }
      
      print('🔍 [Flutter SDK] _handleEvent - Found listener, calling appropriate callback for eventType: $eventType');
      
      switch (eventType) {
        case 'didLoad':
          print('🔍 [Flutter SDK] _handleEvent - Calling onAdLoaded for adId: $adId');
          if (listener is BannerListener) {
            listener.onAdLoaded?.call(adId);
          } else {
            listener.onAdLoaded?.call();
          }
          break;
        case 'failToLoad':
          final error = eventData?['error'] as String? ?? 'Unknown error';
          print('🔍 [Flutter SDK] _handleEvent - Calling onAdFailedToLoad for adId: $adId with error: $error');
          listener.onAdFailedToLoad?.call(adId, error);
          break;
        case 'didShow':
          print('🔍 [Flutter SDK] _handleEvent - Calling onAdShown for adId: $adId');
          if (listener is BannerListener) {
            listener.onAdShown?.call(adId);
          } else {
            listener.onAdShown?.call();
          }
          break;
        case 'failToShow':
          final error = eventData?['error'] as String? ?? 'Unknown error';
          print('🔍 [Flutter SDK] _handleEvent - Calling onAdFailedToShow for adId: $adId with error: $error');
          listener.onAdFailedToShow?.call(adId, error);
          break;
        case 'didHide':
          print('🔍 [Flutter SDK] _handleEvent - Calling onAdHidden for adId: $adId');
          listener.onAdHidden?.call();
          break;
        case 'didClick':
          print('🔍 [Flutter SDK] _handleEvent - Calling onAdClicked for adId: $adId');
          if (listener is BannerListener) {
            listener.onAdClicked?.call(adId);
          } else {
            listener.onAdClicked?.call();
          }
          break;
        case 'impression':
          print('🔍 [Flutter SDK] _handleEvent - Calling onAdImpression for adId: $adId');
          if (listener is BannerListener) {
            listener.onAdImpression?.call(adId);
          } else {
            listener.onAdImpression?.call();
          }
          break;
        case 'closedByUserAction':
          print('🔍 [Flutter SDK] _handleEvent - Calling onAdClosedByUser for adId: $adId');
          listener.onAdClosedByUser?.call();
          break;
        case 'userRewarded':
          if (listener is RewardedListener) {
            final rewardType = eventData?['rewardType'] as String? ?? 'unknown';
            final rewardAmount = eventData?['rewardAmount'] as int? ?? 0;
            print('🔍 [Flutter SDK] _handleEvent - Calling onRewarded for adId: $adId with rewardType: $rewardType, rewardAmount: $rewardAmount');
            listener.onRewarded?.call(rewardType, rewardAmount);
          }
          break;
        case 'rewardedVideoStarted':
          if (listener is RewardedListener) {
            print('🔍 [Flutter SDK] _handleEvent - Calling onRewardedVideoStarted for adId: $adId');
            listener.onRewardedVideoStarted?.call();
          }
          break;
        case 'rewardedVideoCompleted':
          if (listener is RewardedListener) {
            print('🔍 [Flutter SDK] _handleEvent - Calling onRewardedVideoCompleted for adId: $adId');
            listener.onRewardedVideoCompleted?.call();
          }
          break;
        default:
          print('🔍 [Flutter SDK] _handleEvent WARNING - Unknown eventType: $eventType');
      }
      
      print('🔍 [Flutter SDK] _handleEvent - Callback completed for eventType: $eventType');
      
    } catch (e, stackTrace) {
      print('🔍 [Flutter SDK] _handleEvent ERROR - Exception: $e');
      print('🔍 [Flutter SDK] _handleEvent ERROR - Stack trace: $stackTrace');
    }
    
    print('🔍 [Flutter SDK] _handleEvent END');
  }

  // Initialize event stream
  static StreamSubscription? _eventSubscription;

  static void _initializeEventStream() {
    if (_eventSubscription != null) return;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      print('🔵 [Flutter SDK] Received event: $event (type: ${event.runtimeType})');
      
      if (event is Map) {
        _handleEvent(event);
      } else {
        print('🔵 [Flutter SDK] Event is not a Map: $event');
      }
    });
  }

  // Initialize event handling when the class is first used
  static bool _initialized = false;
  
  static void _ensureInitialized() {
    if (!_initialized) {
      _initializeEventStream();
      _initialized = true;
    }
  }



  /// Set a banner listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  /// [listener] - The listener to receive events
  static void setBannerListener(String adId, BannerListener listener) {
    _ensureInitialized();
    _setBannerListener(adId, listener);
  }

  /// Remove a banner listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  static void removeBannerListener(String adId) {
    _ensureInitialized();
    _removeListener(adId);
  }

  /// Set an interstitial listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  /// [listener] - The listener to receive events
  static void setInterstitialListener(String adId, InterstitialListener listener) {
    _ensureInitialized();
    _setInterstitialListener(adId, listener);
  }

  /// Remove an interstitial listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  static void removeInterstitialListener(String adId) {
    _ensureInitialized();
    _removeListener(adId);
  }

  /// Set a rewarded listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  /// [listener] - The listener to receive events
  static void setRewardedListener(String adId, RewardedListener listener) {
    _ensureInitialized();
    _setRewardedListener(adId, listener);
  }

  /// Remove a rewarded listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  static void removeRewardedListener(String adId) {
    _ensureInitialized();
    _removeListener(adId);
  }

  /// Set a native listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  /// [listener] - The listener to receive events
  static void setNativeListener(String adId, NativeListener listener) {
    _ensureInitialized();
    _setNativeListener(adId, listener);
  }

  /// Remove a native listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  static void removeNativeListener(String adId) {
    _ensureInitialized();
    _removeListener(adId);
  }

  /// Set an MREC listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  /// [listener] - The listener to receive events
  static void setMRECListener(String adId, MRECListener listener) {
    _ensureInitialized();
    _setMRECListener(adId, listener);
  }

  /// Remove an MREC listener for a specific ad
  /// 
  /// [adId] - The unique identifier of the ad
  static void removeMRECListener(String adId) {
    _ensureInitialized();
    _removeListener(adId);
  }
}

// Listener Classes

/// Listener for banner ad events
class BannerListener {
  Function(String)? onAdLoaded;
  Function(String, String)? onAdFailedToLoad;
  Function(String)? onAdShown;
  Function(String, String)? onAdFailedToShow;
  VoidCallback? onAdHidden;
  Function(String)? onAdClicked;
  Function(String)? onAdImpression;
  VoidCallback? onAdClosedByUser;
}

/// Listener for interstitial ad events
class InterstitialListener {
  VoidCallback? onAdLoaded;
  Function(String, String)? onAdFailedToLoad;
  VoidCallback? onAdShown;
  Function(String, String)? onAdFailedToShow;
  VoidCallback? onAdHidden;
  VoidCallback? onAdClicked;
  VoidCallback? onAdImpression;
  VoidCallback? onAdClosedByUser;
}

/// Listener for rewarded ad events
class RewardedListener {
  VoidCallback? onAdLoaded;
  Function(String, String)? onAdFailedToLoad;
  VoidCallback? onAdShown;
  Function(String, String)? onAdFailedToShow;
  VoidCallback? onAdHidden;
  VoidCallback? onAdClicked;
  VoidCallback? onAdImpression;
  VoidCallback? onAdClosedByUser;
  Function(String, int)? onRewarded;
  VoidCallback? onRewardedVideoStarted;
  VoidCallback? onRewardedVideoCompleted;
}

/// Listener for native ad events
class NativeListener {
  VoidCallback? onAdLoaded;
  Function(String, String)? onAdFailedToLoad;
  VoidCallback? onAdShown;
  Function(String, String)? onAdFailedToShow;
  VoidCallback? onAdHidden;
  VoidCallback? onAdClicked;
  VoidCallback? onAdImpression;
  VoidCallback? onAdClosedByUser;
}

/// Listener for MREC ad events
class MRECListener {
  VoidCallback? onAdLoaded;
  Function(String, String)? onAdFailedToLoad;
  VoidCallback? onAdShown;
  Function(String, String)? onAdFailedToShow;
  VoidCallback? onAdHidden;
  VoidCallback? onAdClicked;
  Function(String, String)? onAdImpression;
  VoidCallback? onAdClosedByUser;
} 