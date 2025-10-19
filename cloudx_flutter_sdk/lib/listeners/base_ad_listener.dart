/// Base ad listener
/// 
/// Provides common callbacks for all ad types following the
/// Interface Segregation Principle (SOLID).
library;

import '../models/clx_ad.dart';

/// Base class for all ad listeners
/// Provides common callbacks for all ad types
abstract class BaseAdListener {
  /// Called when ad is loaded and ready to show
  /// 
  /// [ad] - Ad metadata including placement, bidder, and revenue information
  void Function(CLXAd? ad)? onAdLoaded;

  /// Called when ad fails to load
  /// 
  /// [error] - Error message describing the failure
  /// [ad] - Ad metadata (may be null if ad creation failed early)
  void Function(String error, CLXAd? ad)? onAdFailedToLoad;

  /// Called when ad is shown to the user
  /// 
  /// [ad] - Ad metadata
  void Function(CLXAd? ad)? onAdShown;

  /// Called when ad fails to show
  /// 
  /// [error] - Error message describing the failure
  /// [ad] - Ad metadata
  void Function(String error, CLXAd? ad)? onAdFailedToShow;

  /// Called when ad is hidden or closed
  /// 
  /// [ad] - Ad metadata
  void Function(CLXAd? ad)? onAdHidden;

  /// Called when user clicks on the ad
  /// 
  /// [ad] - Ad metadata
  void Function(CLXAd? ad)? onAdClicked;

  /// Called when ad impression is recorded
  /// 
  /// [ad] - Ad metadata
  void Function(CLXAd? ad)? onAdImpression;

  /// Called when ad is closed by user action (e.g., close button)
  /// 
  /// [ad] - Ad metadata
  void Function(CLXAd? ad)? onAdClosedByUser;

  /// Called when revenue is paid for the ad
  /// Triggered after NURL is successfully sent to server
  /// 
  /// [ad] - Ad metadata including revenue amount
  void Function(CLXAd? ad)? onRevenuePaid;
}

