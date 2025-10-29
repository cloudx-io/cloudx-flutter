/// CloudX rewarded interstitial ad listener
library;

import '../models/cloudx_ad.dart';
import 'cloudx_ad_listener.dart';

/// Listener for rewarded interstitial ad events
///
/// Extends [CloudXAdListener] with rewarded-specific callback for reward grant.
class CloudXRewardedInterstitialListener extends CloudXAdListener {
  /// Called when user is rewarded
  ///
  /// Note: The native SDKs don't provide reward type/amount in the callback.
  /// Reward details should be managed on your backend for security.
  ///
  /// [ad] - Ad metadata including revenue information
  final void Function(CloudXAd ad) onUserRewarded;

  /// Creates a rewarded interstitial ad listener with required callbacks
  const CloudXRewardedInterstitialListener({
    required super.onAdLoaded,
    required super.onAdLoadFailed,
    required super.onAdDisplayed,
    required super.onAdDisplayFailed,
    required super.onAdClicked,
    required super.onAdHidden,
    required this.onUserRewarded,
  });
}
