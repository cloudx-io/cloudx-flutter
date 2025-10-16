import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';

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
  String? _currentAdId;
  String? _currentPlacement;
  double? _bannerWidth;
  double? _bannerHeight;
  bool _isBannerLoaded = false;
  int _selectedBannerType = 0; // 0 = Banner, 1 = MREC
  BannerListener? _bannerListener;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'banner';

  void _log(String message) {
    print('🔵 BANNER: $message');
  }

  @override
  void initState() {
    super.initState();
    _bannerListener = BannerListener()
      ..onAdLoaded = () {
        print('[BannerScreen] onAdLoaded callback received');
        setAdState(AdState.ready);
        setCustomStatus(text: 'Banner Ad Loaded', color: Colors.green);
        setState(() {
          _isBannerLoaded = true;
        });
        print('[BannerScreen] Status set to READY');
      }
      ..onAdFailedToLoad = (error) {
        print('[BannerScreen] onAdFailedToLoad callback received: $error');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
        setState(() {
          _isBannerLoaded = false;
        });
        print('[BannerScreen] Status set to NO_AD');
      }
      ..onAdShown = () {
        print('🔍 [BannerScreen] onAdShown callback START');
        setAdState(AdState.ready);
        setCustomStatus(text: 'Banner Ad Shown', color: Colors.green);
        print('🔍 [BannerScreen] State updated - READY');
        print('🔍 [BannerScreen] onAdShown callback END');
      }
      ..onAdClicked = () {
        print('🔍 [BannerScreen] onAdClicked callback START');
        setCustomStatus(text: 'Banner Ad Clicked', color: Colors.blue);
        print('🔍 [BannerScreen] onAdClicked callback END');
      }
      ..onAdImpression = () {
        print('🔍 [BannerScreen] onAdImpression callback START');
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
      final width = _bannerWidth ?? 320.0;
      final height = _bannerHeight ?? 50.0;
      
      return Center(
        child: SizedBox(
          width: width,
          height: height,
          child: Platform.isAndroid
              ? AndroidView(
                  viewType: 'cloudx_banner_view',
                  creationParams: {
                    'adId': _currentAdId!,
                    'width': width,
                    'height': height,
                  },
                  creationParamsCodec: const StandardMessageCodec(),
                )
              : UiKitView(
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
    _currentPlacement = _selectedBannerType == 0 
        ? widget.environment.bannerPlacement 
        : widget.environment.mrecPlacement;
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
    print('🔍 [BannerScreen] Calling CloudX.createBanner with adId: $_currentAdId, placement: $_currentPlacement');
    final success = await CloudX.createBanner(
      adId: _currentAdId!,
      placement: _currentPlacement!,
      listener: _bannerListener,
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
    print('🔍 [BannerScreen] createBanner succeeded, setting banner as loaded');
    // Set the banner as loaded so the UiKitView will be shown
    setState(() {
      _isBannerLoaded = true;
    });
    
    // Now load the banner (similar to Objective-C demo: create -> add to view -> load)
    print('🔍 [BannerScreen] Calling CloudX.loadBanner with adId: $_currentAdId');
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
    
    print('🔍 [BannerScreen] loadBanner called successfully, waiting for delegate callbacks');
    print('🔍 [BannerScreen] _loadBanner END');
  }

  void _destroyBanner() {
    if (_currentAdId != null) {
      _log('🗑️ Destroying banner ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
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
    super.dispose();
  }
} 