import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/telemetry_service.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

// Local provider to hold the last captured cranking voltage
final crankingVoltageProvider = NotifierProvider<CrankingVoltageNotifier, double?>(CrankingVoltageNotifier.new);

class CrankingVoltageNotifier extends Notifier<double?> {
  @override
  double? build() {
    ref.listen(batteryStateProvider, (previous, next) {
      next.whenData((state) {
        // Read the user threshold directly here? No, ref is not available for providers inside next.whenData easily unless we watch settings.
        // We will just let the UI handle the thresholds for color/text grading. The tracking remains < 10.5V.
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

    final lastCrank = ref.watch(crankingVoltageProvider);
    final sagThreshold = ref.watch(settingsProvider.select((s) => s.crankingSagThreshold));

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
                _buildStatusTag(lastCrank, sagThreshold),
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
                    lastCrank != null ? "Last Pre-Charge Sag" : "Last Pre-Charge Sag",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                   Text(
                    lastCrank == null ? "Waiting for start..." : _getStatusText(lastCrank, sagThreshold),
                    style: TextStyle(
                      color: _getStatusColor(lastCrank, sagThreshold),
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
              color: _getStatusColor(lastCrank, sagThreshold),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(double voltage, double threshold) {
    Color color = _getStatusColor(voltage, threshold);
    String text = _getStatusTextShort(voltage, threshold);
    
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

  Color _getStatusColor(double? voltage, double threshold) {
    if (voltage == null) return Colors.grey;
    if (voltage > threshold) return AppTheme.neonGreen;
    if (voltage > (threshold - 1.0)) return Colors.orange;
    return AppTheme.neonRed;
  }

  String _getStatusTextShort(double voltage, double threshold) {
    if (voltage > threshold) return "OPTIMAL";
    if (voltage > (threshold - 1.0)) return "WEAK";
    return "FAIL";
  }

  String _getStatusText(double voltage, double threshold) {
     if (voltage > threshold) return "System Healthy";
     if (voltage > (threshold - 1.0)) return "Check Battery";
     return "Replace Battery";
  }
}
