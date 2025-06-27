import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';

class BannerScreen extends BaseAdScreen {
  const BannerScreen({
    super.key,
    required super.isSDKInitialized,
  });

  @override
  State<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends BaseAdScreenState<BannerScreen> {
  String? _currentAdId;
  String? _currentPlacement;
  double? _bannerWidth;
  double? _bannerHeight;
  bool _isBannerLoaded = false;
  int _selectedBannerType = 0; // 0 = Banner, 1 = MREC
  BannerListener? _bannerListener;

  @override
  String getAdIdPrefix() => 'banner';

  void _log(String message) {
    print('🔵 BANNER: $message');
  }

  @override
  void initState() {
    super.initState();
    _bannerListener = BannerListener()
      ..onAdLoaded = (adId) {
        print('[BannerScreen] onAdLoaded callback received');
        setAdState(AdState.ready);
        setCustomStatus(text: 'Banner Ad Loaded', color: Colors.green);
        setState(() {
          _isBannerLoaded = true;
        });
        print('[BannerScreen] Status set to READY');
      }
      ..onAdFailedToLoad = (adId, error) {
        print('[BannerScreen] onAdFailedToLoad callback received: $error');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
        setState(() {
          _isBannerLoaded = false;
        });
        print('[BannerScreen] Status set to NO_AD');
      }
      ..onAdShown = (adId) {
        print('🔍 [BannerScreen] onAdShown callback START - adId: $adId');
        setAdState(AdState.ready);
        setCustomStatus(text: 'Banner Ad Shown', color: Colors.green);
        print('🔍 [BannerScreen] State updated - READY');
        print('🔍 [BannerScreen] onAdShown callback END');
      }
      ..onAdClicked = (adId) {
        print('🔍 [BannerScreen] onAdClicked callback START - adId: $adId');
        setCustomStatus(text: 'Banner Ad Clicked', color: Colors.blue);
        print('🔍 [BannerScreen] onAdClicked callback END');
      }
      ..onAdImpression = (adId) {
        print('🔍 [BannerScreen] onAdImpression callback START - adId: $adId');
        setAdState(AdState.ready);
        setCustomStatus(text: 'Banner Ad Impression', color: Colors.green);
        print('🔍 [BannerScreen] State updated - READY');
        print('🔍 [BannerScreen] onAdImpression callback END');
      };
    print('[BannerScreen] initState - BannerListener created');
  }

  @override
  Widget buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _buildBannerTypeSelector(),
        const SizedBox(height: 16),
        _buildLoadButton(),
        const Spacer(),
        _buildBannerContainer(),
        const SizedBox(height: 16),
        // Removed the top status label here
      ],
    );
  }

  Widget _buildBannerTypeSelector() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment<int>(value: 0, label: Text('Banner')),
            ButtonSegment<int>(value: 1, label: Text('MREC')),
          ],
          selected: {_selectedBannerType},
          onSelectionChanged: (Set<int> newSelection) {
            final newType = newSelection.first;
            _log('User changed banner type from ${_selectedBannerType == 0 ? "Banner" : "MREC"} to ${newType == 0 ? "Banner" : "MREC"}');
            setState(() {
              _selectedBannerType = newType;
              if (_isBannerLoaded) {
                _log('Destroying existing banner due to type change');
                _destroyBanner();
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isBannerLoaded ? _destroyBanner : _loadBanner,
        child: Text(_isBannerLoaded ? 'Stop' : 'Load / Show'),
      ),
    );
  }

  Widget _buildBannerContainer() {
    if (_isBannerLoaded && _currentAdId != null) {
      return Center(
        child: SizedBox(
          width: _bannerWidth ?? 320.0,
          height: _bannerHeight ?? 50.0,
          child: UiKitView(
            viewType: 'cloudx_banner_view',
            creationParams: {
              'adId': _currentAdId!,
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),
      );
    } else {
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
  }

  Future<void> _loadBanner() async {
    print('🔍 [BannerScreen] _loadBanner START');
    // Set loading state immediately when user taps the button
    print('🔍 [BannerScreen] Setting loading state...');
    setLoadingState(true);
    setCustomStatus(text: 'Loading...', color: Colors.orange);
    setState(() {
      _isBannerLoaded = false;
    });
    print('🔍 [BannerScreen] Loading state set');
    // Set up the placement and dimensions based on banner type
    _currentPlacement = _selectedBannerType == 0 ? 'banner1' : 'mrec1';
    if (_selectedBannerType == 0) {
      _bannerWidth = 320.0;
      _bannerHeight = 50.0;
    } else {
      _bannerWidth = 300.0;
      _bannerHeight = 250.0;
    }
    print('🔍 [BannerScreen] Banner type: ${_selectedBannerType == 0 ? "Banner" : "MREC"}, placement: $_currentPlacement, width: $_bannerWidth, height: $_bannerHeight');
    // Generate a unique adId
    _currentAdId = '${getAdIdPrefix()}_${DateTime.now().millisecondsSinceEpoch}';
    print('🔍 [BannerScreen] Generated adId: $_currentAdId');
    // Register the banner listener for this ad
    if (_bannerListener != null) {
      print('🔍 [BannerScreen] Registering banner listener for adId: $_currentAdId');
      CloudX.setBannerListener(_currentAdId!, _bannerListener!);
    } else {
      print('🔍 [BannerScreen] WARNING - _bannerListener is null!');
    }
    print('🔍 [BannerScreen] Calling CloudX.createBanner with adId: $_currentAdId, placement: $_currentPlacement');
    final success = await CloudX.createBanner(
      adId: _currentAdId!,
      placement: _currentPlacement!,
      width: _bannerWidth,
      height: _bannerHeight,
    );
    print('🔍 [BannerScreen] CloudX.createBanner returned: $success');
    if (!success) {
      print('🔍 [BannerScreen] createBanner failed, setting error state');
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Failed to create banner ad.', color: Colors.red);
      setState(() {
        _isBannerLoaded = false;
      });
      setLoadingState(false);
      return;
    }
    print('🔍 [BannerScreen] createBanner succeeded, waiting for delegate callbacks');
    // Set the banner as loaded so the UiKitView will be shown
    setState(() {
      _isBannerLoaded = true;
    });
    // Load the banner after it's added to the view hierarchy, following the working Objective-C app pattern
    print('🔍 [BannerScreen] Calling CloudX.loadBanner to load the banner after UiKitView is shown');
    final loadSuccess = await CloudX.loadBanner(adId: _currentAdId!);
    print('🔍 [BannerScreen] CloudX.loadBanner returned: $loadSuccess');
    if (!loadSuccess) {
      print('🔍 [BannerScreen] loadBanner failed, setting error state');
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Failed to load banner ad.', color: Colors.red);
      setState(() {
        _isBannerLoaded = false;
      });
      setLoadingState(false);
      return;
    }
    print('🔍 [BannerScreen] loadBanner succeeded, banner should start loading');
    print('🔍 [BannerScreen] _loadBanner END');
  }

  void _destroyBanner() {
    if (_currentAdId != null) {
      _log('🗑️ Destroying banner ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
      CloudX.removeBannerListener(_currentAdId!);
    } else {
      _log('⚠️ No adId to destroy');
    }
    setAdState(AdState.noAd);
    setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
    setState(() {
      _isBannerLoaded = false;
      _currentAdId = null;
    });
    _log('✅ Banner destroyed and state reset');
  }

  @override
  void dispose() {
    print('[BannerScreen] dispose called');
    if (_currentAdId != null) {
      print('[BannerScreen] Destroying banner ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
    }
    if (_currentAdId != null) {
      CloudX.removeBannerListener(_currentAdId!);
    }
    super.dispose();
  }
} 