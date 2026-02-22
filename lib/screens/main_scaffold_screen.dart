import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'action_center_screen.dart';

class MainScaffoldScreen extends StatefulWidget {
  const MainScaffoldScreen({super.key});

  @override
  State<MainScaffoldScreen> createState() => _MainScaffoldScreenState();
}

class _MainScaffoldScreenState extends State<MainScaffoldScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const ActionCenterScreen(),
  ];

  final List<String> _titles = [
    "SMARTVOLT GUARDIAN",
    "EV ANALYTICS",
    "ACTION CENTER",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primaryBlue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.white.withValues(alpha: 0.5),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_remote_outlined),
              activeIcon: Icon(Icons.settings_remote),
              label: 'Action Center',
            ),
          ],
        ),
      ),
    );
  }
}
