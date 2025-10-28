import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cloudx.dart';

/// A Flutter widget that displays a CloudX banner ad.
///
/// This widget handles the entire ad lifecycle automatically:
/// - Creates and loads the ad on initialization
/// - Displays the ad using platform views (AndroidView/UiKitView)
/// - Cleans up resources on disposal
///
/// Example:
/// ```dart
/// CloudXBannerView(
///   placement: 'home_banner',
///   listener: BannerListener()
///     ..onAdLoaded = (ad) => print('Banner loaded'),
/// )
/// ```
class CloudXBannerView extends StatefulWidget {
  /// The placement name from your CloudX dashboard
  final String placement;

  /// Optional listener for ad lifecycle events
  final BannerListener? listener;

  /// Optional width for the banner (defaults to 320)
  final double? width;

  /// Optional height for the banner (defaults to 50)
  final double? height;

  const CloudXBannerView({
    super.key,
    required this.placement,
    this.listener,
    this.width,
    this.height,
  });

  @override
  State<CloudXBannerView> createState() => _CloudXBannerViewState();
}

class _CloudXBannerViewState extends State<CloudXBannerView> {
  late String _adId;
  bool _isCreated = false;

  @override
  void initState() {
    super.initState();
    _adId = 'banner_${widget.placement}_${DateTime.now().millisecondsSinceEpoch}';
    _loadAd();
  }

  Future<void> _loadAd() async {
    try {
      final success = await CloudX.createBanner(
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

      await CloudX.loadBanner(adId: _adId);
    } catch (e) {
      // Error will be reported via listener callback
    }
  }

  @override
  void dispose() {
    CloudX.destroyAd(adId: _adId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? 320.0;
    final height = widget.height ?? 50.0;

    // Wait until banner is created before showing the platform view
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
        viewType: 'cloudx_banner_view',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'cloudx_banner_view',
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
