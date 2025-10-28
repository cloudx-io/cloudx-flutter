import 'package:flutter/foundation.dart';
import '../cloudx.dart';

/// Controller for [CloudXBannerView] that provides programmatic control
/// over banner ad behavior.
///
/// Use this controller to start/stop auto-refresh for a banner ad.
///
/// Example:
/// ```dart
/// final controller = CloudXBannerController();
///
/// CloudXBannerView(
///   placement: 'home_banner',
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
class CloudXBannerController extends ChangeNotifier {
  String? _adId;

  /// Whether the controller is attached to a banner view
  bool get isAttached => _adId != null;

  /// Internal method called by CloudXBannerView to attach the controller.
  /// Do not call this method directly - it is managed automatically by the widget.
  void attach(String adId) {
    _adId = adId;
  }

  /// Internal method called by CloudXBannerView to detach the controller.
  /// Do not call this method directly - it is managed automatically by the widget.
  void detach() {
    _adId = null;
  }

  /// Start auto-refresh for the banner ad.
  ///
  /// Auto-refresh interval is configured server-side in CloudX dashboard.
  /// Throws [StateError] if called before the controller is attached to a banner.
  Future<void> startAutoRefresh() async {
    if (_adId == null) {
      throw StateError(
        'CloudXBannerController is not attached to a banner. '
        'Ensure the controller is passed to CloudXBannerView.',
      );
    }
    await CloudX.startAutoRefresh(adId: _adId!);
  }

  /// Stop auto-refresh for the banner ad.
  ///
  /// Throws [StateError] if called before the controller is attached to a banner.
  Future<void> stopAutoRefresh() async {
    if (_adId == null) {
      throw StateError(
        'CloudXBannerController is not attached to a banner. '
        'Ensure the controller is passed to CloudXBannerView.',
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
