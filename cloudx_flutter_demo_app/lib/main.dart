import 'package:flutter/material.dart';
import 'package:cloudx_flutter_sdk/cloudx.dart';
import 'screens/banner_screen.dart';
import 'screens/interstitial_screen.dart';
import 'screens/rewarded_screen.dart';
import 'screens/native_screen.dart';

void main() {
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
                  ? 'SDK READY'
                  : (_initError ?? 'SDK not initialized'),
              style: TextStyle(
                color: _isSDKInitialized
                    ? Colors.green
                    : (_initError != null ? Colors.red : Colors.black),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isInitializing || _isSDKInitialized
                  ? null
                  : _initializeSDK,
              child: _isInitializing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Initialize SDK'),
            ),
            if (_isSDKInitialized)
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const MainTabView(),
                      ),
                    );
                  },
                  child: const Text('Continue to Demo'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeSDK() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });
    const appKey = 'qT9U-tJ0FRb0x4gXb-pF0';
    try {
      final success = await CloudX.initialize(appKey: appKey);
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
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _selectedIndex = 0;

  static const List<Widget> _tabTitles = [
    Text('Banner'),
    Text('Interstitial'),
    Text('Rewarded'),
    Text('Native'),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      BannerScreen(isSDKInitialized: true),
      InterstitialScreen(isSDKInitialized: true),
      RewardedScreen(isSDKInitialized: true),
      NativeScreen(isSDKInitialized: true),
    ];
    return Scaffold(
      appBar: AppBar(
        title: _tabTitles[_selectedIndex],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.view_day), label: 'Banner'),
          BottomNavigationBarItem(icon: Icon(Icons.crop_3_2), label: 'Interstitial'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Rewarded'),
          BottomNavigationBarItem(icon: Icon(Icons.view_module), label: 'Native'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
} 