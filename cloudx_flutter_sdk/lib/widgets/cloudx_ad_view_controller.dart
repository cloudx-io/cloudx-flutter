import 'package:cloudx_flutter/cloudx.dart';
import 'package:flutter/foundation.dart';

/// Controller for [CloudXBannerView] and [CloudXMRECView] that provides
/// programmatic control over ad view behavior.
///
/// Use this controller to start/stop auto-refresh for banner or MREC ads.
///
/// Example:
/// ```dart
/// final controller = CloudXAdViewController();
///
/// CloudXBannerView(
///   placement: 'home_banner',
///   controller: controller,
/// )
///
/// // Or with MREC:
/// CloudXMRECView(
///   placement: 'home_mrec',
///   controller: controller,
/// )
///
/// // Later, control auto-refresh:
/// controller.startAutoRefresh();
/// controller.stopAutoRefresh();
///
/// // Don't forget to dispose:
/// controller.dispose();
/// ```
class CloudXAdViewController extends ChangeNotifier {
  String? _adId;

  /// Whether the controller is attached to an ad view
  bool get isAttached => _adId != null;

  /// Internal method called by ad view widgets to attach the controller.
  /// Do not call this method directly - it is managed automatically by the widget.
  void attach(String adId) {
    _adId = adId;
  }

  /// Internal method called by ad view widgets to detach the controller.
  /// Do not call this method directly - it is managed automatically by the widget.
  void detach() {
    _adId = null;
  }

  /// Start auto-refresh for the ad.
  ///
  /// Auto-refresh interval is configured server-side in CloudX dashboard.
  /// Throws [StateError] if called before the controller is attached to an ad view.
  Future<void> startAutoRefresh() async {
    if (_adId == null) {
      throw StateError(
        'CloudXAdViewController is not attached to an ad view. '
        'Ensure the controller is passed to CloudXBannerView or CloudXMRECView.',
      );
    }
    await CloudX.startAutoRefresh(adId: _adId!);
  }

  /// Stop auto-refresh for the ad.
  ///
  /// Throws [StateError] if called before the controller is attached to an ad view.
  Future<void> stopAutoRefresh() async {
    if (_adId == null) {
      throw StateError(
        'CloudXAdViewController is not attached to an ad view. '
        'Ensure the controller is passed to CloudXBannerView or CloudXMRECView.',
      );
    }
    await CloudX.stopAutoRefresh(adId: _adId!);
  }

  @override
  void dispose() {
    _adId = null;
    super.dispose();
  }
}
