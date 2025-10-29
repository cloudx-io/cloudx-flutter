/// CloudX ad view listener
library;

import '../models/cloudx_ad.dart';
import 'cloudx_ad_listener.dart';

/// Listener for banner, MREC, and native ad events
///
/// Extends [CloudXAdListener] with expand/collapse callbacks specific to
/// banner-style ads.
///
/// Use this single listener for:
/// - Banner ads (320x50 or adaptive)
/// - MREC ads (300x250)
/// - Native ads
class CloudXAdViewListener extends CloudXAdListener {
  /// Called when ad expands to full screen
  ///
  /// [ad] - Ad metadata
  final void Function(CloudXAd ad) onAdExpanded;

  /// Called when ad collapses from full screen
  ///
  /// [ad] - Ad metadata
  final void Function(CloudXAd ad) onAdCollapsed;

  /// Creates an ad view listener with required callbacks
  ///
  /// This single listener type handles banner, MREC, and native ads.
  const CloudXAdViewListener({
    required super.onAdLoaded,
    required super.onAdLoadFailed,
    required super.onAdDisplayed,
    required super.onAdDisplayFailed,
    required super.onAdClicked,
    required super.onAdHidden,
    required this.onAdExpanded,
    required this.onAdCollapsed,
  });
}
