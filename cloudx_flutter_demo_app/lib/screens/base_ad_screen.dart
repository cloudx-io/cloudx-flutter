import 'package:flutter/material.dart';
import '../utils/demo_app_logger.dart';
import 'logs_modal_screen.dart';

/// Base screen that provides common functionality for all ad screens
abstract class BaseAdScreen extends StatefulWidget {
  final bool isSDKInitialized;

  const BaseAdScreen({
    super.key,
    required this.isSDKInitialized,
  });
}

abstract class BaseAdScreenState<T extends BaseAdScreen> extends State<T> {
  AdState _adState = AdState.noAd;
  bool _isLoading = false;

  // Add custom status fields
  String? _customStatusText;
  Color? _customStatusColor;
  
  // Track the last ad format for log clearing
  static String? _lastAdFormat;

  AdState get adState => _adState;
  bool get isLoading => _isLoading;

  // Add setter for custom status
  void setCustomStatus({String? text, Color? color}) {
    setState(() {
      _customStatusText = text;
      _customStatusColor = color;
    });
  }

  @override
  void initState() {
    super.initState();
    
    // Clear logs when switching between different ad formats (tabs)
    final currentAdFormat = runtimeType.toString();
    
    if (_lastAdFormat != null && _lastAdFormat != currentAdFormat) {
      // Switching between different ad formats - clear logs for clean slate
      DemoAppLogger.sharedInstance.clearLogs();
      DemoAppLogger.sharedInstance.logMessage('[$currentAdFormat] Switched from $_lastAdFormat - logs cleared');
    }
    
    // Remember current ad format for next time (session only)
    _lastAdFormat = currentAdFormat;
  }

  void showErrorDialog(String title, String message) {
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

  void setLoadingState(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) {
        _adState = AdState.loading;
      }
    });
  }

  void setAdState(AdState state) {
    setState(() {
      _adState = state;
    });
  }

  /// Override this method to provide the ad ID prefix for this screen
  String getAdIdPrefix();

  /// Override this method to implement ad loading logic
  Future<void> loadAd();

  /// Override this method to implement ad showing logic
  Future<void> showAd();

  @override
  Widget build(BuildContext context) {
    return buildScreen(context);
  }

  /// Build the screen scaffold - can be overridden for AutomaticKeepAliveClientMixin
  Widget buildScreen(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: buildMainContent(),
            ),
          ),
          _buildStatusUI(),
        ],
      ),
    );
  }
  

  /// Override this method to provide the main content for each screen
  Widget buildMainContent();

  Widget _buildStatusUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _customStatusColor ?? _getStatusColor(),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _customStatusText ?? _getStatusText(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _customStatusColor ?? _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (_adState) {
      case AdState.noAd:
        return 'No Ad Loaded';
      case AdState.loading:
        return 'Loading Ad...';
      case AdState.ready:
        return 'Ad Ready';
    }
  }

  Color _getStatusColor() {
    switch (_adState) {
      case AdState.noAd:
        return Colors.red;
      case AdState.loading:
        return Colors.orange;
      case AdState.ready:
        return Colors.green;
    }
  }

  Widget _buildCenteredButton({
    required String title,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildLoadAndShowButton() {
    return Column(
      children: [
        _buildCenteredButton(
          title: _isLoading ? 'Loading...' : 'Load Ad',
          onPressed: _isLoading ? () {} : loadAd,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        _buildCenteredButton(
          title: 'Show Ad',
          onPressed: _adState == AdState.ready ? showAd : () {},
          enabled: _adState == AdState.ready,
        ),
      ],
    );
  }
}

// Simple enum for ad state
enum AdState {
  noAd,
  loading,
  ready,
} 