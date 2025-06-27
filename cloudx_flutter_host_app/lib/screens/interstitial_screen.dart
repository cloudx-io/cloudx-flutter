import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';

class InterstitialScreen extends BaseAdScreen {
  const InterstitialScreen({
    super.key,
    required super.isSDKInitialized,
  });

  @override
  State<InterstitialScreen> createState() => _InterstitialScreenState();
}

class _InterstitialScreenState extends BaseAdScreenState<InterstitialScreen> {
  String? _currentAdId;
  bool _isInterstitialLoaded = false;

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
        onPressed: _isInterstitialLoaded ? null : _loadAd,
        child: Text(_isInterstitialLoaded ? 'Interstitial Loaded' : 'Load Interstitial'),
      ),
    );
  }

  Widget _buildShowButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isInterstitialLoaded ? _showAd : null,
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
  Future<void> _loadAd() async {
    _log('User clicked Load Interstitial - starting load...');
    setLoadingState(true);
    setCustomStatus(text: 'Loading...', color: Colors.orange);
    setState(() {
      _isInterstitialLoaded = false;
    });
    
    try {
      _currentAdId = '${getAdIdPrefix()}_${DateTime.now().millisecondsSinceEpoch}';
      _log('Creating interstitial with adId: $_currentAdId, placement: interstitial1');
      final success = await CloudX.createInterstitial(
        placement: 'interstitial1',
        adId: _currentAdId!,
        listener: InterstitialListener()
          ..onAdLoaded = () {
            setAdState(AdState.ready);
            setCustomStatus(text: 'Interstitial Ad Loaded', color: Colors.green);
            setState(() {
              _isInterstitialLoaded = true;
            });
          }
          ..onAdFailedToLoad = (adId, error) {
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load interstitial ad: $error', color: Colors.red);
            setState(() {
              _isInterstitialLoaded = false;
            });
          }
          ..onAdShown = () {
            setAdState(AdState.ready);
            setCustomStatus(text: 'Interstitial Ad Shown', color: Colors.green);
          }
          ..onAdFailedToShow = (adId, error) {
            setCustomStatus(text: 'Failed to show interstitial ad: $error', color: Colors.red);
          }
          ..onAdHidden = () {
            setAdState(AdState.noAd);
            setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
            setState(() {
              _isInterstitialLoaded = false;
            });
          }
          ..onAdClicked = () {
            setCustomStatus(text: 'Interstitial Ad Clicked', color: Colors.blue);
          },
      );
      if (!success) {
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to create interstitial ad.', color: Colors.red);
        setState(() {
          _isInterstitialLoaded = false;
        });
      }
    } catch (e) {
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Error loading interstitial ad: $e', color: Colors.red);
      setState(() {
        _isInterstitialLoaded = false;
      });
    }
  }

  Future<void> _showAd() async {
    if (_currentAdId == null) {
      setCustomStatus(text: 'No adId available for showing interstitial', color: Colors.red);
      return;
    }
    _log('User clicked Show Interstitial - showing ad with adId: $_currentAdId');
    try {
      await CloudX.showInterstitial(adId: _currentAdId!);
      setCustomStatus(text: 'Interstitial Ad Shown', color: Colors.green);
    } catch (e) {
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