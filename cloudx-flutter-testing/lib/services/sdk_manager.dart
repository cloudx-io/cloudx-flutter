import 'dart:io' show Platform;
import 'package:cloudx_flutter/cloudx.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SDKManager {
  static final SDKManager _instance = SDKManager._internal();

  factory SDKManager() => _instance;

  SDKManager._internal();

  bool _isInitialized = false;
  String _sdkVersion = 'Unknown';

  bool get isInitialized => _isInitialized;
  String get sdkVersion => _sdkVersion;

  final List<String> _logs = [];

  List<String> get logs => List.unmodifiable(_logs);

  void addLog(String message) {
    _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
  }

  void _addLog(String message) {
    addLog(message);
  }

  Future<bool> initialize() async {
    if (_isInitialized) {
      _addLog('⚠️ TEST: SDK already initialized (skipped)');
      return true;
    }

    _addLog('▶️ TEST: Starting SDK initialization');

    try {
      // Load platform-specific app key from settings
      final prefs = await SharedPreferences.getInstance();
      final appKey = Platform.isIOS
          ? (prefs.getString('iosAppKey') ?? 'uOPdnQC_zu0gJs8HP3cBs')
          : (prefs.getString('androidAppKey') ?? '69TdNnN1EcNpeyWWkLhBS');
      _addLog('📋 TEST: Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
      _addLog('📋 TEST: App Key: ${appKey.substring(0, 8)}...');

      // Set environment to production (iOS app key is for production)
      _addLog('⚙️ TEST: Setting environment to PRODUCTION');
      await CloudX.setEnvironment('production');

      // Enable SDK logging
      _addLog('⚙️ TEST: Enabling SDK logging');
      await CloudX.setLoggingEnabled(true);

      // Apply privacy settings (before initialization)
      _addLog('⚙️ TEST: Applying privacy settings');
      await _applyPrivacySettings(prefs);

      // Apply user targeting settings (before initialization)
      _addLog('⚙️ TEST: Applying user targeting settings');
      await _applyUserTargetingSettings(prefs);

      // Call initialize
      _addLog('⚙️ TEST: Calling CloudX.initialize()');
      final success = await CloudX.initialize(
        appKey: appKey,
      );

      // Log result
      if (success) {
        _addLog('✅ TEST PASS: initialize() returned TRUE');

        // Get SDK version
        _sdkVersion = await CloudX.getVersion();
        _addLog('📦 TEST: SDK Version: $_sdkVersion');

        _addLog('✅ TEST PASS: SDK initialized successfully');
        _isInitialized = true;
        return true;
      } else {
        _addLog('❌ TEST FAIL: initialize() returned FALSE');
        _addLog('ℹ️ Check native logs for details');
        return false;
      }
    } catch (e) {
      _addLog('⚠️ UNEXPECTED: Exception: $e');
      return false;
    }
  }

  void clearLogs() {
    _logs.clear();
  }

  Future<void> reset() async {
    _addLog('🔄 TEST: Reset requested');

    // Note: deinitialize() not available in SDK 0.1.0
    // _addLog('⚙️ TEST: Calling CloudX.deinitialize()');
    // await CloudX.deinitialize();
    // _addLog('✅ TEST: CloudX.deinitialize() completed');

    // Reset local state
    _isInitialized = false;
    _addLog('✅ TEST: Local state reset (SDK deinitialize not available in 0.1.0)');
    _addLog('ℹ️ NOTE: SDK will remain initialized - restart app for full reset');
  }

  Future<void> _applyPrivacySettings(SharedPreferences prefs) async {
    final ccpaEnabled = prefs.getBool('ccpaEnabled') ?? false;
    final coppaEnabled = prefs.getBool('coppaEnabled') ?? false;
    final gppEnabled = prefs.getBool('gppEnabled') ?? false;

    // CCPA
    if (ccpaEnabled) {
      await CloudX.setCCPAPrivacyString('1YNN');
      _addLog('   ✓ CCPA: Enabled (1YNN)');
    } else {
      await CloudX.setCCPAPrivacyString(null);
      _addLog('   ✗ CCPA: Disabled');
    }

    // COPPA
    if (coppaEnabled) {
      await CloudX.setIsAgeRestrictedUser(true);
      _addLog('   ✓ COPPA: Enabled (age restricted)');
    } else {
      await CloudX.setIsAgeRestrictedUser(false);
      _addLog('   ✗ COPPA: Disabled');
    }

    // GPP
    if (gppEnabled) {
      await CloudX.setGPPString('DBABrw~BAAUAAAAAABA.QA~BAUAAABA.QA');
      await CloudX.setGPPSid([7, 8]);
      _addLog('   ✓ GPP: Enabled (US National + CA, both opt-out)');
    } else {
      await CloudX.setGPPString(null);
      await CloudX.setGPPSid(null);
      _addLog('   ✗ GPP: Disabled');
    }
  }

  Future<void> _applyUserTargetingSettings(SharedPreferences prefs) async {
    // Clear all previously set key-values first
    // (SDK doesn't have individual remove methods, so we clear all then set only enabled ones)
    await CloudX.clearAllKeyValues();
    _addLog('   🗑️ Cleared all previous key-values');

    // User ID
    final userIdEnabled = prefs.getBool('userIdEnabled') ?? false;
    if (userIdEnabled) {
      await CloudX.setUserID('user_12345');
      _addLog('   ✓ User ID: user_12345');
    } else {
      await CloudX.setUserID(null);
      _addLog('   ✗ User ID: Disabled');
    }

    // User Key-Value
    final userKeyValueEnabled = prefs.getBool('userKeyValueEnabled') ?? false;
    if (userKeyValueEnabled) {
      await CloudX.setUserKeyValue('age', '25');
      _addLog('   ✓ User KV: age=25');
    } else {
      _addLog('   ✗ User KV: Disabled');
    }

    // App Key-Value
    final appKeyValueEnabled = prefs.getBool('appKeyValueEnabled') ?? false;
    if (appKeyValueEnabled) {
      await CloudX.setAppKeyValue('flutter_version', '1.0.0');
      _addLog('   ✓ App KV: flutter_version=1.0.0');
    } else {
      _addLog('   ✗ App KV: Disabled');
    }
  }
}
