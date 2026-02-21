import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Use ref
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("SYSTEM CONFIGURATION"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("ALERTS & NOTIFICATIONS"),
              _buildSwitchTile(
                "Push Notifications",
                "Receive critical alerts for voltage drops",
                settings.notificationsEnabled,
                (val) => notifier.toggleNotifications(val),
              ),
              _buildSliderTile(
                "Low Voltage Threshold",
                "${settings.voltageThreshold.toStringAsFixed(1)} V",
                settings.voltageThreshold,
                10.0,
                12.0,
                (val) => notifier.setVoltageThreshold(val),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader("PREFERENCES"),
              _buildSwitchTile(
                "Use Fahrenheit (°F)",
                "Display temperature in Imperial units",
                settings.useFahrenheit,
                (val) => notifier.toggleUnits(val),
              ),
              _buildSwitchTile(
                "Dark Mode Override",
                "Force deep sleep theme (Always On)",
                true,
                (val) {}, // Locked on for this app
                isLocked: true,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader("DIAGNOSTICS"),
              _buildSwitchTile(
                "Demo / Story Mode",
                "Simulate lifecycle events for testing",
                settings.demoMode,
                (val) => notifier.toggleDemoMode(val),
              ),
              _buildInfoTile("Firmware Version", "v2.4.1-BETA"),
              _buildInfoTile("Device ID", "SVG-2024-X99"),
              _buildInfoTile("Connection", "Firestore (Secure)"),
              
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "SMARTVOLT GUARDIAN v1.0.0",
                  style: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5), fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    notifier.resetToDefaults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Settings reset to default")),
                    );
                  },
                  child: const Text("Reset to Defaults", style: TextStyle(color: AppTheme.neonRed)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textGrey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, {bool isLocked = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        value: value,
        onChanged: isLocked ? null : onChanged,
        activeThumbColor: AppTheme.primaryBlue,
        activeTrackColor: AppTheme.primaryBlue.withValues(alpha: 0.3),
        inactiveThumbColor: AppTheme.textGrey,
        inactiveTrackColor: Colors.black,
      ),
    );
  }

  Widget _buildSliderTile(String title, String valueLabel, double value, double min, double max, Function(double) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(valueLabel, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            activeColor: AppTheme.primaryBlue,
            inactiveColor: Colors.black,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textGrey)),
          Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'Courier')),
        ],
      ),
    );
  }
}
