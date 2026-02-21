import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/telemetry_service.dart';
import '../models/battery_state.dart';
import '../theme/app_theme.dart';
import '../widgets/status_banner.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/metric_card.dart';
import '../widgets/diagnostics_log.dart';
import '../widgets/hv_contactor_card.dart';
import '../widgets/dcdc_converter_card.dart';
import '../screens/voltage_monitor_screen.dart';
import '../screens/temperature_monitor_screen.dart';
import '../screens/current_monitor_screen.dart';
import '../screens/rul_monitor_screen.dart';
import '../screens/diagnostic_report_screen.dart';
import '../providers/settings_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Flag to prevent multiple dialogs from stacking
  bool _isDialogVisible = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider); // Listen to settings

    // Listen for anomaly state changes to trigger alerts
    ref.listen<AsyncValue<BatteryState>>(batteryStateProvider, (previous, next) {
      next.whenData((currentState) {
        final previousState = previous?.value;

        // Custom Threshold logic or Platform Anomaly
        bool isCustomLowVoltage = currentState.voltage <= settings.voltageThreshold;
        
        // AdrenoX Telematics Wakeup signature: ~8.5A drain while voltage is still healthy (>12.0)
        bool isAdrenoxWakeup = currentState.voltage > 12.0 && currentState.current < -6.0 && currentState.current > -12.0;
        
        // General parasitic drain (slower drain, lower voltage)
        bool isParasiticDrain = !isAdrenoxWakeup && currentState.voltage < 13.0 && currentState.current < -1.0;
        
        bool shouldAlert = (currentState.isAnomaly || isCustomLowVoltage || isParasiticDrain || isAdrenoxWakeup) && settings.notificationsEnabled;

        // Trigger alert if anomaly detected (and wasn't previously, or initial load)
        // AND ensuring we don't stack dialogs
        if (shouldAlert && 
           (previousState == null || (!previousState.isAnomaly && previousState.voltage > settings.voltageThreshold)) && 
           !_isDialogVisible) {
          _showAnomalyDialog(context, isParasiticDrain: isParasiticDrain, isAdrenoxWakeup: isAdrenoxWakeup, state: currentState);
        }
      });
    });

    final hasError = ref.watch(batteryStateProvider.select((s) => s.hasError));
    final isLoading = ref.watch(batteryStateProvider.select((s) => s.isLoading));

    if (hasError) {
      final err = ref.watch(batteryStateProvider.select((s) => s.error));
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.neonRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Telemetry Stream Error',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.refresh(batteryStateProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.black,
              ),
              child: const Text("RETRY CONNECTION"),
            )
          ],
        ),
      );
    }

    if (isLoading && !ref.watch(batteryStateProvider.select((s) => s.hasValue))) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    return Column(
      children: [
        // 1. Dynamic Status Banner
        Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(batteryStateProvider.select((s) => s.value));
            if (state == null) return const SizedBox.shrink();
            bool isAdrenoxWakeup = state.voltage > 12.0 && state.current < -6.0 && state.current > -12.0;
            bool isParasiticDrain = !isAdrenoxWakeup && state.voltage < 13.0 && state.current < -1.0;
            
            String? bannerMessage;
            bool isCriticalRisk = state.riskIndex >= settings.criticalRiskThreshold;
            if (isAdrenoxWakeup) {
              bannerMessage = "WARNING: EXCESSIVE ADRENOX APP POLLING";
            } else if (isParasiticDrain) {
              bannerMessage = "WARNING: HIGH PARASITIC DRAIN DETECTED";
            } else if (state.isAnomaly || state.voltage <= settings.voltageThreshold || isCriticalRisk) {
              bannerMessage = "CRITICAL ALERT: IMPENDING FAILURE";
            }

            return StatusBanner(
              isAnomaly: state.isAnomaly || state.voltage <= settings.voltageThreshold || isCriticalRisk || isParasiticDrain || isAdrenoxWakeup,
              anomalyMessage: bannerMessage,
            );
          }
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 2. Hero Widget - Risk Gauge
                  Consumer(
                    builder: (context, ref, child) {
                      final riskIndex = ref.watch(batteryStateProvider.select((s) => s.value?.riskIndex ?? 0));
                      final criticalThreshold = ref.watch(settingsProvider.select((s) => s.criticalRiskThreshold));
                      return RiskGauge(riskIndex: riskIndex, criticalThreshold: criticalThreshold);
                    }
                  ),
                  const SizedBox(height: 20),
                  
                  // NEW: Industry-Grade Feature
                  const HvContactorCard(),
                  const SizedBox(height: 16),
                  const DcDcConverterCard(),
                  const SizedBox(height: 30),

                  // 3. Data Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final voltage = ref.watch(batteryStateProvider.select((s) => s.value?.voltage ?? 0.0));
                          return MetricCard(
                            title: "Voltage",
                            value: "${voltage.toStringAsFixed(1)} V",
                            unit: "Tap for Graph",
                            icon: Icons.bolt,
                            iconColor: AppTheme.primaryBlue,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const VoltageMonitorScreen()));
                            },
                          );
                        }
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final temperature = ref.watch(batteryStateProvider.select((s) => s.value?.temperature ?? 0.0));
                          String tempValue;
                          String tempUnit;
                          if (settings.useFahrenheit) {
                            double tempF = (temperature * 9 / 5) + 32;
                            tempValue = "${tempF.toStringAsFixed(1)}°F";
                            tempUnit = "Max: 113°F";
                          } else {
                            tempValue = "${temperature.toStringAsFixed(1)}°C";
                            tempUnit = "Max: 45°C";
                          }
                          return MetricCard(
                            title: "Temperature",
                            value: tempValue,
                            unit: tempUnit,
                            icon: Icons.thermostat,
                            iconColor: Colors.orangeAccent,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const TemperatureMonitorScreen()));
                            },
                          );
                        }
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final current = ref.watch(batteryStateProvider.select((s) => s.value?.current ?? 0.0));
                          return MetricCard(
                            title: "Current",
                            value: "${current.toStringAsFixed(1)} A",
                            unit: "Discharge",
                            icon: Icons.electrical_services,
                            iconColor: Colors.purpleAccent,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const CurrentMonitorScreen()));
                            },
                          );
                        }
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final rulDays = ref.watch(batteryStateProvider.select((s) => s.value?.rulDays ?? 0));
                          return MetricCard(
                            title: "RUL",
                            value: "$rulDays",
                            unit: "Days Remaining",
                            icon: Icons.timer,
                            iconColor: AppTheme.neonGreen,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const RulMonitorScreen()));
                            },
                          );
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // NEW: Diagnostic Report Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DiagnosticReportScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text("VIEW FULL DIAGNOSTIC REPORT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. [RESTORED] Diagnostics Log
                  const DiagnosticsLog(),

                  // 5. Footer
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "With Love,",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 28, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppTheme.primaryBlue, AppTheme.neonGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              "From Naveen & Co.",
                              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAnomalyDialog(BuildContext context, {bool isParasiticDrain = false, bool isAdrenoxWakeup = false, BatteryState? state}) {
    // Set flag to true immediately to block other dialogs
    setState(() {
      _isDialogVisible = true;
    });

    String titleText = "CRITICAL ALERT";
    String bodyText = "Anomaly detected in auxiliary battery system! Immediate inspection recommended to prevent failure.";
    
    if (isAdrenoxWakeup) {
      titleText = "ADRENOX WAKE-UP DRAIN";
      bodyText = "Vehicle computers are waking up too frequently! This is often caused by excessive polling from the AdrenoX mobile app. The continuous ~8A draw will deplete the 12V battery while parked.";
    } else if (isParasiticDrain && state != null) {
        titleText = "TIME-TO-BRICK ALERT";
        // TTB Calculation (Simplified linear extrapolation for 12V 40Ah battery)
        // Usable capacity between 12.6V (100%) and 11.0V (0% / Bricked for HV contactors) ~ 30Ah
        // Assuming current is negative (discharge)
        double dischargeRate = state.current.abs();
        if (dischargeRate > 0) {
           double hoursLeft = 30.0 / dischargeRate; // Ah / A = h
           
           if (hoursLeft < 1.0) {
              int mins = (hoursLeft * 60).toInt();
              bodyText = "High parasitic drain detected! Voltage dropping rapidly. Vehicle will BRICK in approximately $mins minutes. HV Contactors will fail to close.";
           } else {
              bodyText = "High parasitic drain detected! Vehicle will BRICK in approximately ${hoursLeft.toStringAsFixed(1)} hours. Inspect aftermarket electronics or faulty modules.";
           }
        }
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Force user acknowledgement
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.neonRed, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.neonRed, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(titleText, style: const TextStyle(color: AppTheme.neonRed)),
            ),
          ],
        ),
        content: Text(
          bodyText,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("ACKNOWLEDGE", style: TextStyle(color: AppTheme.primaryBlue)),
          ),
        ],
      ),
    ).then((_) {
      // Reset flag when dialog is closed
      if (mounted) {
        setState(() {
          _isDialogVisible = false;
        });
      }
    });
  }
}
