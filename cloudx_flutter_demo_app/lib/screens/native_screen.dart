import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';
import '../utils/demo_app_logger.dart';

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
  final double _nativeWidth = 320.0;
  final double _nativeHeight = 200.0;

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
    debugPrint('🟣 NATIVE: $message');
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
        onPressed: _isNativeLoaded ? _destroyNative : loadAd,
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
  Future<void> loadAd() async {
    _log('User clicked Load Native - starting load...');
    DemoAppLogger.sharedInstance.logMessage('🔄 Native load initiated');
    setLoadingState(true);
    setCustomStatus(text: 'Loading...', color: Colors.orange);
    setState(() {
      _isNativeLoaded = false;
    });
    
    try {
      // adId is now auto-generated - no need to create manually!
      _currentAdId = await CloudX.createNative(
        placement: widget.environment.nativePlacement,
        // adId is optional - will be auto-generated as 'native_<placement>_<timestamp>'
        listener: CloudXAdViewListener(
          onAdLoaded: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('✅ Native didLoadWithAd', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Native Ad Loaded', color: Colors.green);
            setState(() {
              _isNativeLoaded = true;
            });
          },
          onAdLoadFailed: (error) {
            DemoAppLogger.sharedInstance.logMessage('❌ Native failed to load: $error');
            setAdState(AdState.noAd);
            setCustomStatus(text: 'Failed to load native ad: $error', color: Colors.red);
            setState(() {
              _isNativeLoaded = false;
            });
          },
          onAdDisplayed: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👀 Native didDisplayWithAd', ad);
            setAdState(AdState.ready);
            setCustomStatus(text: 'Native Ad Displayed', color: Colors.green);
          },
          onAdDisplayFailed: (error) {
            DemoAppLogger.sharedInstance.logMessage('❌ Native failed to display: $error');
            setCustomStatus(text: 'Failed to display native ad: $error', color: Colors.red);
          },
          onAdClicked: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('👆 Native didClickWithAd', ad);
            setCustomStatus(text: 'Native Ad Clicked', color: Colors.blue);
          },
          onAdHidden: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('🔚 Native didHideWithAd', ad);
            setAdState(AdState.noAd);
            setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
            setState(() {
              _isNativeLoaded = false;
            });
          },
          onAdExpanded: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('📏 Native Expanded', ad);
            setCustomStatus(text: 'Native Ad Expanded', color: Colors.purple);
          },
          onAdCollapsed: (ad) {
            DemoAppLogger.sharedInstance.logAdEvent('📐 Native Collapsed', ad);
            setCustomStatus(text: 'Native Ad Collapsed', color: Colors.purple);
          },
        ),
      );
      if (_currentAdId == null) {
        DemoAppLogger.sharedInstance.logMessage('❌ Failed to create native ad');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to create native ad', color: Colors.red);
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
        DemoAppLogger.sharedInstance.logMessage('❌ Failed to load native ad');
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
      DemoAppLogger.sharedInstance.logMessage('❌ Error loading native ad: $e');
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Error loading native ad: $e', color: Colors.red);
      setState(() {
        _isNativeLoaded = false;
      });
    }
  }

  @override
  Future<void> showAd() async {
    // Native ads are automatically shown when loaded, no explicit show needed
  }

  void _destroyNative() {
    if (_currentAdId != null) {
      DemoAppLogger.sharedInstance.logMessage('🗑️ Destroying native ad');
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
      debugPrint('🟣 NATIVE: 🗑️ Disposing native ad with adId: $_currentAdId');
      CloudX.destroyAd(adId: _currentAdId!);
    }
    super.dispose();
  }
} 