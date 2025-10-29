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
  bool _isAutoRefreshEnabled = true;
  final _bannerController = CloudXAdViewController();

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
        const SizedBox(height: 16),
        _buildAutoRefreshControls(),
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
          } else {
            setAdState(AdState.loading);
          }
        },
        child: Text(_showBanner ? 'Stop' : 'Load / Show'),
      ),
    );
  }

  Widget _buildAutoRefreshControls() {
    if (!_showBanner || !_bannerController.isAttached) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _isAutoRefreshEnabled ? null : _startAutoRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Auto-Refresh'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: !_isAutoRefreshEnabled ? null : _stopAutoRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop Auto-Refresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _startAutoRefresh() async {
    await _bannerController.startAutoRefresh();
    setState(() {
      _isAutoRefreshEnabled = true;
    });
    DemoAppLogger.sharedInstance.logMessage('🔄 Auto-refresh started');
    setCustomStatus(text: 'Auto-refresh started', color: Colors.green);
  }

  Future<void> _stopAutoRefresh() async {
    await _bannerController.stopAutoRefresh();
    setState(() {
      _isAutoRefreshEnabled = false;
    });
    DemoAppLogger.sharedInstance.logMessage('⏸️ Auto-refresh stopped');
    setCustomStatus(text: 'Auto-refresh stopped', color: Colors.orange);
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
        controller: _bannerController,
        listener: CloudXAdViewListener(
          onAdLoaded: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('✅ Banner Loaded', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Banner Ad Loaded', color: Colors.green);
          },
          onAdLoadFailed: (error) {
            DemoAppLogger.sharedInstance.logMessage('❌ Banner Failed: $error');
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
          },
          onAdDisplayed: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('📺 Banner Displayed', ad);
            setCustomStatus(text: 'Banner Ad Displayed', color: Colors.green);
          },
          onAdDisplayFailed: (error) {
            DemoAppLogger.sharedInstance.logMessage('❌ Banner Display Failed: $error');
            setCustomStatus(text: 'Failed to display: $error', color: Colors.red);
          },
          onAdClicked: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👆 Banner Clicked', ad);
            setCustomStatus(text: 'Banner Ad Clicked', color: Colors.blue);
          },
          onAdHidden: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👋 Banner Hidden', ad);
            setCustomStatus(text: 'Banner Ad Hidden', color: Colors.grey);
          },
          onAdExpanded: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('📏 Banner Expanded', ad);
            setCustomStatus(text: 'Banner Ad Expanded', color: Colors.purple);
          },
          onAdCollapsed: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('📐 Banner Collapsed', ad);
            setCustomStatus(text: 'Banner Ad Collapsed', color: Colors.purple);
          },
        ),
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

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }
}
