import 'package:flutter/material.dart';
import 'screens/settings_screen.dart';
import 'screens/init_screen.dart';
import 'screens/banner_screen.dart';
import 'screens/mrec_screen.dart';
import 'screens/interstitial_screen.dart';

void main() async {
  // Enable Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const CloudXDemoApp());
}

class CloudXDemoApp extends StatelessWidget {
  const CloudXDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudX Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = [
    const SettingsScreen(),
    const InitScreen(),
    const BannerScreen(),
    const MRECScreen(),
    const InterstitialScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.power_settings_new),
            label: 'Init',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_day),
            label: 'Banner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.crop_square),
            label: 'MREC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.crop_3_2),
            label: 'Interstitial',
          ),
        ],
      ),
    );
  }
}

// Placeholder screen for tabs we haven't built yet
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Screen\n(Coming soon)',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
