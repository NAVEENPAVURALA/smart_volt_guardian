import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/telemetry_service.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'action_center_screen.dart';

class MainScaffoldScreen extends ConsumerStatefulWidget {
  const MainScaffoldScreen({super.key});

  @override
  ConsumerState<MainScaffoldScreen> createState() => _MainScaffoldScreenState();
}

class _MainScaffoldScreenState extends ConsumerState<MainScaffoldScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
    // Listen for anomaly state to trigger animation
    ref.listen(batteryStateProvider, (previous, next) {
        final isAnomaly = next.value?.isAnomaly ?? false;
        final risk = next.value?.riskIndex ?? 0;
        final isHighRisk = isAnomaly || risk >= 80;
        
        if (isHighRisk) {
            if (!_pulseController.isAnimating) {
                _pulseController.repeat(reverse: true);
            }
        } else {
            if (_pulseController.isAnimating) {
                _pulseController.stop();
                _pulseController.reset();
            }
        }
    });

    final isAnomaly = ref.watch(batteryStateProvider.select((s) => s.value?.isAnomaly ?? false)) || 
                      ref.watch(batteryStateProvider.select((s) => (s.value?.riskIndex ?? 0) >= 80));

    return Stack(
      children: [
        Scaffold(
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
    ),
    if (isAnomaly)
      IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.neonRed.withValues(alpha: _pulseAnimation.value * 0.8),
                  width: 3.0 + (_pulseAnimation.value * 5.0),
                ),
                color: AppTheme.neonRed.withValues(alpha: _pulseAnimation.value * 0.05),
              ),
            );
          },
        ),
      ),
    ],
  );
}
}
