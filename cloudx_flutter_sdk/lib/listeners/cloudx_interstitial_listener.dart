/// CloudX interstitial ad listener
library;

import 'cloudx_ad_listener.dart';

/// Listener for interstitial ad events
///
/// Uses only the core callbacks from [CloudXAdListener] without additional
/// interstitial-specific callbacks.
class CloudXInterstitialListener extends CloudXAdListener {
  /// Creates an interstitial ad listener with required callbacks
  const CloudXInterstitialListener({
    required super.onAdLoaded,
    required super.onAdLoadFailed,
    required super.onAdDisplayed,
    required super.onAdDisplayFailed,
    required super.onAdClicked,
    required super.onAdHidden,
  });
}
