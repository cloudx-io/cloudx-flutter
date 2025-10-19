/// Banner ad listener
library;

import '../models/clx_ad.dart';
import 'base_ad_listener.dart';

/// Listener for banner ad events
/// Extends [BaseAdListener] with banner-specific callbacks
class BannerListener extends BaseAdListener {
  /// Called when banner ad expands (e.g., MRAID expand)
  /// 
  /// [ad] - Ad metadata
  void Function(CLXAd? ad)? onAdExpanded;

  /// Called when banner ad collapses back to original size
  /// 
  /// [ad] - Ad metadata
  void Function(CLXAd? ad)? onAdCollapsed;
}

