import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/hv_contactor_card.dart';

class AppSettings {
  final bool notificationsEnabled;
  final bool useFahrenheit;
  final bool demoMode;
  final double voltageThreshold;

  AppSettings({
    this.notificationsEnabled = true,
    this.useFahrenheit = false,
    this.demoMode = false,
    this.voltageThreshold = 11.5,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? useFahrenheit,
    bool? demoMode,
    double? voltageThreshold,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      useFahrenheit: useFahrenheit ?? this.useFahrenheit,
      demoMode: demoMode ?? this.demoMode,
      voltageThreshold: voltageThreshold ?? this.voltageThreshold,
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

  void resetToDefaults() {
    state = AppSettings();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});
