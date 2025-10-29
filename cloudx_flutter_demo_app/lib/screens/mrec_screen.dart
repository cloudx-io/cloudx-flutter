import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';
import '../utils/demo_app_logger.dart';

/// MREC (Medium Rectangle) Ad Screen
///
/// Demonstrates CloudXMRECView widget with auto-refresh controls.
class MRECScreen extends BaseAdScreen {
  final DemoEnvironmentConfig environment;

  const MRECScreen({
    super.key,
    required super.isSDKInitialized,
    required this.environment,
  });

  @override
  State<MRECScreen> createState() => _MRECScreenState();
}

class _MRECScreenState extends BaseAdScreenState<MRECScreen> with AutomaticKeepAliveClientMixin {
  bool _showMREC = false;
  bool _isAutoRefreshEnabled = true;
  final _mrecController = CloudXAdViewController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'mrec';

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
        _buildMRECContainer(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _showMREC = !_showMREC;
          });
          if (!_showMREC) {
            setAdState(AdState.noAd);
            setCustomStatus(text: 'MREC stopped', color: Colors.grey);
          } else {
            setAdState(AdState.loading);
          }
        },
        child: Text(_showMREC ? 'Stop' : 'Load / Show'),
      ),
    );
  }

  Widget _buildAutoRefreshControls() {
    if (!_showMREC || !_mrecController.isAttached) {
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
    await _mrecController.startAutoRefresh();
    setState(() {
      _isAutoRefreshEnabled = true;
    });
    DemoAppLogger.sharedInstance.logMessage('🔄 Auto-refresh started');
    setCustomStatus(text: 'Auto-refresh started', color: Colors.green);
  }

  Future<void> _stopAutoRefresh() async {
    await _mrecController.stopAutoRefresh();
    setState(() {
      _isAutoRefreshEnabled = false;
    });
    DemoAppLogger.sharedInstance.logMessage('⏸️ Auto-refresh stopped');
    setCustomStatus(text: 'Auto-refresh stopped', color: Colors.orange);
  }

  Widget _buildMRECContainer() {
    if (!_showMREC) {
      return Container(
        height: 250,
        color: Colors.grey[200],
        child: const Center(
          child: Text(
            'MREC will appear here when loaded',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Center(
      child: CloudXMRECView(
        placement: widget.environment.mrecPlacement,
        width: 300,
        height: 250,
        controller: _mrecController,
        listener: CloudXAdViewListener(
          onAdLoaded: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('✅ MREC Loaded', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'MREC Ad Loaded', color: Colors.green);
          },
          onAdLoadFailed: (error) {
            DemoAppLogger.sharedInstance.logMessage('❌ MREC Failed: $error');
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
          },
          onAdDisplayed: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('📺 MREC Displayed', ad);
            setCustomStatus(text: 'MREC Ad Displayed', color: Colors.green);
          },
          onAdDisplayFailed: (error) {
            DemoAppLogger.sharedInstance.logMessage('❌ MREC Display Failed: $error');
            setCustomStatus(text: 'Failed to display: $error', color: Colors.red);
          },
          onAdClicked: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👆 MREC Clicked', ad);
            setCustomStatus(text: 'MREC Ad Clicked', color: Colors.blue);
          },
          onAdHidden: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👋 MREC Hidden', ad);
            setCustomStatus(text: 'MREC Ad Hidden', color: Colors.grey);
          },
          onAdExpanded: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('📏 MREC Expanded', ad);
            setCustomStatus(text: 'MREC Ad Expanded', color: Colors.purple);
          },
          onAdCollapsed: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('📐 MREC Collapsed', ad);
            setCustomStatus(text: 'MREC Ad Collapsed', color: Colors.purple);
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
    _mrecController.dispose();
    super.dispose();
  }
}

