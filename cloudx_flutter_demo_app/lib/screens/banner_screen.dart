import 'package:flutter/material.dart';
import 'package:cloudx_flutter/cloudx.dart';
import 'base_ad_screen.dart';
import '../config/demo_config.dart';
import '../utils/demo_app_logger.dart';

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

class _BannerScreenState extends BaseAdScreenState<BannerScreen> {
  // UI Constants
  static const double _containerHeight = 180.0;
  static const double _containerBorderRadius = 12.0;
  static const double _containerBorderWidth = 2.0;
  static const double _iconSizeLarge = 48.0;
  static const double _iconSizeSmall = 32.0;
  static const double _iconPadding = 12.0;
  static const double _horizontalMargin = 16.0;

  bool _showBanner = false;
  bool _isAutoRefreshEnabled = true;
  final _bannerController = CloudXAdViewController();

  // Programmatic banner state
  bool _useProgrammaticBanner = false;
  AdViewPosition _selectedPosition = AdViewPosition.bottomCenter;
  String? _programmaticAdId;

  @override
  Widget build(BuildContext context) {
    return buildScreen(context);
  }

  @override
  String getAdIdPrefix() => 'banner';

  @override
  Widget buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _buildBannerModeToggle(),
          const SizedBox(height: 16),
          if (_useProgrammaticBanner) _buildPositionSelector(),
          if (_useProgrammaticBanner) const SizedBox(height: 16),
          _buildLoadButton(),
          const SizedBox(height: 16),
          _buildAutoRefreshControls(),
          const SizedBox(height: 24),
          _buildBannerContainer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBannerModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalMargin),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _useProgrammaticBanner
                      ? 'Programmatic (Positioned)'
                      : 'Widget-based (Embedded)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: _useProgrammaticBanner,
                onChanged: !_showBanner
                    ? (value) {
                        setState(() {
                          _useProgrammaticBanner = value;
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
              const Text('Banner Position:',
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
      onSelected: !_showBanner
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
        onPressed: _useProgrammaticBanner
            ? _toggleProgrammaticBanner
            : () {
                setState(() {
                  _showBanner = !_showBanner;
                  // Reset auto-refresh state to default when stopping widget-based banner
                  if (!_showBanner) {
                    _isAutoRefreshEnabled = true;
                  }
                });
                if (!_showBanner) {
                  setAdState(AdState.noAd);
                  setCustomStatus(text: 'Banner stopped', color: Colors.grey);
                } else {
                  setAdState(AdState.loading);
                }
              },
        child: Text(_showBanner ? 'Stop' : 'Load / Show'),
      ),
    );
  }

  Future<void> _toggleProgrammaticBanner() async {
    if (_showBanner) {
      // Stop and destroy programmatic banner
      if (_programmaticAdId != null) {
        await CloudX.destroyAd(adId: _programmaticAdId!);
        _programmaticAdId = null;
        DemoAppLogger.sharedInstance
            .logMessage('🗑️ Destroyed programmatic banner');
      }
      setState(() {
        _showBanner = false;
        // Reset auto-refresh state to default when destroying ad
        _isAutoRefreshEnabled = true;
      });
      setAdState(AdState.noAd);
      setCustomStatus(text: 'Programmatic banner stopped', color: Colors.grey);
    } else {
      // Create, load, and show programmatic banner
      setState(() {
        _showBanner = true;
      });
      setAdState(AdState.loading);
      setCustomStatus(
          text: 'Loading programmatic banner...', color: Colors.blue);

      try {
        // Create programmatic banner with position
        _programmaticAdId = await CloudX.createBanner(
          placementName: widget.environment.bannerPlacementName,
          position: _selectedPosition,
          listener: _createBannerListener('Programmatic Banner'),
        );

        DemoAppLogger.sharedInstance.logMessage(
            '🎯 Created programmatic banner at ${_selectedPosition.value}');

        // Load the banner
        if (_programmaticAdId != null) {
          await CloudX.loadBanner(adId: _programmaticAdId!);
          DemoAppLogger.sharedInstance.logMessage('📥 Loading programmatic banner');
        }

        // Start auto-refresh (enabled by default)
        if (_isAutoRefreshEnabled && _programmaticAdId != null) {
          await CloudX.startAutoRefresh(adId: _programmaticAdId!);
          DemoAppLogger.sharedInstance
              .logMessage('🔄 Auto-refresh started (enabled by default)');
        }
      } catch (e) {
        DemoAppLogger.sharedInstance
            .logMessage('❌ Error creating programmatic banner: $e');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Error: $e', color: Colors.red);
        setState(() {
          _showBanner = false;
        });
      }
    }
  }

  Widget _buildAutoRefreshControls() {
    // Only show when banner is loaded
    if (!_showBanner) {
      return const SizedBox.shrink();
    }

    // Don't show for widget-based if controller not attached
    if (!_useProgrammaticBanner && !_bannerController.isAttached) {
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
      widgetAction: () => _bannerController.startAutoRefresh(),
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
      widgetAction: () => _bannerController.stopAutoRefresh(),
    );

    setState(() {
      _isAutoRefreshEnabled = false;
    });
    DemoAppLogger.sharedInstance.logMessage('⏸️ Auto-refresh stopped');
    setCustomStatus(text: 'Auto-refresh stopped', color: Colors.orange);
  }

  /// Helper to perform auto-refresh actions for both banner modes
  Future<void> _performAutoRefreshAction({
    required Future<void> Function() programmaticAction,
    required Future<void> Function() widgetAction,
  }) async {
    if (_useProgrammaticBanner && _programmaticAdId != null) {
      await programmaticAction();
    } else {
      await widgetAction();
    }
  }

  Widget _buildBannerContainer() {
    if (!_showBanner) {
      return _buildPlaceholderContainer(
        icon: Icon(
          _useProgrammaticBanner ? Icons.fullscreen : Icons.view_compact,
          size: _iconSizeLarge,
          color: Colors.grey[400],
        ),
        title:
            _useProgrammaticBanner ? 'Programmatic Mode' : 'Widget-based Mode',
        description: _useProgrammaticBanner
            ? 'Banner will overlay at\nselected screen position'
            : 'Banner will render here\nin the widget tree',
        backgroundColor: Colors.grey[100]!,
        borderColor: Colors.grey[300]!,
        titleColor: Colors.grey[700]!,
        descriptionColor: Colors.grey[600]!,
      );
    }

    // Programmatic banners don't render in this container
    if (_useProgrammaticBanner) {
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
                    color: Colors.blue.withValues(alpha: 0.2),
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
              'Banner Active',
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

    // Widget-based banner
    return Center(
      child: CloudXBannerView(
        placementName: widget.environment.bannerPlacementName,
        width: 320,
        height: 50,
        controller: _bannerController,
        listener: _createBannerListener('Banner Ad'),
      ),
    );
  }

  /// Creates a CloudXAdViewListener with appropriate callbacks for banner ads
  CloudXAdViewListener _createBannerListener(String adType) {
    return CloudXAdViewListener(
      onAdLoaded: (ad) {
        DemoAppLogger.sharedInstance.logAdEvent('✅ $adType Loaded', ad);
        setAdState(AdState.ready);
        setCustomStatus(text: '$adType Loaded', color: Colors.green);

        // Auto-show programmatic banners
        if (_useProgrammaticBanner && _programmaticAdId != null) {
          CloudX.showBanner(adId: _programmaticAdId!);
        }
      },
      onAdLoadFailed: (error) {
        DemoAppLogger.sharedInstance.logMessage('❌ $adType Failed: $error');
        setAdState(AdState.noAd);
        setCustomStatus(text: 'Failed to load: $error', color: Colors.red);
        if (_useProgrammaticBanner) {
          setState(() {
            _showBanner = false;
          });
        }
      },
      onAdDisplayed: (ad) {
        DemoAppLogger.sharedInstance.logAdEvent('📺 $adType Displayed', ad);
        final positionText =
            _useProgrammaticBanner ? ' at ${_selectedPosition.value}' : '';
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
    _bannerController.dispose();
    // Clean up programmatic banner if exists
    if (_programmaticAdId != null) {
      CloudX.destroyAd(adId: _programmaticAdId!);
    }
    super.dispose();
  }
}
