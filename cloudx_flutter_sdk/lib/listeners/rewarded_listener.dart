/// Rewarded ad listener
library;

import '../models/cloudx_ad.dart';
import 'base_ad_listener.dart';

/// Listener for rewarded ad events
/// Extends [BaseAdListener] with rewarded-specific callbacks
class RewardedListener extends BaseAdListener {
  /// Called when user is rewarded
  ///
  /// Note: The native SDKs don't provide reward type/amount in the callback.
  /// Reward details should be managed on your backend for security.
  /// 
  /// [ad] - Ad metadata including revenue information
  void Function(CloudXAd? ad)? onRewarded;

  /// Called when rewarded video starts playing
  /// 
  /// [ad] - Ad metadata
  void Function(CloudXAd? ad)? onRewardedVideoStarted;

  /// Called when rewarded video completes playback
  /// 
  /// [ad] - Ad metadata
  void Function(CloudXAd? ad)? onRewardedVideoCompleted;
}

