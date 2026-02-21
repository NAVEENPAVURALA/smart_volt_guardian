import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return AppSettings();
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void toggleUnits(bool value) {
    state = state.copyWith(useFahrenheit: value);
  }

  void toggleDemoMode(bool value) {
    state = state.copyWith(demoMode: value);
    // Hard Reset Cranking Analysis when switching modes to avoid stale data
    ref.invalidate(crankingVoltageProvider);
  }

  void setVoltageThreshold(double value) {
    state = state.copyWith(voltageThreshold: value);
  }

  void setCriticalRiskThreshold(int value) {
    state = state.copyWith(criticalRiskThreshold: value);
  }

  void setCrankingSagThreshold(double value) {
    state = state.copyWith(crankingSagThreshold: value);
  }

  void resetToDefaults() {
    state = AppSettings();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
