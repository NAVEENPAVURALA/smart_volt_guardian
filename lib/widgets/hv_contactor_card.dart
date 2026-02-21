import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';

// Local provider to hold the last captured cranking voltage
final crankingVoltageProvider = NotifierProvider<CrankingVoltageNotifier, double?>(CrankingVoltageNotifier.new);

class CrankingVoltageNotifier extends Notifier<double?> {
  @override
  double? build() {
    ref.listen(batteryStateProvider, (previous, next) {
      next.whenData((state) {
        // 1. CRANKING DETECTED (< 10.5V)
        if (state.voltage < 10.5 && state.voltage > 5.0) {
           updateCrank(state.voltage);
        } else {
           // 2. RESTING DETECTED (System Reset)
           resetIfResting(state.voltage);
        }
      });
    });
    return null;
  }

  void updateCrank(double voltage) {
    // Capture if it's the first value or lower than current tracked minimum
    if (state == null || voltage < state!) {
      state = voltage;
    }
  }

  void resetIfResting(double voltage) {
      // If we see steady resting voltage (Engine OFF), reset to 'Waiting' state
      // This allows the next crank (which will be a dip) to be captured fresh.
      // Range: 12.5V to 13.0V (Strict Idle/Resting). 
      // Avoids resetting during "Load Test" (11.8V) or "Deep Discharge".
      if (voltage > 12.5 && voltage < 12.9) {
          state = null; 
      }
  }
}

class HvContactorCard extends ConsumerWidget {
  const HvContactorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final batteryStateAsync = ref.watch(batteryStateProvider);
    final lastCrank = ref.watch(crankingVoltageProvider);
    
    // We need the current temperature to grade the cranking performance
    double currentTemp = 25.0; // Default fallback
    batteryStateAsync.whenData((state) {
      currentTemp = state.temperature;
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          colors: [AppTheme.surface, AppTheme.surface.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Icon(Icons.car_repair, color: Colors.white.withValues(alpha: 0.7), size: 20),
                   const SizedBox(width: 8),
                   Text(
                    "HV CONTACTOR HEALTH",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (lastCrank != null)
                _buildStatusTag(lastCrank, currentTemp),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lastCrank?.toStringAsFixed(2) ?? "--",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  "V",
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Text(
                    // Show the temperature used for the calculation to the user
                    lastCrank != null ? "Last Pre-Charge Sag (@ ${currentTemp.toStringAsFixed(0)}°C)" : "Last Pre-Charge Sag",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                   Text(
                    lastCrank == null ? "Waiting for start..." : _getStatusText(lastCrank, currentTemp),
                    style: TextStyle(
                      color: _getStatusColor(lastCrank, currentTemp),
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar - dynamically scaled based on temp threshold
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: lastCrank == null ? 0 : (lastCrank / 12.0).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: _getStatusColor(lastCrank, currentTemp),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(double voltage, double temp) {
    Color color = _getStatusColor(voltage, temp);
    String text = _getStatusTextShort(voltage, temp);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Industry Standard: Cold batteries drop voltage much lower during crank.
  // We dynamically adjust the "pass" threshold based on temp.
  double _getDynamicOptimalThreshold(double temp) {
    if (temp < 0) return 8.5; // Freezing, massive sag expected
    if (temp < 15) return 9.0; // Cold
    return 9.6; // Normal/Warm
  }

  double _getDynamicWeakThreshold(double temp) {
    if (temp < 0) return 7.0; 
    if (temp < 15) return 7.5;
    return 8.0; 
  }

  Color _getStatusColor(double? voltage, double temp) {
    if (voltage == null) return Colors.grey;
    if (voltage > _getDynamicOptimalThreshold(temp)) return AppTheme.neonGreen;
    if (voltage > _getDynamicWeakThreshold(temp)) return Colors.orange;
    return AppTheme.neonRed;
  }

  String _getStatusTextShort(double voltage, double temp) {
    if (voltage > _getDynamicOptimalThreshold(temp)) return "OPTIMAL";
    if (voltage > _getDynamicWeakThreshold(temp)) return "WEAK";
    return "FAIL";
  }

  String _getStatusText(double voltage, double temp) {
     if (voltage > _getDynamicOptimalThreshold(temp)) return "System Healthy";
     if (voltage > _getDynamicWeakThreshold(temp)) return "Check Battery";
     return "Replace Battery";
  }
}
