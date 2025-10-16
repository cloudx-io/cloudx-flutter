import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';

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
        onPressed: _isRewardedLoaded ? null : _loadAd,
        child: Text(_isRewardedLoaded ? 'Rewarded Ad Loaded' : 'Load Rewarded'),
      ),
    );
  }

  Widget _buildShowButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isRewardedLoaded ? _showAd : null,
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
  Future<void> _loadAd() async {
    _log('User clicked Load Rewarded - starting load...');
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
          ..onAdLoaded = () {
            setAdState(AdState.ready);
            setCustomStatus(text: 'Rewarded Ad Loaded', color: Colors.green);
            setState(() {
              _isRewardedLoaded = true;
            });
          }
          ..onAdFailedToLoad = (error) {
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load rewarded ad: $error', color: Colors.red);
            setState(() {
              _isRewardedLoaded = false;
            });
          }
          ..onAdShown = () {
            setAdState(AdState.ready);
            setCustomStatus(text: 'Rewarded Ad Shown', color: Colors.green);
          }
          ..onAdFailedToShow = (error) {
            setCustomStatus(text: 'Failed to show rewarded ad: $error', color: Colors.red);
          }
          ..onAdHidden = () {
            setAdState(AdState.noAd);
            setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
            setState(() {
              _isRewardedLoaded = false;
            });
          }
          ..onAdClicked = () {
            setCustomStatus(text: 'Rewarded Ad Clicked', color: Colors.blue);
          }
          ..onRewarded = () {
            setCustomStatus(text: 'User rewarded!', color: Colors.purple);
          },
      );
      if (!success) {
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
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Error loading rewarded ad: $e', color: Colors.red);
      setState(() {
        _isRewardedLoaded = false;
      });
    }
  }

  Future<void> _showAd() async {
    if (_currentAdId == null) {
      setCustomStatus(text: 'No adId available for showing rewarded', color: Colors.red);
      return;
    }
    _log('User clicked Show Rewarded - showing ad with adId: $_currentAdId');
    try {
      await CloudX.showRewarded(adId: _currentAdId!);
      setCustomStatus(text: 'Rewarded Ad Shown', color: Colors.green);
    } catch (e) {
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