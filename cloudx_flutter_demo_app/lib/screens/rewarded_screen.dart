import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';
import '../utils/demo_app_logger.dart';

class RewardedScreen extends BaseAdScreen {
  final DemoEnvironmentConfig environment;
  
  const RewardedScreen({
    super.key,
    required super.isSDKInitialized,
    required this.environment,
  });

  @override
  State<RewardedScreen> createState() => _RewardedScreenState();
}

class _RewardedScreenState extends BaseAdScreenState<RewardedScreen> with AutomaticKeepAliveClientMixin {
  String? _currentAdId;
  bool _isRewardedLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'rewarded';

  void _log(String message) {
    print('🟢 REWARDED: $message');
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
        onPressed: _isRewardedLoaded ? null : loadAd,
        child: Text(_isRewardedLoaded ? 'Rewarded Ad Loaded' : 'Load Rewarded'),
      ),
    );
  }

  Widget _buildShowButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isRewardedLoaded ? showAd : null,
        child: const Text('Show Rewarded'),
      ),
    );
  }

  Widget _buildInfoContainer() {
    return Container(
      height: 180,
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
            'Rewarded Ads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Full-screen ads that reward users',
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
          const Text(
            '• User must watch the full ad to get reward',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> loadAd() async {
    _log('User clicked Load Rewarded - starting load...');
    DemoAppLogger.sharedInstance.logMessage('🔄 Rewarded load initiated');
    setLoadingState(true);
    setCustomStatus(text: 'Loading...', color: Colors.orange);
    setState(() {
      _isRewardedLoaded = false;
    });
    
    try {
      _currentAdId = '${getAdIdPrefix()}_${DateTime.now().millisecondsSinceEpoch}';
      final success = await CloudX.createRewarded(
        placement: widget.environment.rewardedPlacement,
        adId: _currentAdId!,
        listener: RewardedListener()
          ..onAdLoaded = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('✅ Rewarded didLoadWithAd', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Rewarded Ad Loaded', color: Colors.green);
            setState(() {
              _isRewardedLoaded = true;
            });
          }
          ..onAdFailedToLoad = (error, ad) {
            DemoAppLogger.sharedInstance.logAdEvent('❌ Rewarded failToLoadWithAd', ad);
            DemoAppLogger.sharedInstance.logMessage('  Error: $error');
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load rewarded ad: $error', color: Colors.red);
            setState(() {
              _isRewardedLoaded = false;
            });
          }
          ..onAdShown = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👀 Rewarded didShowWithAd', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Rewarded Ad Shown', color: Colors.green);
          }
          ..onAdFailedToShow = (error, ad) {
            DemoAppLogger.sharedInstance.logAdEvent('❌ Rewarded failToShowWithAd', ad);
            DemoAppLogger.sharedInstance.logMessage('  Error: $error');
            setCustomStatus(text: 'Failed to show rewarded ad: $error', color: Colors.red);
          }
          ..onAdHidden = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('🔚 Rewarded didHideWithAd', ad);
            setAdState(AdState.noAd);
            setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
            setState(() {
              _isRewardedLoaded = false;
            });
          }
          ..onAdClicked = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👆 Rewarded didClickWithAd', ad);
            setCustomStatus(text: 'Rewarded Ad Clicked', color: Colors.blue);
          }
          ..onRewarded = (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('🎁 Rewarded - User rewarded!', ad);
            setCustomStatus(text: 'User rewarded!', color: Colors.purple);
          },
      );
      if (!success) {
        DemoAppLogger.sharedInstance.logMessage('❌ Failed to create rewarded ad');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to create rewarded ad.', color: Colors.red);
        setState(() {
          _isRewardedLoaded = false;
        });
        setLoadingState(false);
        return;
      }
      
      // Now load the rewarded ad (create -> load -> wait for callbacks)
      _log('Calling CloudX.loadRewarded with adId: $_currentAdId');
      final loadSuccess = await CloudX.loadRewarded(adId: _currentAdId!);
      _log('CloudX.loadRewarded returned: $loadSuccess');
      
      if (!loadSuccess) {
        DemoAppLogger.sharedInstance.logMessage('❌ Failed to load rewarded ad');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load rewarded ad.', color: Colors.red);
        setState(() {
          _isRewardedLoaded = false;
        });
        setLoadingState(false);
        return;
      }
      
      _log('loadRewarded called successfully, waiting for delegate callbacks');
    } catch (e) {
      DemoAppLogger.sharedInstance.logMessage('❌ Error loading rewarded ad: $e');
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Error loading rewarded ad: $e', color: Colors.red);
      setState(() {
        _isRewardedLoaded = false;
      });
    }
  }

  @override
  Future<void> showAd() async {
    if (_currentAdId == null) {
      setCustomStatus(text: 'No adId available for showing rewarded', color: Colors.red);
      return;
    }
    _log('User clicked Show Rewarded - showing ad with adId: $_currentAdId');
    DemoAppLogger.sharedInstance.logMessage('📺 Attempting to show rewarded ad');
    try {
      await CloudX.showRewarded(adId: _currentAdId!);
      setCustomStatus(text: 'Rewarded Ad Shown', color: Colors.green);
    } catch (e) {
      DemoAppLogger.sharedInstance.logMessage('❌ Error showing rewarded ad: $e');
      setCustomStatus(text: 'Error showing rewarded ad: $e', color: Colors.red);
    }
  }

  @override
  void dispose() {
    if (_currentAdId != null) {
      print('🟢 REWARDED: 🗑️ Disposing rewarded ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
    }
    super.dispose();
  }
} 