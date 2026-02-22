import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/hv_contactor_card.dart';

class AppSettings {
  final bool notificationsEnabled;
  final bool useFahrenheit;
  final bool demoMode;
  final double voltageThreshold;
  final int criticalRiskThreshold;
  final double crankingSagThreshold;

  AppSettings({
    this.notificationsEnabled = true,
    this.useFahrenheit = false,
    this.demoMode = false,
    this.voltageThreshold = 11.5,
    this.criticalRiskThreshold = 80,
    this.crankingSagThreshold = 10.5,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? useFahrenheit,
    bool? demoMode,
    double? voltageThreshold,
    int? criticalRiskThreshold,
    double? crankingSagThreshold,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      useFahrenheit: useFahrenheit ?? this.useFahrenheit,
      demoMode: demoMode ?? this.demoMode,
      voltageThreshold: voltageThreshold ?? this.voltageThreshold,
      criticalRiskThreshold: criticalRiskThreshold ?? this.criticalRiskThreshold,
      crankingSagThreshold: crankingSagThreshold ?? this.crankingSagThreshold,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadFromDisk();
    return AppSettings();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      useFahrenheit: prefs.getBool('useFahrenheit') ?? false,
      demoMode: prefs.getBool('demoMode') ?? false,
      voltageThreshold: prefs.getDouble('voltageThreshold') ?? 11.5,
      criticalRiskThreshold: prefs.getInt('criticalRiskThreshold') ?? 80,
      crankingSagThreshold: prefs.getDouble('crankingSagThreshold') ?? 10.5,
    );
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', state.notificationsEnabled);
    await prefs.setBool('useFahrenheit', state.useFahrenheit);
    await prefs.setBool('demoMode', state.demoMode);
    await prefs.setDouble('voltageThreshold', state.voltageThreshold);
    await prefs.setInt('criticalRiskThreshold', state.criticalRiskThreshold);
    await prefs.setDouble('crankingSagThreshold', state.crankingSagThreshold);
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
    _saveToDisk();
  }

  void toggleUnits(bool value) {
    state = state.copyWith(useFahrenheit: value);
    _saveToDisk();
  }

  void toggleDemoMode(bool value) {
    state = state.copyWith(demoMode: value);
    _saveToDisk();
    // Hard Reset Cranking Analysis when switching modes to avoid stale data
    ref.invalidate(crankingVoltageProvider);
  }

  void setVoltageThreshold(double value) {
    state = state.copyWith(voltageThreshold: value);
    _saveToDisk();
  }

  void setCriticalRiskThreshold(int value) {
    state = state.copyWith(criticalRiskThreshold: value);
    _saveToDisk();
  }

  void setCrankingSagThreshold(double value) {
    state = state.copyWith(crankingSagThreshold: value);
    _saveToDisk();
  }

  void resetToDefaults() {
    state = AppSettings();
    _saveToDisk();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

// Global provider for Deep Sleep sent state (persists across tab switches)
class DeepSleepNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void activate() => state = true;
  void reset() => state = false;
}

final deepSleepSentProvider = NotifierProvider<DeepSleepNotifier, bool>(DeepSleepNotifier.new);
