import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudx_flutter/cloudx.dart';

class MRECScreen extends StatefulWidget {
  const MRECScreen({super.key});

  @override
  State<MRECScreen> createState() => _MRECScreenState();
}

class _MRECScreenState extends State<MRECScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  final CloudXAdViewController _controller = CloudXAdViewController();
  bool _showMREC = false;
  bool _autoRefreshEnabled = true; // Auto-refresh is enabled by default in SDK
  String _placementName = 'flutterMrec';

  @override
  void initState() {
    super.initState();
    _loadPlacementName();
  }

  Future<void> _loadPlacementName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _placementName = Platform.isIOS
          ? (prefs.getString('iosMrecPlacement') ?? 'flutterMreciOS')
          : (prefs.getString('androidMrecPlacement') ?? 'flutterMrec');
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
          if (_showMREC) _buildMRECDisplay(),
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
            'MREC Ad Logs',
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
          'No logs yet. Load MREC to see logs.',
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

  Widget _buildMRECDisplay() {
    return Container(
      height: 250,
      color: Colors.grey[200],
      child: Center(
        child: CloudXMRECView(
          placementName: _placementName,
          width: 300,
          height: 250,
          controller: _controller,
          listener: _createMRECListener(),
        ),
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
            onPressed: _showMREC ? _toggleAutoRefresh : null,
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
          // Load/Stop MREC Button
          ElevatedButton(
            onPressed: _toggleMREC,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: _showMREC ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _showMREC ? 'Stop MREC' : 'Load MREC Ad',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMREC() async {
    setState(() {
      _showMREC = !_showMREC;
    });

    if (_showMREC) {
      _logs.clear();
      _addLog('▶️ TEST: Loading MREC ad (widget-based)');
      _addLog('📋 Placement: $_placementName');
      _addLog('🔄 Auto-refresh: ENABLED (default)');
    } else {
      _addLog('🗑️ TEST: Stopping MREC');
      // Reset auto-refresh state when stopping MREC
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

  CloudXAdViewListener _createMRECListener() {
    return CloudXAdViewListener(
      onAdLoaded: (ad) {
        _addLog('📞 CALLBACK: onAdLoaded');
        _addLog('📦 Bidder: ${ad.bidder ?? "unknown"}');
        _addLog('📦 Revenue: \$${ad.revenue ?? 0.0}');
        _addLog('📦 Bidder: ${ad.bidder ?? "unknown"}');
        _addLog('✅ TEST PASS: MREC loaded');
        _addLog('===============================');
      },
      onAdLoadFailed: (error) {
        _addLog('📞 CALLBACK: onAdLoadFailed');
        _addLog('❌ TEST FAIL: MREC failed to load');
        _addLog('❌ Error: $error');
        _addLog('===============================');
      },
      onAdDisplayed: (ad) {
        _addLog('📞 CALLBACK: onAdDisplayed');
        _addLog('✅ TEST PASS: MREC displayed');
        _addLog('===============================');
      },
      onAdDisplayFailed: (error) {
        _addLog('📞 CALLBACK: onAdDisplayFailed');
        _addLog('❌ Error: $error');
        _addLog('===============================');
      },
      onAdClicked: (ad) {
        _addLog('📞 CALLBACK: onAdClicked');
        _addLog('✅ TEST PASS: MREC clicked');
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
