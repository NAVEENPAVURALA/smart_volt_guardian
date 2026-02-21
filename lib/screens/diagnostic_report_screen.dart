import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/telemetry_service.dart';
import '../providers/settings_provider.dart';
import '../models/battery_state.dart';
import '../theme/app_theme.dart';
import '../widgets/hv_contactor_card.dart';

class DiagnosticReportScreen extends ConsumerWidget {
  const DiagnosticReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryStateAsync = ref.watch(batteryStateProvider);
    final lastContactorSag = ref.watch(crankingVoltageProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("DIAGNOSTIC REPORT"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.primaryBlue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                    content: Text("PDF Report Generated & Shared"),
                    backgroundColor: AppTheme.neonGreen,
                 ),
              );
            },
          )
        ],
      ),
      body: batteryStateAsync.when(
        data: (state) => _buildReport(context, state, lastContactorSag, settings),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
        error: (_, _) => const Center(child: Text("Error generating report", style: TextStyle(color: AppTheme.neonRed))),
      ),
    );
  }

  Widget _buildReport(BuildContext context, BatteryState state, double? lastContactorSag, AppSettings settings) {
    bool isContactorOptimal = false;
    if (lastContactorSag != null) {
        // Use user-defined settings instead of hardcoded temperature approximations
        isContactorOptimal = lastContactorSag > settings.crankingSagThreshold;
    }

    // DC-DC Logic:
    // < 12.5V: Contactors Open (Off)
    // 12.5V - 13.2V: Floating / Energy Save
    // > 13.2V: Active Charging
    bool isDcDcTested = state.voltage >= 12.5; 
    bool isDcDcOptimal = state.voltage > 12.8 && state.voltage < 14.8;
    
    // Parasitic Drain (Current < -1.5A while Engine Off < 13.0V)
    bool isParasiticDrain = state.voltage < 13.0 && state.current < -1.5;

    bool isHealthOptimal = state.soc > 70 && !isParasiticDrain;
    
    // Overall Status
    bool systemPass = isContactorOptimal && (!isDcDcTested || isDcDcOptimal) && isHealthOptimal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
           Center(
            child: Column(
              children: [
                Icon(
                  systemPass ? Icons.verified : Icons.warning_rounded,
                  color: systemPass ? AppTheme.neonGreen : Colors.orange,
                  size: 64,
                ),
                const SizedBox(height: 8),
                Text(
                  systemPass ? "SYSTEM PASSED" : "ATTENTION REQUIRED",
                  style: TextStyle(
                    color: systemPass ? AppTheme.neonGreen : Colors.orange,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Generated on ${DateTime.now().toString().substring(0, 16)}",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          const Text("EXECUTIVE SUMMARY", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Divider(color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          
          _buildReportRow(
             "State of Health (SOH)", 
             "${state.soc.toStringAsFixed(1)}%", 
             isHealthOptimal ? AppTheme.neonGreen : Colors.orange,
             "Life expected: ${state.rulDays} days"
          ),
          _buildReportRow(
             "HV Contactor Draw", 
             lastContactorSag == null ? "Not Tested" : "${lastContactorSag.toStringAsFixed(2)} V", 
             lastContactorSag == null ? Colors.grey : (isContactorOptimal ? AppTheme.neonGreen : Colors.orange),
             "Threshold: > ${settings.crankingSagThreshold.toStringAsFixed(1)} V"
          ),
          _buildReportRow(
             "DC-DC Output", 
             state.voltage < 12.5 ? "Contactors Open" : "${state.voltage.toStringAsFixed(2)} V", 
             state.voltage < 12.5 ? Colors.grey : (isDcDcOptimal ? AppTheme.neonGreen : Colors.orange),
             state.voltage < 13.2 && state.voltage >= 12.5 ? "Energy Save Mode" : "Charging System Efficiency"
          ),
          _buildReportRow(
             "Vampire Drain Check", 
             isParasiticDrain ? "HIGH DRAIN FOUND" : "OPTIMAL", 
             isParasiticDrain ? AppTheme.neonRed : AppTheme.neonGreen,
             "Resting draw < 1.0A"
          ),
          
          const SizedBox(height: 32),
          const Text("TECHNICAL DETAILS", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Divider(color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 _buildDetailLine("Battery Temp", "${state.temperature.toStringAsFixed(1)} °C"),
                 _buildDetailLine("Live Voltage", "${state.voltage.toStringAsFixed(2)} V"),
                 _buildDetailLine("Live Current", "${state.current.toStringAsFixed(1)} A"),
                 _buildDetailLine("Anomaly Flag", state.isAnomaly ? "TRUE (FAIL)" : "FALSE (PASS)"),
                 _buildDetailLine("Risk Index", "${state.riskIndex}/100"),
               ],
             ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportRow(String title, String value, Color statusColor, String subtitle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
              ],
            ),
            Text(value, style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      );
  }

  Widget _buildDetailLine(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );
  }
}
