import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';
import '../utils/demo_app_logger.dart';

class InterstitialScreen extends BaseAdScreen {
  final DemoEnvironmentConfig environment;
  
  const InterstitialScreen({
    super.key,
    required super.isSDKInitialized,
    required this.environment,
  });

  @override
  State<InterstitialScreen> createState() => _InterstitialScreenState();
}

class _InterstitialScreenState extends BaseAdScreenState<InterstitialScreen> with AutomaticKeepAliveClientMixin {
  String? _currentAdId;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'interstitial';

  void _log(String message) {
    debugPrint('🟡 INTERSTITIAL: $message');
  }

  @override
  Widget buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _buildLoadShowButton(),
        const Spacer(),
        _buildInfoContainer(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadShowButton() {
    return Center(
      child: ElevatedButton(
        onPressed: isLoading ? null : _loadOrShowInterstitial,
        child: Text(isLoading ? 'Loading...' : 'Load / Show Interstitial'),
      ),
    );
  }

  Widget _buildInfoContainer() {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interstitial Ads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '• Full-screen ads that cover the entire app',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '• Shown modally by the native SDK',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            '• No UiKitView needed in Flutter',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _loadOrShowInterstitial() async {
    if (_currentAdId != null) {
      // Check if we have an ad ready to show
      final isReady = await CloudX.isInterstitialReady(adId: _currentAdId!);

      if (isReady) {
        _log('Ad is ready, showing interstitial');
        await showAd();
        return;
      } else {
        _log('Ad exists but not ready, loading new ad');
      }
    }

    // No ad or ad not ready - load a new one
    await loadAd();
  }

  @override
  Future<void> loadAd() async {
    _log('Loading interstitial ad...');
    DemoAppLogger.sharedInstance.logMessage('🔄 Interstitial load initiated');
    setLoadingState(true);
    setCustomStatus(text: 'Loading...', color: Colors.orange);

    try {
      // adId is now auto-generated - no need to create manually!
      _log('Creating interstitial with placement: ${widget.environment.interstitialPlacement}');

      _currentAdId = await CloudX.createInterstitial(
        placement: widget.environment.interstitialPlacement,
        // adId is optional - will be auto-generated as 'interstitial_<placement>_<timestamp>'
        listener: InterstitialListener()
          ..onAdLoaded = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('✅ Interstitial loaded', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Interstitial Ad Loaded - Tap to show', color: Colors.green);
            setLoadingState(false);
          }
          ..onAdFailedToLoad = (error, ad) {
            DemoAppLogger.sharedInstance.logAdEvent('❌ Interstitial failed to load', ad);
            DemoAppLogger.sharedInstance.logMessage('  Error: $error');
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
            setLoadingState(false);
          }
          ..onAdShown = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👀 Interstitial shown', ad);
            setCustomStatus(text: 'Interstitial Ad Shown', color: Colors.green);
          }
          ..onAdFailedToShow = (error, ad) {
            DemoAppLogger.sharedInstance.logAdEvent('❌ Interstitial failed to show', ad);
            DemoAppLogger.sharedInstance.logMessage('  Error: $error');
            setCustomStatus(text: 'Failed to show: $error', color: Colors.red);
          }
          ..onAdHidden = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('🔚 Interstitial hidden', ad);
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Interstitial dismissed', color: Colors.grey);
            _currentAdId = null; // Clear the ad ID since it's been consumed
          }
          ..onAdClicked = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👆 Interstitial clicked', ad);
            setCustomStatus(text: 'Interstitial Ad Clicked', color: Colors.blue);
          },
      );

      if (_currentAdId == null) {
        DemoAppLogger.sharedInstance.logMessage('❌ Failed to create interstitial ad');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to create interstitial ad', color: Colors.red);
        setLoadingState(false);
        return;
      }

      // Load the interstitial
      _log('Calling CloudX.loadInterstitial with adId: $_currentAdId');
      final loadSuccess = await CloudX.loadInterstitial(adId: _currentAdId!);
      _log('CloudX.loadInterstitial returned: $loadSuccess');

      if (!loadSuccess) {
        DemoAppLogger.sharedInstance.logMessage('❌ Failed to load interstitial ad');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load interstitial ad', color: Colors.red);
        setLoadingState(false);
        return;
      }

      _log('loadInterstitial called successfully, waiting for callbacks');
    } catch (e) {
      DemoAppLogger.sharedInstance.logMessage('❌ Error loading interstitial: $e');
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Error loading interstitial: $e', color: Colors.red);
      setLoadingState(false);
    }
  }

  @override
  Future<void> showAd() async {
    if (_currentAdId == null) {
      setCustomStatus(text: 'No adId available for showing interstitial', color: Colors.red);
      return;
    }
    _log('User clicked Show Interstitial - showing ad with adId: $_currentAdId');
    DemoAppLogger.sharedInstance.logMessage('📺 Attempting to show interstitial ad');
    try {
      await CloudX.showInterstitial(adId: _currentAdId!);
      setCustomStatus(text: 'Interstitial Ad Shown', color: Colors.green);
    } catch (e) {
      DemoAppLogger.sharedInstance.logMessage('❌ Error showing interstitial ad: $e');
      setCustomStatus(text: 'Error showing interstitial ad: $e', color: Colors.red);
    }
  }

  @override
  void dispose() {
    if (_currentAdId != null) {
      debugPrint('🟡 INTERSTITIAL: 🗑️ Disposing interstitial ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
    }
    super.dispose();
  }
} 