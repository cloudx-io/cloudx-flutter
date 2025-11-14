import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudx_flutter/cloudx.dart';

class InterstitialScreen extends StatefulWidget {
  const InterstitialScreen({super.key});

  @override
  State<InterstitialScreen> createState() => _InterstitialScreenState();
}

class _InterstitialScreenState extends State<InterstitialScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _logs = [];
  String? _adId;
  String _placementName = 'flutterInterstitial';
  bool _isLoading = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _loadPlacementName();
  }

  Future<void> _loadPlacementName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _placementName = Platform.isIOS
          ? (prefs.getString('iosInterstitialPlacement') ?? 'flutterInterstitialiOS')
          : (prefs.getString('androidInterstitialPlacement') ?? 'flutterInterstitial');
    });
  }

  @override
  void dispose() {
    if (_adId != null) {
      CloudX.destroyAd(adId: _adId!);
    }
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
          _buildActionButtons(),
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
            'Interstitial Ad Logs',
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
          'No logs yet. Load interstitial to see logs.',
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Load Button
          ElevatedButton(
            onPressed: _isLoading ? null : _loadInterstitial,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _isLoading ? 'Loading...' : 'Load Interstitial',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          // Show Button
          ElevatedButton(
            onPressed: _isReady ? _showInterstitial : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Show Interstitial',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInterstitial() async {
    setState(() {
      _isLoading = true;
      _isReady = false;
      _logs.clear();
    });

    _addLog('▶️ TEST: Creating interstitial ad');
    _addLog('📋 Placement: $_placementName');

    try {
      // Create interstitial
      _adId = await CloudX.createInterstitial(
        placementName: _placementName,
        listener: _createInterstitialListener(),
      );

      if (_adId != null) {
        _addLog('✅ Created with adId: $_adId');
        _addLog('▶️ TEST: Loading interstitial');

        // Load interstitial
        final success = await CloudX.loadInterstitial(adId: _adId!);
        if (!success) {
          _addLog('❌ TEST FAIL: loadInterstitial() returned false');
          setState(() => _isLoading = false);
        }
      } else {
        _addLog('❌ TEST FAIL: createInterstitial() returned null');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _addLog('❌ ERROR: Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showInterstitial() async {
    if (_adId == null) {
      _addLog('❌ ERROR: No ad loaded');
      return;
    }

    _addLog('▶️ TEST: Checking if interstitial is ready');
    final isReady = await CloudX.isInterstitialReady(adId: _adId!);

    if (isReady) {
      _addLog('✅ Interstitial is ready');
      _addLog('▶️ TEST: Showing interstitial');

      final success = await CloudX.showInterstitial(adId: _adId!);
      if (!success) {
        _addLog('❌ TEST FAIL: showInterstitial() returned false');
      }
    } else {
      _addLog('❌ TEST FAIL: Interstitial not ready');
    }
  }

  CloudXInterstitialListener _createInterstitialListener() {
    return CloudXInterstitialListener(
      onAdLoaded: (ad) {
        _addLog('📞 CALLBACK: onAdLoaded');
        _addLog('📦 Placement: ${ad.placementName ?? "unknown"}');
        _addLog('📦 Placement ID: ${ad.placementId ?? "unknown"}');
        _addLog('📦 Bidder/Network: ${ad.bidder ?? "unknown"}');
        _addLog('📦 External ID: ${ad.externalPlacementId ?? "N/A"}');
        _addLog('📦 Revenue: \$${ad.revenue ?? 0.0}');
        _addLog('✅ TEST PASS: Interstitial loaded');
        _addLog('===============================');
        setState(() {
          _isLoading = false;
          _isReady = true;
        });
      },
      onAdLoadFailed: (error) {
        _addLog('📞 CALLBACK: onAdLoadFailed');
        _addLog('❌ TEST FAIL: Interstitial failed to load');
        _addLog('❌ Error: $error');
        _addLog('===============================');
        setState(() {
          _isLoading = false;
          _isReady = false;
        });
      },
      onAdDisplayed: (ad) {
        _addLog('📞 CALLBACK: onAdDisplayed');
        _addLog('✅ TEST PASS: Interstitial displayed');
        _addLog('===============================');
      },
      onAdDisplayFailed: (error) {
        _addLog('📞 CALLBACK: onAdDisplayFailed');
        _addLog('❌ Error: $error');
        _addLog('===============================');
      },
      onAdClicked: (ad) {
        _addLog('📞 CALLBACK: onAdClicked');
        _addLog('✅ TEST PASS: Interstitial clicked');
        _addLog('===============================');
      },
      onAdHidden: (ad) {
        _addLog('📞 CALLBACK: onAdHidden');
        _addLog('✅ TEST PASS: Interstitial closed');
        _addLog('===============================');
        setState(() {
          _isReady = false;
        });
        // Destroy ad after it's closed
        if (_adId != null) {
          CloudX.destroyAd(adId: _adId!);
          _adId = null;
          _addLog('🗑️ Ad destroyed');
        }
      },
    );
  }

}
