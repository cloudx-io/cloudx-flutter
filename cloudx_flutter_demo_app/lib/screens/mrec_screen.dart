import 'package:flutter/material.dart';
import 'package:cloudx_flutter/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';
import '../utils/demo_app_logger.dart';

/// MREC (Medium Rectangle) Ad Screen
///
/// Demonstrates CloudXMRECView widget with auto-refresh controls and programmatic positioning.
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

class _MRECScreenState extends BaseAdScreenState<MRECScreen> {
  // UI Constants
  static const double _containerHeight = 250.0;
  static const double _containerBorderRadius = 12.0;
  static const double _containerBorderWidth = 2.0;
  static const double _iconSizeLarge = 48.0;
  static const double _iconSizeSmall = 32.0;
  static const double _iconPadding = 12.0;
  static const double _horizontalMargin = 16.0;

  bool _showMREC = false;
  bool _isAutoRefreshEnabled = true;
  final _mrecController = CloudXAdViewController();

  // Programmatic MREC state
  bool _useProgrammaticMREC = false;
  AdViewPosition _selectedPosition = AdViewPosition.centered;
  String? _programmaticAdId;

  @override
  Widget build(BuildContext context) {
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'mrec';

  @override
  Widget buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _buildMRECModeToggle(),
          const SizedBox(height: 16),
          if (_useProgrammaticMREC) _buildPositionSelector(),
          if (_useProgrammaticMREC) const SizedBox(height: 16),
          _buildLoadButton(),
          const SizedBox(height: 16),
          _buildAutoRefreshControls(),
          const SizedBox(height: 24),
          _buildMRECContainer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMRECModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalMargin),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _useProgrammaticMREC
                      ? 'Programmatic (Positioned)'
                      : 'Widget-based (Embedded)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: _useProgrammaticMREC,
                onChanged: !_showMREC
                    ? (value) {
                        setState(() {
                          _useProgrammaticMREC = value;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalMargin),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MREC Position:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPositionChip('Top Center', AdViewPosition.topCenter),
                  _buildPositionChip('Top Right', AdViewPosition.topRight),
                  _buildPositionChip('Center', AdViewPosition.centered),
                  _buildPositionChip('Center Left', AdViewPosition.centerLeft),
                  _buildPositionChip(
                      'Center Right', AdViewPosition.centerRight),
                  _buildPositionChip('Bottom Left', AdViewPosition.bottomLeft),
                  _buildPositionChip(
                      'Bottom Center', AdViewPosition.bottomCenter),
                  _buildPositionChip(
                      'Bottom Right', AdViewPosition.bottomRight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionChip(String label, AdViewPosition position) {
    final isSelected = _selectedPosition == position;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: !_showMREC
          ? (selected) {
              setState(() {
                _selectedPosition = position;
              });
            }
          : null,
    );
  }

  Widget _buildLoadButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _useProgrammaticMREC
            ? _toggleProgrammaticMREC
            : () {
                setState(() {
                  _showMREC = !_showMREC;
                  // Reset auto-refresh state to default when stopping widget-based MREC
                  if (!_showMREC) {
                    _isAutoRefreshEnabled = true;
                  }
                });
                if (!_showMREC) {
                  setAdState(AdState.noAd);
                  setCustomStatus(text: 'MREC stopped', color: Colors.grey);
                } else {
                  setAdState(AdState.loading);
                }
              },
        child: Text(_showMREC ? 'Stop' : 'Load / Show'),
      ),
    );
  }

  Future<void> _toggleProgrammaticMREC() async {
    if (_showMREC) {
      // Stop and destroy programmatic MREC
      if (_programmaticAdId != null) {
        await CloudX.destroyAd(adId: _programmaticAdId!);
        _programmaticAdId = null;
        DemoAppLogger.sharedInstance
            .logMessage('🗑️ Destroyed programmatic MREC');
      }
      setState(() {
        _showMREC = false;
        // Reset auto-refresh state to default when destroying ad
        _isAutoRefreshEnabled = true;
      });
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Programmatic MREC stopped', color: Colors.grey);
    } else {
      // Create, load, and show programmatic MREC
      setState(() {
        _showMREC = true;
      });
      setAdState(AdState.loading);
      setCustomStatus(text: 'Loading programmatic MREC...', color: Colors.blue);

      try {
        // Create programmatic MREC with position
        _programmaticAdId = await CloudX.createMREC(
          placementName: widget.environment.mrecPlacementName,
          position: _selectedPosition,
          listener: _createMRECListener('Programmatic MREC'),
        );

        // Check if creation failed (native SDK returned nil)
        if (_programmaticAdId == null) {
          DemoAppLogger.sharedInstance.logMessage(
              '❌ Failed to create programmatic MREC - native SDK returned nil');
          setAdState(AdState.noAd);
          setCustomStatus(
              text: 'Failed to create MREC (SDK returned nil)',
              color: Colors.red);
          setState(() {
            _showMREC = false;
          });
          return;
        }

        DemoAppLogger.sharedInstance.logMessage(
            '🎯 Created programmatic MREC at ${_selectedPosition.value}');

        // Load the MREC
        await CloudX.loadMREC(adId: _programmaticAdId!);
        DemoAppLogger.sharedInstance.logMessage('📥 Loading programmatic MREC');

        // Start auto-refresh (enabled by default)
        if (_isAutoRefreshEnabled) {
          await CloudX.startAutoRefresh(adId: _programmaticAdId!);
          DemoAppLogger.sharedInstance
              .logMessage('🔄 Auto-refresh started (enabled by default)');
        }
      } catch (e) {
        DemoAppLogger.sharedInstance
            .logMessage('❌ Error creating programmatic MREC: $e');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Error: $e', color: Colors.red);
        setState(() {
          _showMREC = false;
        });
      }
    }
  }

  Widget _buildAutoRefreshControls() {
    // Only show when MREC is loaded
    if (!_showMREC) {
      return const SizedBox.shrink();
    }

    // Don't show for widget-based if controller not attached
    if (!_useProgrammaticMREC && !_mrecController.isAttached) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalMargin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _isAutoRefreshEnabled ? null : _startAutoRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Auto-Refresh'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: !_isAutoRefreshEnabled ? null : _stopAutoRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Stop Auto-Refresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _startAutoRefresh() async {
    await _performAutoRefreshAction(
      programmaticAction: () =>
          CloudX.startAutoRefresh(adId: _programmaticAdId!),
      widgetAction: () => _mrecController.startAutoRefresh(),
    );

    setState(() {
      _isAutoRefreshEnabled = true;
    });
    DemoAppLogger.sharedInstance.logMessage('🔄 Auto-refresh started');
    setCustomStatus(text: 'Auto-refresh started', color: Colors.green);
  }

  Future<void> _stopAutoRefresh() async {
    await _performAutoRefreshAction(
      programmaticAction: () =>
          CloudX.stopAutoRefresh(adId: _programmaticAdId!),
      widgetAction: () => _mrecController.stopAutoRefresh(),
    );

    setState(() {
      _isAutoRefreshEnabled = false;
    });
    DemoAppLogger.sharedInstance.logMessage('⏸️ Auto-refresh stopped');
    setCustomStatus(text: 'Auto-refresh stopped', color: Colors.orange);
  }

  /// Helper to perform auto-refresh actions for both MREC modes
  Future<void> _performAutoRefreshAction({
    required Future<void> Function() programmaticAction,
    required Future<void> Function() widgetAction,
  }) async {
    if (_useProgrammaticMREC && _programmaticAdId != null) {
      await programmaticAction();
    } else {
      await widgetAction();
    }
  }

  Widget _buildMRECContainer() {
    if (!_showMREC) {
      return _buildPlaceholderContainer(
        icon: Icon(
          _useProgrammaticMREC ? Icons.fullscreen : Icons.view_compact,
          size: _iconSizeLarge,
          color: Colors.grey[400],
        ),
        title: _useProgrammaticMREC ? 'Programmatic Mode' : 'Widget-based Mode',
        description: _useProgrammaticMREC
            ? 'MREC will overlay at\nselected screen position'
            : 'MREC will render here\nin the widget tree',
        backgroundColor: Colors.grey[100]!,
        borderColor: Colors.grey[300]!,
        titleColor: Colors.grey[700]!,
        descriptionColor: Colors.grey[600]!,
      );
    }

    // Programmatic MRECs don't render in this container
    if (_useProgrammaticMREC) {
      return _buildStateContainer(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.blue[100]!],
          ),
          borderRadius: BorderRadius.circular(_containerBorderRadius),
          border: Border.all(
            color: Colors.blue[300]!,
            width: _containerBorderWidth,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(_iconPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.layers,
                  size: _iconSizeSmall, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              'MREC Active',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _selectedPosition.value.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Widget-based MREC
    return Center(
      child: CloudXMRECView(
        placementName: widget.environment.mrecPlacementName,
        width: 300,
        height: 250,
        controller: _mrecController,
        listener: _createMRECListener('MREC Ad'),
      ),
    );
  }

  /// Creates a CloudXAdViewListener with appropriate callbacks for MREC ads
  CloudXAdViewListener _createMRECListener(String adType) {
    return CloudXAdViewListener(
      onAdLoaded: (ad) {
        DemoAppLogger.sharedInstance.logAdEvent('✅ $adType Loaded', ad);
        setAdState(AdState.ready);
        setCustomStatus(text: '$adType Loaded', color: Colors.green);

        // Auto-show programmatic MRECs
        if (_useProgrammaticMREC && _programmaticAdId != null) {
          CloudX.showMREC(adId: _programmaticAdId!);
        }
      },
      onAdLoadFailed: (error) {
        DemoAppLogger.sharedInstance.logMessage('❌ $adType Failed: $error');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
        if (_useProgrammaticMREC) {
          setState(() {
            _showMREC = false;
          });
        }
      },
      onAdDisplayed: (ad) {
        DemoAppLogger.sharedInstance.logAdEvent('📺 $adType Displayed', ad);
        final positionText =
            _useProgrammaticMREC ? ' at ${_selectedPosition.value}' : '';
        setCustomStatus(
            text: '$adType Displayed$positionText', color: Colors.green);
      },
      onAdDisplayFailed: (error) {
        DemoAppLogger.sharedInstance
            .logMessage('❌ $adType Display Failed: $error');
        setCustomStatus(text: 'Failed to display: $error', color: Colors.red);
      },
      onAdClicked: (ad) {
        DemoAppLogger.sharedInstance.logAdEvent('👆 $adType Clicked', ad);
        setCustomStatus(text: '$adType Clicked', color: Colors.blue);
      },
      onAdHidden: (ad) {
        DemoAppLogger.sharedInstance.logAdEvent('👋 $adType Hidden', ad);
        setCustomStatus(text: '$adType Hidden', color: Colors.grey);
      },
      onAdExpanded: (ad) {
        DemoAppLogger.sharedInstance.logAdEvent('📏 $adType Expanded', ad);
        setCustomStatus(text: '$adType Expanded', color: Colors.purple);
      },
      onAdCollapsed: (ad) {
        DemoAppLogger.sharedInstance.logAdEvent('📐 $adType Collapsed', ad);
        setCustomStatus(text: '$adType Collapsed', color: Colors.purple);
      },
    );
  }

  /// Helper to build a state container with consistent styling
  Widget _buildStateContainer({
    required BoxDecoration decoration,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _horizontalMargin),
      height: _containerHeight,
      decoration: decoration,
      child: Center(child: child),
    );
  }

  /// Helper to build a placeholder container with consistent styling
  Widget _buildPlaceholderContainer({
    required Icon icon,
    required String title,
    required String description,
    required Color backgroundColor,
    required Color borderColor,
    required Color titleColor,
    required Color descriptionColor,
  }) {
    return _buildStateContainer(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_containerBorderRadius),
        border: Border.all(
          color: borderColor,
          width: _containerBorderWidth,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: _iconPadding),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: descriptionColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> loadAd() async {
    // Widget handles loading automatically
  }

  @override
  Future<void> showAd() async {
    // Widget handles showing automatically
  }

  @override
  void dispose() {
    _mrecController.dispose();
    // Clean up programmatic MREC if exists
    if (_programmaticAdId != null) {
      CloudX.destroyAd(adId: _programmaticAdId!);
    }
    super.dispose();
  }
}
