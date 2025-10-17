import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';

/// MREC (Medium Rectangle) Ad Screen
/// 
/// Implements MREC ad functionality:
/// - Creates MREC ad view on first load (user-initiated)
/// - Supports auto-refresh start/stop toggle
/// - Handles expand/collapse fullscreen events
/// - Fixed 300x250 ad dimensions per IAB standards
/// - Proper lifecycle management (create -> load -> show -> destroy)
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
  // MREC ad instance and state
  String? _currentAdId;
  bool _isMRECLoaded = false;
  bool _isMRECCreated = false;
  
  // Auto-refresh state
  bool _autoRefreshEnabled = true; // Default to enabled, matching ObjC
  
  // MREC listener instance (MRECListener extends BannerListener)
  MRECListener? _mrecListener;
  
  // MREC standard dimensions (IAB Medium Rectangle)
  static const double _mrecWidth = 300.0;
  static const double _mrecHeight = 250.0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'mrec';

  void _log(String message) {
    print('🟣 MREC: $message');
  }

  @override
  void initState() {
    super.initState();
    _initializeMRECListener();
    // DO NOT auto-create MREC - wait for user to press "Load MREC"
    // This prevents the spurious "Ad Shown" callback that fires when the view is created
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _createAndAddMRECToView();
    // });
  }

  /// Initialize MREC-specific listener with all delegate callbacks
  /// MRECListener extends BannerListener (MRECs are built on banner infrastructure)
  void _initializeMRECListener() {
    _mrecListener = MRECListener()
      ..onAdLoaded = _handleAdLoaded
      ..onAdFailedToLoad = _handleAdFailedToLoad
      ..onAdShown = _handleAdShown
      ..onAdClicked = _handleAdClicked
      ..onAdImpression = _handleAdImpression
      ..onAdExpanded = _handleAdExpanded
      ..onAdCollapsed = _handleAdCollapsed
      ..onAdClosedByUser = _handleAdClosedByUser;
    
    _log('MREC listener initialized with all delegates');
  }

  // ============================================================================
  // MARK: - MREC Lifecycle Management
  // ============================================================================

  /// Create and add MREC to view hierarchy (called on first load)
  Future<void> _createAndAddMRECToView() async {
    if (_isMRECCreated) {
      _log('MREC already created, skipping');
      return;
    }

    _log('Auto-creating MREC and adding to view hierarchy...');
    
    // Generate unique adId
    _currentAdId = '${getAdIdPrefix()}_${DateTime.now().millisecondsSinceEpoch}';
    
    _log('Creating MREC with adId: $_currentAdId, placement: ${widget.environment.mrecPlacement}');
    
    try {
      final success = await CloudX.createMREC(
        adId: _currentAdId!,
        placement: widget.environment.mrecPlacement,
        listener: _mrecListener,
      );

      if (success) {
        _log('✅ MREC created successfully and added to view hierarchy');
        setState(() {
          _isMRECCreated = true;
        });
        setCustomStatus(text: 'MREC Ready (not loaded)', color: Colors.grey);
      } else {
        _log('❌ Failed to create MREC');
        _showErrorDialog('MREC Error', 'Failed to create MREC ad view.');
        setAdState(AdState.noAd);
      }
    } catch (e) {
      _log('❌ Exception creating MREC: $e');
      _showErrorDialog('MREC Error', 'Exception creating MREC: $e');
      setAdState(AdState.noAd);
    }
  }

  // ============================================================================
  // MARK: - User Actions
  // ============================================================================

  /// Load MREC ad (user-initiated)
  @override
  Future<void> _loadAd() async {
    _log('User clicked Load MREC button');

    if (!widget.isSDKInitialized) {
      _showErrorDialog('SDK Not Initialized', 'Please initialize SDK first.');
      return;
    }

    if (isLoading) {
      _showErrorDialog('Info', 'MREC is already loading.');
      return;
    }

    if (!_isMRECCreated) {
      _log('MREC not created, creating now...');
      await _createAndAddMRECToView();
      if (!_isMRECCreated) {
        return; // Creation failed
      }
    }

    // Start loading
    _log('Starting MREC load...');
    setLoadingState(true);
    setCustomStatus(text: 'Loading MREC...', color: Colors.orange);

    // Allow UI to render the loading state before starting async load
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final loadSuccess = await CloudX.loadMREC(adId: _currentAdId!);
      _log('CloudX.loadMREC returned: $loadSuccess');

      if (!loadSuccess) {
        _log('❌ loadMREC returned false');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load MREC', color: Colors.red);
        setLoadingState(false);
      }
      // Success case handled by onAdLoaded callback
    } catch (e) {
      _log('❌ Exception loading MREC: $e');
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Error loading MREC: $e', color: Colors.red);
      setLoadingState(false);
    }
  }

  /// Not used for MREC (auto-shows when loaded)
  @override
  Future<void> _showAd() async {
    // MREC ads are automatically shown when loaded, no explicit show needed
    _log('Show button pressed (MREC auto-shows on load)');
  }

  /// Toggle auto-refresh on/off
  void _toggleAutoRefresh() {
    if (!_isMRECCreated || _currentAdId == null) {
      _log('⚠️ Cannot toggle auto-refresh: MREC not created');
      return;
    }

    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });

    if (_autoRefreshEnabled) {
      _log('▶️ Starting auto-refresh');
      CloudX.startAutoRefresh(adId: _currentAdId!);
      setCustomStatus(text: 'Auto-refresh enabled', color: Colors.purple);
    } else {
      _log('⏸️ Stopping auto-refresh');
      CloudX.stopAutoRefresh(adId: _currentAdId!);
      setCustomStatus(text: 'Auto-refresh disabled', color: Colors.grey);
    }
  }

  // ============================================================================
  // MARK: - MREC Delegate Callbacks
  // ============================================================================

  void _handleAdLoaded() {
    _log('✅ didLoadWithAd - MREC loaded successfully');
    setLoadingState(false);
    setAdState(AdState.ready);
    setCustomStatus(text: 'MREC Ad Loaded', color: Colors.green);
    setState(() {
      _isMRECLoaded = true;
    });
  }

  void _handleAdFailedToLoad(String error) {
    _log('❌ failToLoadWithAd - Error: $error');
    setLoadingState(false);
    setAdState(AdState.noAd);
    setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
    setState(() {
      _isMRECLoaded = false;
    });
    
    // Show error dialog on main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showErrorDialog('MREC Error', error);
    });
  }

  void _handleAdShown() {
    _log('👀 didShowWithAd - MREC shown to user');
    setCustomStatus(text: 'MREC Ad Shown', color: Colors.green);
  }

  void _handleAdClicked() {
    _log('👆 didClickWithAd - MREC clicked');
    setCustomStatus(text: 'MREC Ad Clicked', color: Colors.blue);
  }

  void _handleAdImpression() {
    _log('👁️ impressionOn - MREC impression recorded');
    setCustomStatus(text: 'MREC Impression', color: Colors.green);
  }

  void _handleAdExpanded() {
    _log('🔍 didExpandAd - MREC expanded to fullscreen');
    setCustomStatus(text: 'MREC Expanded', color: Colors.purple);
    
    // Show alert to user (matching ObjC behavior)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInfoDialog('MREC Expanded!', 'MREC ad expanded to full screen.');
    });
  }

  void _handleAdCollapsed() {
    _log('🔍 didCollapseAd - MREC collapsed from fullscreen');
    setCustomStatus(text: 'MREC Collapsed', color: Colors.green);
    
    // Show alert to user (matching ObjC behavior)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInfoDialog('MREC Collapsed!', 'MREC ad collapsed from full screen.');
    });
  }

  void _handleAdClosedByUser() {
    _log('✋ closedByUserActionWithAd - MREC closed by user');
    setCustomStatus(text: 'MREC Closed', color: Colors.orange);
    setState(() {
      _isMRECLoaded = false;
    });
  }

  // ============================================================================
  // MARK: - UI Building
  // ============================================================================

  @override
  Widget buildMainContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _buildLoadButton(),
        const SizedBox(height: 120),
        _buildMRECContainer(),
        const Spacer(),
        _buildAutoRefreshButton(),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Load MREC button
  Widget _buildLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: isLoading ? null : _loadAd,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(200, 44),
        ),
        child: Text(
          isLoading ? 'Loading...' : 'Load MREC',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// MREC ad container (300x250 fixed size)
  Widget _buildMRECContainer() {
    if (_isMRECCreated && _currentAdId != null) {
      return Center(
        child: Container(
          width: _mrecWidth,
          height: _mrecHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Platform.isAndroid
              ? AndroidView(
                  viewType: 'cloudx_banner_view', // MREC uses banner view type
                  creationParams: {
                    'adId': _currentAdId!,
                    'width': _mrecWidth,
                    'height': _mrecHeight,
                  },
                  creationParamsCodec: const StandardMessageCodec(),
                )
              : UiKitView(
                  viewType: 'cloudx_banner_view', // MREC uses banner view type
                  creationParams: {
                    'adId': _currentAdId!,
                  },
                  creationParamsCodec: const StandardMessageCodec(),
                ),
        ),
      );
    } else {
      return Center(
        child: Container(
          width: _mrecWidth,
          height: _mrecHeight,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey.shade400, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ad_units, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'MREC (300x250)',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ad will appear here',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// Auto-refresh toggle button (positioned above status label)
  Widget _buildAutoRefreshButton() {
    return Center(
      child: ElevatedButton(
        onPressed: (_isMRECCreated && _currentAdId != null) ? _toggleAutoRefresh : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _autoRefreshEnabled ? Colors.red : Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(200, 44),
        ),
        child: Text(
          _autoRefreshEnabled ? 'Stop Auto-Refresh' : 'Start Auto-Refresh',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // MARK: - Helper Methods
  // ============================================================================

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        icon: const Icon(Icons.info_outline, size: 48, color: Colors.blue),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Reset ad state and destroy MREC (called on dispose or viewWillDisappear)
  void _resetAdState() {
    if (_currentAdId != null) {
      _log('🗑️ Destroying MREC ad with adId: $_currentAdId (critical for stopping auto-refresh)');
      CloudX.destroyAd(adId: _currentAdId!);
    }
    setState(() {
      _isMRECLoaded = false;
      _isMRECCreated = false;
      _currentAdId = null;
    });
    setAdState(AdState.noAd);
    setCustomStatus(text: 'No Ad Loaded', color: Colors.red);
  }

  @override
  void dispose() {
    _log('dispose called - cleaning up MREC resources');
    _resetAdState();
    super.dispose();
  }
}

