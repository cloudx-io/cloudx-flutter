import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudx_flutter/cloudx.dart';

class BannerScreen extends StatefulWidget {
  const BannerScreen({super.key});

  @override
  State<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends State<BannerScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  final CloudXAdViewController _controller = CloudXAdViewController();
  bool _showBanner = false;
  bool _autoRefreshEnabled = true; // Auto-refresh is enabled by default in SDK
  String _placementName = 'flutterBanner';

  @override
  void initState() {
    super.initState();
    _loadPlacementName();
  }

  Future<void> _loadPlacementName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _placementName = Platform.isIOS
          ? (prefs.getString('iosBannerPlacement') ?? 'flutterBanneriOS')
          : (prefs.getString('androidBannerPlacement') ?? 'flutterBanner');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(child: _buildLogsSection()),
          if (_showBanner) _buildBannerDisplay(),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogsHeader(),
          Expanded(child: _buildLogsList()),
        ],
      ),
    );
  }

  Widget _buildLogsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[200],
      child: Row(
        children: [
          const Icon(Icons.article_outlined, color: Colors.black87, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Banner Ad Logs',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _logs.clear()),
            child: const Text('Clear', style: TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'No logs yet. Load banner to see logs.',
          style: TextStyle(color: Colors.black38),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            _logs[index],
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerDisplay() {
    return Container(
      height: 50,
      color: Colors.grey[200],
      child: CloudXBannerView(
        placementName: _placementName,
        width: 320,
        height: 50,
        controller: _controller,
        listener: _createBannerListener(),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Auto-Refresh Toggle Button
          ElevatedButton(
            onPressed: _showBanner ? _toggleAutoRefresh : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: _autoRefreshEnabled ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _autoRefreshEnabled ? 'Stop Auto-Refresh' : 'Start Auto-Refresh',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          // Load/Stop Banner Button
          ElevatedButton(
            onPressed: _toggleBanner,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: _showBanner ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _showBanner ? 'Stop Banner' : 'Load Banner Ad',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBanner() async {
    setState(() {
      _showBanner = !_showBanner;
    });

    if (_showBanner) {
      _logs.clear();
      _addLog('▶️ TEST: Loading banner ad (widget-based)');
      _addLog('📋 Placement: $_placementName');
      _addLog('🔄 Auto-refresh: ENABLED (default)');
    } else {
      _addLog('🗑️ TEST: Stopping banner');
      // Reset auto-refresh state when stopping banner
      setState(() {
        _autoRefreshEnabled = true;
      });
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });

    if (_autoRefreshEnabled) {
      _addLog('🔄 TEST: Starting auto-refresh');
      _controller.startAutoRefresh();
      _addLog('✅ Auto-refresh enabled - timer will resume');
    } else {
      _addLog('⏸️ TEST: Stopping auto-refresh');
      _controller.stopAutoRefresh();
      _addLog('✅ Auto-refresh paused - timer frozen');
    }
  }

  CloudXAdViewListener _createBannerListener() {
    return CloudXAdViewListener(
      onAdLoaded: (ad) {
        _addLog('📞 CALLBACK: onAdLoaded');
        _addLog('📦 Placement: ${ad.placementName ?? "unknown"}');
        _addLog('📦 Placement ID: ${ad.placementId ?? "unknown"}');
        _addLog('📦 Bidder/Network: ${ad.bidder ?? "unknown"}');
        _addLog('📦 External ID: ${ad.externalPlacementId ?? "N/A"}');
        _addLog('📦 Revenue: \$${ad.revenue ?? 0.0}');
        _addLog('✅ TEST PASS: Banner loaded');
        _addLog('===============================');
      },
      onAdLoadFailed: (error) {
        _addLog('📞 CALLBACK: onAdLoadFailed');
        _addLog('❌ TEST FAIL: Banner failed to load');
        _addLog('❌ Error: $error');
        _addLog('===============================');
      },
      onAdDisplayed: (ad) {
        _addLog('📞 CALLBACK: onAdDisplayed');
        _addLog('✅ TEST PASS: Banner displayed');
        _addLog('===============================');
      },
      onAdDisplayFailed: (error) {
        _addLog('📞 CALLBACK: onAdDisplayFailed');
        _addLog('❌ Error: $error');
        _addLog('===============================');
      },
      onAdClicked: (ad) {
        _addLog('📞 CALLBACK: onAdClicked');
        _addLog('✅ TEST PASS: Banner clicked');
        _addLog('===============================');
      },
      onAdHidden: (ad) {
        _addLog('📞 CALLBACK: onAdHidden');
      },
      onAdExpanded: (ad) {
        _addLog('📞 CALLBACK: onAdExpanded');
      },
      onAdCollapsed: (ad) {
        _addLog('📞 CALLBACK: onAdCollapsed');
      },
    );
  }
}
