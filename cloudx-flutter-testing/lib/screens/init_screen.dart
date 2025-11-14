import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../services/sdk_manager.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  final ScrollController _scrollController = ScrollController();
  final SDKManager _sdkManager = SDKManager();
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when logs update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _requestATTPermission() async {
    if (!Platform.isIOS) {
      _sdkManager.addLog('⚠️ ATT is only available on iOS');
      setState(() {});
      return;
    }

    _sdkManager.addLog('🔐 Requesting ATT permission...');
    setState(() {});

    try {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      _sdkManager.addLog('🔐 ATT Status: ${status.name}');

      if (status == TrackingStatus.authorized) {
        _sdkManager.addLog('✅ Tracking authorized - user data will be included in bid requests');
      } else {
        _sdkManager.addLog('❌ Tracking not authorized - user data will be cleared for privacy');
      }
    } catch (e) {
      _sdkManager.addLog('❌ ATT request error: $e');
    }

    setState(() {});
    _scrollToBottom();
  }

  Future<void> _initializeSDK() async {
    if (_isInitializing || _sdkManager.isInitialized) return;

    setState(() {
      _isInitializing = true;
    });

    await _sdkManager.initialize();

    setState(() {
      _isInitializing = false;
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Logs Section
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Logs Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      const Icon(Icons.article_outlined, color: Colors.black87, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Initialization Logs',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _sdkManager.clearLogs();
                          setState(() {});
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logs List
                Expanded(
                  child: _sdkManager.logs.isEmpty
                      ? const Center(
                          child: Text(
                            'SDK initialization logs will appear here.',
                            style: TextStyle(color: Colors.black38),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _sdkManager.logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _sdkManager.logs[index],
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Button Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              // ATT Permission Button (iOS only, before initialization)
              if (!_sdkManager.isInitialized && Platform.isIOS) ...[
                OutlinedButton.icon(
                  onPressed: _requestATTPermission,
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Request Tracking Permission (iOS)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Initialize Button
              if (!_sdkManager.isInitialized)
                ElevatedButton(
                  onPressed: _isInitializing ? null : _initializeSDK,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: _isInitializing ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isInitializing ? 'Initializing...' : 'Initialize SDK',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

              // Status (when initialized)
              if (_sdkManager.isInitialized) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SDK Initialized ✓',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CloudX SDK ${_sdkManager.sdkVersion} is ready',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _sdkManager.reset();
                    setState(() {});
                  },
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Stop SDK'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
        ],
      ),
    );
  }
}
