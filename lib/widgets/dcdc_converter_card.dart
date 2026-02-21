import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_volt_guardian/models/battery_state.dart';
import 'package:smart_volt_guardian/services/telemetry_service.dart';
import '../theme/app_theme.dart';

class DcDcConverterCard extends ConsumerWidget {
  const DcDcConverterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryStateAsync = ref.watch(batteryStateProvider);

    return batteryStateAsync.when(
      data: (state) => _buildCard(state),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BatteryState state) {
    // Logic: 
    // If < 13.0V: "Engine Off" or "Alternator Fail"
    // If 13.0-13.5V: "Weak Charging"
    // If 13.5-14.8V: "Optimal Charging"
    // If > 14.8V: "Overvoltage"
    
    // We only show this if the engine is presumably ON (or if voltage is high enough)
    // Actually, always show it, but status changes.
    
    // For realism, let's assume if it's > 13.0V, the alternator IS running.
    // If it's < 13.0V, we can't really test alternator unless we KNEW engine was on (RPM).
    // So we display "Voltage Output" and grade it if it looks like a charging voltage.
    
    bool isCharging = state.voltage > 13.2;
    String status = "NO OUTPUT";
    Color statusColor = AppTheme.textGrey;
    
    if (state.voltage > 14.8) {
      status = "OVERVOLTAGE";
      statusColor = AppTheme.neonRed;
    } else if (state.voltage > 13.5) {
      status = "OPTIMAL";
      statusColor = AppTheme.neonGreen;
    } else if (state.voltage > 13.2) {
      status = "WEAK";
      statusColor = Colors.orange;
    }

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                children: [
                   Icon(Icons.flash_on, color: isCharging ? AppTheme.neonGreen : Colors.white.withValues(alpha: 0.5), size: 20),
                   const SizedBox(width: 8),
                   Text(
                    "ALTERNATOR OUTPUT",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isCharging) 
                Text(
                  "${state.voltage.toStringAsFixed(2)} V",
                   style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                )
              else 
                 Text(
                  "Idle / Off",
                   style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                ),
            ],
          ),
          
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCharging ? statusColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCharging ? statusColor.withValues(alpha: 0.5) : Colors.transparent),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isCharging ? statusColor : Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          )
        ],
      ),
    );
  }
}
