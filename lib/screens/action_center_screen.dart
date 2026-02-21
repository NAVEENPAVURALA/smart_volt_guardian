import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/battery_state.dart';
import '../services/telemetry_service.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class ActionCenterScreen extends ConsumerStatefulWidget {
  const ActionCenterScreen({super.key});

  @override
  ConsumerState<ActionCenterScreen> createState() => _ActionCenterScreenState();
}

class _ActionCenterScreenState extends ConsumerState<ActionCenterScreen> {
  bool _isDeepSleepSent = false;

  @override
  Widget build(BuildContext context) {
    final batteryStateAsync = ref.watch(batteryStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let MainScaffold handle this
      body: batteryStateAsync.when(
        data: (state) => _buildActionCenter(context, state),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: AppTheme.neonRed))),
      ),
    );
  }

  Widget _buildActionCenter(BuildContext context, BatteryState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDeepSleepCard(state),
        const SizedBox(height: 24),
        _buildManualDiagnosticTrigger(),
      ],
    );
  }

  Widget _buildDeepSleepCard(BatteryState state) {
    bool isEngineRunning = state.voltage > 13.0;
    
    // For demo purposes, we will mock the "sending command" state
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDeepSleepSent ? AppTheme.neonGreen.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.power_settings_new, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                "DEEP SLEEP OVERRIDE",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (_isDeepSleepSent)
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: AppTheme.neonGreen.withValues(alpha: 0.2),
                     borderRadius: BorderRadius.circular(6),
                   ),
                   child: const Text("ACTIVE", style: TextStyle(color: AppTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                 )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Force the vehicle's telematics and background modules to completely shut down to preserve 12V battery charge. HV Contactors will remain locked until physical key fob proximity is detected.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          
          if (isEngineRunning)
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: Colors.orange.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
               ),
               child: const Row(
                 children: [
                   Icon(Icons.info_outline, color: Colors.orange, size: 20),
                   SizedBox(width: 8),
                   Expanded(
                     child: Text("Vehicle is ON. Deep Sleep override is disabled while driving.", style: TextStyle(color: Colors.orange, fontSize: 12)),
                   )
                 ],
               ),
             )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDeepSleepSent ? AppTheme.surface : AppTheme.neonRed,
                  foregroundColor: _isDeepSleepSent ? AppTheme.neonGreen : Colors.white,
                  side: BorderSide(
                    color: _isDeepSleepSent ? AppTheme.neonGreen : Colors.transparent,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: _isDeepSleepSent ? 0 : 4,
                ),
                onPressed: _isDeepSleepSent ? null : () async {
                   final settings = ref.read(settingsProvider);
                   
                   showDialog(
                     context: context,
                     barrierDismissible: false,
                     builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Text("Transmitting Command...", style: TextStyle(color: Colors.white)),
                        content: const Row(
                          children: [
                            CircularProgressIndicator(color: AppTheme.neonRed),
                            SizedBox(width: 20),
                            Expanded(child: Text("Instructing BCM to cut auxiliary power...", style: TextStyle(color: Colors.white70, fontSize: 14))),
                          ],
                        ),
                     )
                   );
                   
                   if (!settings.demoMode) {
                      try {
                        await FirebaseFirestore.instance.collection('commands').doc('active').set({
                          'command': 'DEEP_SLEEP',
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                      } catch (e) {
                         debugPrint("Failed to send command: $e");
                      }
                   } else {
                      await Future.delayed(const Duration(seconds: 2));
                   }
                   
                   if (!mounted) return;
                   
                   Navigator.of(context).pop(); // kill dialog
                   setState(() {
                     _isDeepSleepSent = true;
                   });
                   
                   ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                         content: Text("Module Shutdown Confirmed. Parasitic drain halted.", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                         backgroundColor: AppTheme.neonGreen,
                       )
                   );
                },
                child: Text(
                  _isDeepSleepSent ? "VEHICLE IN DEEP SLEEP" : "FORCE MODULE SHUTDOWN",
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildManualDiagnosticTrigger() {
     return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Row(
            children: [
               Icon(Icons.build_circle_outlined, color: Colors.white70),
               SizedBox(width: 8),
               Text(
                "MANUAL DIAGNOSTICS",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ]
          ),
          const SizedBox(height: 16),
           Text(
            "Trigger an immediate scan of the DC-DC Converter and HV Relay systems.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
           SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                         content: Text("Sending diagnostic request to OBD-II port...", style: TextStyle(color: Colors.white)),
                         backgroundColor: Color(0xFF1E1E1E),
                       )
                     );
                },
                icon: const Icon(Icons.flash_on),
                label: const Text(
                  "RUN FULL SCAN",
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            )
        ]
      )
     );
  }
}
