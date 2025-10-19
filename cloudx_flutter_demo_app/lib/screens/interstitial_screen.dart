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
  bool _isInterstitialLoaded = false;

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
    print('🟡 INTERSTITIAL: $message');
  }

  @override
  Widget buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _buildLoadButton(),
        const SizedBox(height: 16),
        _buildShowButton(),
        const Spacer(),
        _buildInfoContainer(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isInterstitialLoaded ? null : loadAd,
        child: Text(_isInterstitialLoaded ? 'Interstitial Loaded' : 'Load Interstitial'),
      ),
    );
  }

  Widget _buildShowButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isInterstitialLoaded ? showAd : null,
        child: const Text('Show Interstitial'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interstitial Ads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Full-screen ads that cover the entire app',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            '• Shown modally by the native SDK',
            style: TextStyle(fontSize: 14),
          ),
          const Text(
            '• No UiKitView needed in Flutter',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> loadAd() async {
    _log('User clicked Load Interstitial - starting load...');
    DemoAppLogger.sharedInstance.logMessage('🔄 Interstitial load initiated');
    setLoadingState(true);
    setCustomStatus(text: 'Loading...', color: Colors.orange);
    setState(() {
      _isInterstitialLoaded = false;
    });
    
    try {
      _currentAdId = '${getAdIdPrefix()}_${DateTime.now().millisecondsSinceEpoch}';
      _log('Creating interstitial with adId: $_currentAdId, placement: ${widget.environment.interstitialPlacement}');
      final success = await CloudX.createInterstitial(
        placement: widget.environment.interstitialPlacement,
        adId: _currentAdId!,
        listener: InterstitialListener()
          ..onAdLoaded = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('✅ Interstitial didLoadWithAd', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Interstitial Ad Loaded', color: Colors.green);
            setState(() {
              _isInterstitialLoaded = true;
            });
          }
          ..onAdFailedToLoad = (error, ad) {
            DemoAppLogger.sharedInstance.logAdEvent('❌ Interstitial failToLoadWithAd', ad);
            DemoAppLogger.sharedInstance.logMessage('  Error: $error');
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load interstitial ad: $error', color: Colors.red);
            setState(() {
              _isInterstitialLoaded = false;
            });
          }
          ..onAdShown = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👀 Interstitial didShowWithAd', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Interstitial Ad Shown', color: Colors.green);
          }
          ..onAdFailedToShow = (error, ad) {
            DemoAppLogger.sharedInstance.logAdEvent('❌ Interstitial failToShowWithAd', ad);
            DemoAppLogger.sharedInstance.logMessage('  Error: $error');
            setCustomStatus(text: 'Failed to show interstitial ad: $error', color: Colors.red);
          }
          ..onAdHidden = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('🔚 Interstitial didHideWithAd', ad);
            setAdState(AdState.noAd);
            setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
            setState(() {
              _isInterstitialLoaded = false;
            });
          }
          ..onAdClicked = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👆 Interstitial didClickWithAd', ad);
            setCustomStatus(text: 'Interstitial Ad Clicked', color: Colors.blue);
          },
      );
      if (!success) {
        DemoAppLogger.sharedInstance.logMessage('❌ Failed to create interstitial ad');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to create interstitial ad.', color: Colors.red);
        setState(() {
          _isInterstitialLoaded = false;
        });
        setLoadingState(false);
        return;
      }
      
      // Now load the interstitial (create -> load -> wait for callbacks)
      _log('Calling CloudX.loadInterstitial with adId: $_currentAdId');
      final loadSuccess = await CloudX.loadInterstitial(adId: _currentAdId!);
      _log('CloudX.loadInterstitial returned: $loadSuccess');
      
      if (!loadSuccess) {
        DemoAppLogger.sharedInstance.logMessage('❌ Failed to load interstitial ad');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load interstitial ad.', color: Colors.red);
        setState(() {
          _isInterstitialLoaded = false;
        });
        setLoadingState(false);
        return;
      }
      
      _log('loadInterstitial called successfully, waiting for delegate callbacks');
    } catch (e) {
      DemoAppLogger.sharedInstance.logMessage('❌ Error loading interstitial ad: $e');
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Error loading interstitial ad: $e', color: Colors.red);
      setState(() {
        _isInterstitialLoaded = false;
      });
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
      print('🟡 INTERSTITIAL: 🗑️ Disposing interstitial ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
    }
    super.dispose();
  }
} 