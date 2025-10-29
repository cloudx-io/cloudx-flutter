/// CloudX ad listener
library;

import '../models/cloudx_ad.dart';

/// Base listener for all CloudX ad types
///
/// Provides 6 core ad lifecycle callbacks. All callbacks are required
/// to ensure proper error handling.
abstract class CloudXAdListener {
  /// Called when ad is loaded and ready to show
  ///
  /// [ad] - Ad metadata including placement, bidder, and revenue information
  final void Function(CloudXAd ad) onAdLoaded;

  /// Called when ad fails to load
  ///
  /// [error] - Error message describing the failure
  final void Function(String error) onAdLoadFailed;

  /// Called when ad is displayed to the user
  ///
  /// [ad] - Ad metadata
  final void Function(CloudXAd ad) onAdDisplayed;

  /// Called when ad fails to display
  ///
  /// [error] - Error message describing the failure
  final void Function(String error) onAdDisplayFailed;

  /// Called when user clicks on the ad
  ///
  /// [ad] - Ad metadata
  final void Function(CloudXAd ad) onAdClicked;

  /// Called when ad is hidden or closed
  ///
  /// [ad] - Ad metadata
  final void Function(CloudXAd ad) onAdHidden;

  /// Creates a CloudX ad listener with required core callbacks
  ///
  /// All 6 callbacks are required to ensure developers handle all critical
  /// ad lifecycle events.
  const CloudXAdListener({
    required this.onAdLoaded,
    required this.onAdLoadFailed,
    required this.onAdDisplayed,
    required this.onAdDisplayFailed,
    required this.onAdClicked,
    required this.onAdHidden,
  });
}
