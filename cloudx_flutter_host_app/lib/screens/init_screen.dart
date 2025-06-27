import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';

class InitScreen extends StatefulWidget {
  final CloudXFlutterSdk cloudX;
  final bool isSDKInitialized;
  final VoidCallback onSDKInitialized;

  const InitScreen({
    super.key,
    required this.cloudX,
    required this.isSDKInitialized,
    required this.onSDKInitialized,
  });

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Flutter Demo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            _buildInitButton(),
            const SizedBox(height: 20),
            _buildStatusIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitButton() {
    return ElevatedButton(
      onPressed: _isLoading || widget.isSDKInitialized ? null : _initializeSDK,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        _getButtonText(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getButtonText() {
    if (widget.isSDKInitialized) {
      return 'SDK Already Initialized';
    }
    if (_isLoading) {
      return 'Initializing...';
    }
    return 'Initialize SDK';
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    String statusText;

    if (widget.isSDKInitialized) {
      statusColor = Colors.green;
      statusText = 'SDK Ready';
    } else if (_isLoading) {
      statusColor = Colors.orange;
      statusText = 'Initializing...';
    } else {
      statusColor = Colors.red;
      statusText = 'SDK Not Initialized';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Future<void> _initializeSDK() async {
    if (widget.isSDKInitialized) {
      _showAlert('SDK Already Initialized', 'The SDK is already initialized.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.cloudX.initSDK(
        appKey: 'qT9U-tJ0FRb0x4gXb-pF0',
        hashedUserID: 'test-user-123',
      );

      if (success) {
        widget.onSDKInitialized();
        _showAlert('Success', 'SDK initialized successfully!');
      } else {
        _showAlert('SDK Init Failed', 'Failed to initialize SDK.');
      }
    } catch (e) {
      _showAlert('SDK Init Failed', 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlert(String title, String message) {
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
} 