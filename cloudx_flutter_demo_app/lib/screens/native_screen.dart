import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';

class NativeScreen extends BaseAdScreen {
  final DemoEnvironmentConfig environment;
  
  const NativeScreen({
    super.key,
    required super.isSDKInitialized,
    required this.environment,
  });

  @override
  State<NativeScreen> createState() => _NativeScreenState();
}

class _NativeScreenState extends BaseAdScreenState<NativeScreen> with AutomaticKeepAliveClientMixin {
  String? _currentAdId;
  bool _isNativeLoaded = false;
  double _nativeWidth = 320.0;
  double _nativeHeight = 200.0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'native';

  void _log(String message) {
    print('🟣 NATIVE: $message');
  }

  @override
  Widget buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _buildLoadButton(),
        const SizedBox(height: 40),
        _buildNativeContainer(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isNativeLoaded ? _destroyNative : _loadAd,
        child: Text(_isNativeLoaded ? 'Stop' : 'Load / Show Native'),
      ),
    );
  }

  Widget _buildNativeContainer() {
    if (_isNativeLoaded && _currentAdId != null) {
      return Center(
        child: SizedBox(
          width: _nativeWidth,
          height: _nativeHeight,
          child: UiKitView(
            viewType: 'cloudx_native_view', // Native ads use their own view type
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
            'Native ad will appear here when loaded',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
  }

  @override
  Future<void> _loadAd() async {
    _log('User clicked Load Native - starting load...');
    setLoadingState(true);
    setCustomStatus(text: 'Loading...', color: Colors.orange);
    setState(() {
      _isNativeLoaded = false;
    });
    
    try {
      _currentAdId = '${getAdIdPrefix()}_${DateTime.now().millisecondsSinceEpoch}';
      final success = await CloudX.createNative(
        placement: widget.environment.nativePlacement,
        adId: _currentAdId!,
        listener: NativeListener()
          ..onAdLoaded = () {
            setAdState(AdState.ready);
            setCustomStatus(text: 'Native Ad Loaded', color: Colors.green);
            setState(() {
              _isNativeLoaded = true;
            });
          }
          ..onAdFailedToLoad = (error) {
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load native ad: $error', color: Colors.red);
            setState(() {
              _isNativeLoaded = false;
            });
          }
          ..onAdShown = () {
            setAdState(AdState.ready);
            setCustomStatus(text: 'Native Ad Shown', color: Colors.green);
          }
          ..onAdFailedToShow = (error) {
            setCustomStatus(text: 'Failed to show native ad: $error', color: Colors.red);
          }
          ..onAdHidden = () {
            setAdState(AdState.noAd);
            setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
            setState(() {
              _isNativeLoaded = false;
            });
          }
          ..onAdClicked = () {
            setCustomStatus(text: 'Native Ad Clicked', color: Colors.blue);
          },
      );
      if (!success) {
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to create native ad.', color: Colors.red);
        setState(() {
          _isNativeLoaded = false;
        });
        setLoadingState(false);
        return;
      }
      
      // Now load the native ad (create -> load -> wait for callbacks)
      _log('Calling CloudX.loadNative with adId: $_currentAdId');
      final loadSuccess = await CloudX.loadNative(adId: _currentAdId!);
      _log('CloudX.loadNative returned: $loadSuccess');
      
      if (!loadSuccess) {
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load native ad.', color: Colors.red);
        setState(() {
          _isNativeLoaded = false;
        });
        setLoadingState(false);
        return;
      }
      
      _log('loadNative called successfully, waiting for delegate callbacks');
    } catch (e) {
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Error loading native ad: $e', color: Colors.red);
      setState(() {
        _isNativeLoaded = false;
      });
    }
  }

  void _destroyNative() {
    if (_currentAdId != null) {
      _log('🗑️ Destroying native ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
    }
    setAdState(AdState.noAd);
    setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
    setState(() {
      _isNativeLoaded = false;
      _currentAdId = null;
    });
    _log('✅ Native ad destroyed and state reset');
  }

  @override
  void dispose() {
    if (_currentAdId != null) {
      print('🟣 NATIVE: 🗑️ Disposing native ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
    }
    super.dispose();
  }
} 