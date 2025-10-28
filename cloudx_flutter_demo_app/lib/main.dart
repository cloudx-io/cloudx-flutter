import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'screens/banner_screen.dart';
import 'screens/mrec_screen.dart';
import 'screens/interstitial_screen.dart';
import 'screens/rewarded_screen.dart';
import 'screens/native_screen.dart';
import 'screens/logs_modal_screen.dart';
import 'config/demo_config.dart';

void main() async {
  // Enable verbose logging for demo app
  WidgetsFlutterBinding.ensureInitialized();
  await CloudX.setLoggingEnabled(true);
  
  runApp(const CloudXDemoApp());
}

class CloudXDemoApp extends StatelessWidget {
  const CloudXDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudX Flutter Demo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const InitScreen(),
    );
  }
}

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  bool _isSDKInitialized = false;
  bool _isInitializing = false;
  String? _initError;
  DemoEnvironmentConfig? _currentEnvironment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initialize SDK')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _isSDKInitialized
                    ? Colors.green
                    : (_initError != null ? Colors.red : Colors.grey),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSDKInitialized
                  ? 'SDK Initialized (${_currentEnvironment?.name ?? ""})'
                  : (_initError ?? 'SDK Not Initialized'),
              style: TextStyle(
                color: _isSDKInitialized
                    ? Colors.green
                    : (_initError != null ? Colors.red : Colors.black),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Environment buttons (matches Obj-C demo app order)
            _buildEnvironmentButton(
              'Init Staging',
              Platform.isIOS ? DemoConfig.iosStaging : DemoConfig.androidStaging,
              const Color.fromRGBO(102, 179, 230, 1.0), // Light blue
            ),
            const SizedBox(height: 16),
            _buildEnvironmentButton(
              'Init Dev',
              Platform.isIOS ? DemoConfig.iosDev : DemoConfig.androidDev,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildEnvironmentButton(
              'Init Production',
              Platform.isIOS ? DemoConfig.iosProduction : DemoConfig.androidProduction,
              const Color.fromRGBO(51, 179, 77, 1.0), // Green
            ),
            if (_isSDKInitialized) ...[
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => MainTabView(environment: _currentEnvironment!),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 44),
                ),
                child: const Text('Continue to Demo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentButton(String label, DemoEnvironmentConfig config, Color color) {
    return SizedBox(
      width: 200,
      height: 44,
      child: ElevatedButton(
        onPressed: _isInitializing || _isSDKInitialized ? null : () => _initializeSDK(config),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isInitializing && _currentEnvironment == config
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _initializeSDK(DemoEnvironmentConfig config) async {
    setState(() {
      _isInitializing = true;
      _initError = null;
      _currentEnvironment = config;
    });

    try {
      // Set environment (iOS only, Android uses CloudXInitializationServer)
      await CloudX.setEnvironment(config.name.toLowerCase());
      
      final success = await CloudX.initialize(
        appKey: config.appKey
      );
      
      setState(() {
        _isSDKInitialized = success;
        _isInitializing = false;
        if (!success) {
          _initError = 'Failed to initialize CloudX SDK.';
        }
      });
    } catch (e) {
      setState(() {
        _isSDKInitialized = false;
        _isInitializing = false;
        _initError = 'Error: $e';
      });
    }
  }
}

class MainTabView extends StatefulWidget {
  final DemoEnvironmentConfig environment;
  
  const MainTabView({super.key, required this.environment});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _selectedIndex = 0;

  static const List<Widget> _tabTitles = [
    Text('Banner'),
    Text('MREC'),
    Text('Interstitial'),
    Text('Rewarded'),
    Text('Native'),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      BannerScreen(isSDKInitialized: true, environment: widget.environment),
      MRECScreen(isSDKInitialized: true, environment: widget.environment),
      InterstitialScreen(isSDKInitialized: true, environment: widget.environment),
      RewardedScreen(isSDKInitialized: true, environment: widget.environment),
      NativeScreen(isSDKInitialized: true, environment: widget.environment),
    ];
    return Scaffold(
      appBar: AppBar(
        title: _tabTitles[_selectedIndex],
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LogsModalScreen(title: 'Logs'),
                  fullscreenDialog: true,
                ),
              );
            },
            icon: const Icon(Icons.article_outlined),
            tooltip: 'Show Logs',
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.view_day), label: 'Banner'),
          BottomNavigationBarItem(icon: Icon(Icons.crop_square), label: 'MREC'),
          BottomNavigationBarItem(icon: Icon(Icons.crop_3_2), label: 'Interstitial'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewarded'),
          BottomNavigationBarItem(icon: Icon(Icons.view_module), label: 'Native'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
} 