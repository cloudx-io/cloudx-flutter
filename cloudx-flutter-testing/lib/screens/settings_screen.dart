import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controllers for text fields - iOS
  final _iosAppKeyController = TextEditingController();
  final _iosBannerPlacementController = TextEditingController();
  final _iosMrecPlacementController = TextEditingController();
  final _iosInterstitialPlacementController = TextEditingController();

  // Controllers for text fields - Android
  final _androidAppKeyController = TextEditingController();
  final _androidBannerPlacementController = TextEditingController();
  final _androidMrecPlacementController = TextEditingController();
  final _androidInterstitialPlacementController = TextEditingController();

  final _userIdController = TextEditingController();

  // Privacy toggles
  bool _ccpaEnabled = false;
  bool _coppaEnabled = false;
  bool _gppEnabled = false;

  // User Targeting toggles
  bool _userIdEnabled = false;
  bool _userKeyValueEnabled = false;
  bool _appKeyValueEnabled = false;

  // Default values - iOS
  static const String _defaultIosAppKey = 'uOPdnQC_zu0gJs8HP3cBs';
  static const String _defaultIosBanner = 'flutterBanneriOS';
  static const String _defaultIosMrec = 'flutterMreciOS';
  static const String _defaultIosInterstitial = 'flutterInterstitialiOS';

  // Default values - Android
  static const String _defaultAndroidAppKey = '69TdNnN1EcNpeyWWkLhBS';
  static const String _defaultAndroidBanner = 'flutterBanner';
  static const String _defaultAndroidMrec = 'flutterMrec';
  static const String _defaultAndroidInterstitial = 'flutterInterstitial';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _iosAppKeyController.dispose();
    _iosBannerPlacementController.dispose();
    _iosMrecPlacementController.dispose();
    _iosInterstitialPlacementController.dispose();
    _androidAppKeyController.dispose();
    _androidBannerPlacementController.dispose();
    _androidMrecPlacementController.dispose();
    _androidInterstitialPlacementController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // iOS settings
      _iosAppKeyController.text = prefs.getString('iosAppKey') ?? _defaultIosAppKey;
      _iosBannerPlacementController.text = prefs.getString('iosBannerPlacement') ?? _defaultIosBanner;
      _iosMrecPlacementController.text = prefs.getString('iosMrecPlacement') ?? _defaultIosMrec;
      _iosInterstitialPlacementController.text = prefs.getString('iosInterstitialPlacement') ?? _defaultIosInterstitial;

      // Android settings
      _androidAppKeyController.text = prefs.getString('androidAppKey') ?? _defaultAndroidAppKey;
      _androidBannerPlacementController.text = prefs.getString('androidBannerPlacement') ?? _defaultAndroidBanner;
      _androidMrecPlacementController.text = prefs.getString('androidMrecPlacement') ?? _defaultAndroidMrec;
      _androidInterstitialPlacementController.text = prefs.getString('androidInterstitialPlacement') ?? _defaultAndroidInterstitial;

      _userIdController.text = prefs.getString('userId') ?? '';
      _ccpaEnabled = prefs.getBool('ccpaEnabled') ?? false;
      _coppaEnabled = prefs.getBool('coppaEnabled') ?? false;
      _gppEnabled = prefs.getBool('gppEnabled') ?? false;

      // User Targeting
      _userIdEnabled = prefs.getBool('userIdEnabled') ?? false;
      _userKeyValueEnabled = prefs.getBool('userKeyValueEnabled') ?? false;
      _appKeyValueEnabled = prefs.getBool('appKeyValueEnabled') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // iOS settings
    await prefs.setString('iosAppKey', _iosAppKeyController.text);
    await prefs.setString('iosBannerPlacement', _iosBannerPlacementController.text);
    await prefs.setString('iosMrecPlacement', _iosMrecPlacementController.text);
    await prefs.setString('iosInterstitialPlacement', _iosInterstitialPlacementController.text);

    // Android settings
    await prefs.setString('androidAppKey', _androidAppKeyController.text);
    await prefs.setString('androidBannerPlacement', _androidBannerPlacementController.text);
    await prefs.setString('androidMrecPlacement', _androidMrecPlacementController.text);
    await prefs.setString('androidInterstitialPlacement', _androidInterstitialPlacementController.text);

    await prefs.setString('userId', _userIdController.text);
    await prefs.setBool('ccpaEnabled', _ccpaEnabled);
    await prefs.setBool('coppaEnabled', _coppaEnabled);
    await prefs.setBool('gppEnabled', _gppEnabled);

    // User Targeting
    await prefs.setBool('userIdEnabled', _userIdEnabled);
    await prefs.setBool('userKeyValueEnabled', _userKeyValueEnabled);
    await prefs.setBool('appKeyValueEnabled', _appKeyValueEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Platform Indicator
          _buildPlatformIndicator(),
          const SizedBox(height: 16),

          // iOS Configuration Section
          _buildSectionHeader('iOS Configuration'),
          _buildTextField(
            controller: _iosAppKeyController,
            label: 'iOS App Key',
            hint: 'CloudX iOS App Key',
            enabled: Platform.isIOS,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _iosBannerPlacementController,
            label: 'iOS Banner Placement',
            hint: 'e.g., flutterBanneriOS',
            enabled: Platform.isIOS,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _iosMrecPlacementController,
            label: 'iOS MREC Placement',
            hint: 'e.g., flutterMreciOS',
            enabled: Platform.isIOS,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _iosInterstitialPlacementController,
            label: 'iOS Interstitial Placement',
            hint: 'e.g., flutterInterstitialiOS',
            enabled: Platform.isIOS,
          ),
          const SizedBox(height: 24),

          // Android Configuration Section
          _buildSectionHeader('Android Configuration'),
          _buildTextField(
            controller: _androidAppKeyController,
            label: 'Android App Key',
            hint: 'CloudX Android App Key',
            enabled: Platform.isAndroid,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _androidBannerPlacementController,
            label: 'Android Banner Placement',
            hint: 'e.g., flutterBanner',
            enabled: Platform.isAndroid,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _androidMrecPlacementController,
            label: 'Android MREC Placement',
            hint: 'e.g., flutterMrec',
            enabled: Platform.isAndroid,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _androidInterstitialPlacementController,
            label: 'Android Interstitial Placement',
            hint: 'e.g., flutterInterstitial',
            enabled: Platform.isAndroid,
          ),
          const SizedBox(height: 24),

          // Privacy Section
          _buildSectionHeader('Privacy Settings'),
          _buildSwitchTile(
            title: 'CCPA (Do Not Sell)',
            subtitle: 'Enable CCPA privacy string',
            value: _ccpaEnabled,
            onChanged: (value) => setState(() => _ccpaEnabled = value),
          ),
          _buildSwitchTile(
            title: 'COPPA (Age Restricted)',
            subtitle: 'User is under 13',
            value: _coppaEnabled,
            onChanged: (value) => setState(() => _coppaEnabled = value),
          ),
          _buildSwitchTile(
            title: 'GPP (Global Privacy Platform)',
            subtitle: 'US National + California opt-out',
            value: _gppEnabled,
            onChanged: (value) => setState(() => _gppEnabled = value),
          ),
          const SizedBox(height: 24),

          // User Targeting Section
          _buildSectionHeader('User Targeting'),

          // User ID Toggle
          _buildSwitchTile(
            title: 'User ID',
            subtitle: 'Value: user_12345',
            value: _userIdEnabled,
            onChanged: (value) => setState(() => _userIdEnabled = value),
          ),
          const SizedBox(height: 12),

          // User Key-Value Toggle
          _buildSwitchTile(
            title: 'User Key-Value',
            subtitle: 'age=25',
            value: _userKeyValueEnabled,
            onChanged: (value) => setState(() => _userKeyValueEnabled = value),
          ),
          const SizedBox(height: 12),

          // App Key-Value Toggle
          _buildSwitchTile(
            title: 'App Key-Value',
            subtitle: 'flutter_version=1.0.0',
            value: _appKeyValueEnabled,
            onChanged: (value) => setState(() => _appKeyValueEnabled = value),
          ),
          const SizedBox(height: 24),

          // Save Button
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Save Settings'),
          ),
          const SizedBox(height: 16),

          // Reset to Defaults Button
          OutlinedButton(
            onPressed: _resetToDefaults,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Reset to Defaults'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPlatformIndicator() {
    final isIOS = Platform.isIOS;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isIOS ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIOS ? Colors.blue : Colors.green,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isIOS ? Icons.apple : Icons.android,
            color: isIOS ? Colors.blue : Colors.green,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Platform: ${isIOS ? 'iOS' : 'Android'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIOS ? Colors.blue.shade900 : Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isIOS
                      ? 'iOS configuration will be used'
                      : 'Android configuration will be used',
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey.shade100 : null,
      ),
      style: TextStyle(
        color: !enabled ? Colors.grey.shade500 : null,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      // iOS defaults
      _iosAppKeyController.text = _defaultIosAppKey;
      _iosBannerPlacementController.text = _defaultIosBanner;
      _iosMrecPlacementController.text = _defaultIosMrec;
      _iosInterstitialPlacementController.text = _defaultIosInterstitial;

      // Android defaults
      _androidAppKeyController.text = _defaultAndroidAppKey;
      _androidBannerPlacementController.text = _defaultAndroidBanner;
      _androidMrecPlacementController.text = _defaultAndroidMrec;
      _androidInterstitialPlacementController.text = _defaultAndroidInterstitial;

      _userIdController.text = '';
      _ccpaEnabled = false;
      _coppaEnabled = false;
      _gppEnabled = false;

      // User Targeting
      _userIdEnabled = false;
      _userKeyValueEnabled = false;
      _appKeyValueEnabled = false;
    });

    _saveSettings();
  }
}
