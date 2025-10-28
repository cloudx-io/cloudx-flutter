import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';
import '../utils/demo_app_logger.dart';

class BannerScreen extends BaseAdScreen {
  final DemoEnvironmentConfig environment;

  const BannerScreen({
    super.key,
    required super.isSDKInitialized,
    required this.environment,
  });

  @override
  State<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends BaseAdScreenState<BannerScreen> with AutomaticKeepAliveClientMixin {
  bool _showBanner = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'banner';

  @override
  Widget buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _buildLoadButton(),
        const Spacer(),
        _buildBannerContainer(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _showBanner = !_showBanner;
          });
          if (!_showBanner) {
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Banner stopped', color: Colors.grey);
          }
        },
        child: Text(_showBanner ? 'Stop' : 'Load / Show'),
      ),
    );
  }

  Widget _buildBannerContainer() {
    if (!_showBanner) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            'Banner will appear here when loaded',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Center(
      child: CloudXBannerView(
        placement: widget.environment.bannerPlacement,
        width: 320,
        height: 50,
        listener: BannerListener()
          ..onAdLoaded = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('✅ Banner Loaded', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Banner Ad Loaded', color: Colors.green);
          }
          ..onAdFailedToLoad = (error, ad) {
            DemoAppLogger.sharedInstance.logMessage('❌ Banner Failed: $error');
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
          }
          ..onAdClicked = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👆 Banner Clicked', ad);
            setCustomStatus(text: 'Banner Ad Clicked', color: Colors.blue);
          }
          ..onAdImpression = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👁️ Banner Impression', ad);
            setCustomStatus(text: 'Banner Ad Impression', color: Colors.green);
          },
      ),
    );
  }

  @override
  Future<void> loadAd() async {
    // Widget handles loading automatically
  }

  @override
  Future<void> showAd() async {
    // Widget handles showing automatically
  }
}
