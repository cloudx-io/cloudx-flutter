import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cloudx.dart';

/// A Flutter widget that displays a CloudX MREC (Medium Rectangle) ad.
///
/// This widget handles the entire ad lifecycle automatically:
/// - Creates and loads the ad on initialization
/// - Displays the ad using platform views (AndroidView/UiKitView)
/// - Cleans up resources on disposal
///
/// Basic usage:
/// ```dart
/// CloudXMRECView(
///   placement: 'home_mrec',
///   listener: MRECListener()
///     ..onAdLoaded = (ad) => print('MREC loaded'),
/// )
/// ```
///
/// With controller for auto-refresh control:
/// ```dart
/// final controller = CloudXAdViewController();
///
/// CloudXMRECView(
///   placement: 'home_mrec',
///   controller: controller,
/// )
///
/// // Control auto-refresh:
/// controller.startAutoRefresh();
/// controller.stopAutoRefresh();
/// ```
class CloudXMRECView extends StatefulWidget {
  /// The placement name from your CloudX dashboard
  final String placement;

  /// Optional listener for ad lifecycle events
  final MRECListener? listener;

  /// Optional width for the MREC (defaults to 300)
  final double? width;

  /// Optional height for the MREC (defaults to 250)
  final double? height;

  /// Optional controller for programmatic control over the MREC ad.
  /// Use this to start/stop auto-refresh.
  final CloudXAdViewController? controller;

  const CloudXMRECView({
    super.key,
    required this.placement,
    this.listener,
    this.width,
    this.height,
    this.controller,
  });

  @override
  State<CloudXMRECView> createState() => _CloudXMRECViewState();
}

class _CloudXMRECViewState extends State<CloudXMRECView> {
  late String _adId;
  bool _isCreated = false;

  @override
  void initState() {
    super.initState();
    _adId = 'mrec_${widget.placement}_${DateTime.now().millisecondsSinceEpoch}';

    // Attach controller if provided
    widget.controller?.attach(_adId);

    _loadAd();
  }

  Future<void> _loadAd() async {
    try {
      final success = await CloudX.createMREC(
        placement: widget.placement,
        adId: _adId,
        listener: widget.listener,
      );

      if (!success) {
        // Error will be reported via listener callback
        return;
      }

      // Mark as created so the platform view can be shown
      if (mounted) {
        setState(() {
          _isCreated = true;
        });
      }

      await CloudX.loadMREC(adId: _adId);
    } catch (e) {
      // Error will be reported via listener callback
    }
  }

  @override
  void dispose() {
    // Detach controller if provided
    widget.controller?.detach();
    CloudX.destroyAd(adId: _adId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? 300.0;
    final height = widget.height ?? 250.0;

    // Wait until MREC is created before showing the platform view
    if (!_isCreated) {
      return SizedBox(
        width: width,
        height: height,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: _buildPlatformView(),
    );
  }

  Widget _buildPlatformView() {
    final creationParams = {
      'adId': _adId,
    };

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'cloudx_mrec_view',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'cloudx_mrec_view',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Container(
      color: Colors.red,
      child: const Center(
        child: Text('Unsupported platform'),
      ),
    );
  }
}
