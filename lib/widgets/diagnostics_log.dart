import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_volt_guardian/services/telemetry_service.dart';
import 'package:smart_volt_guardian/theme/app_theme.dart';

class DiagnosticsLog extends ConsumerStatefulWidget {
  const DiagnosticsLog({super.key});

  @override
  ConsumerState<DiagnosticsLog> createState() => _DiagnosticsLogState();
}

class _DiagnosticsLogState extends ConsumerState<DiagnosticsLog> {
  final List<String> _logs = [
    "System Initialized...",
    "Connecting to Telemetry Stream...",
  ];
  final ScrollController _scrollController = ScrollController();

  void _addLog(String message) {
    if (!mounted) return;

    // Prevent spamming the exact same underlying message multiple times per second
    if (_logs.isNotEmpty && _logs.last.contains(message)) {
      return;
    }

    setState(() {
      _logs.add("> ${DateTime.now().toString().substring(11, 19)} $message");
      if (_logs.length > 50) _logs.removeAt(0);
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(batteryStateProvider, (previous, next) {
      next.whenData((data) {
        if (data.isAnomaly) {
          _addLog("[CRITICAL] Anomaly Detected! Risk Index: ${data.riskIndex}");
        } else if (data.voltage < 12.0) {
          _addLog("[WARNING] Voltage Dip Detected (${data.voltage}V)");
        } else if (data.temperature > 40.0) {
          _addLog("[WARNING] High Temperature (${data.temperature}°C)");
        } else if (data.riskIndex > 50) {
          _addLog("[ALERT] Risk Index Rising...");
        } else {
           // Randomly log "Normal" messages to keep it looking alive
           if (DateTime.now().second % 5 == 0) {
             _addLog("[INFO] Telemetry Stable. Logic Board OK.");
           }
        }
      });
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
      ),
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, color: AppTheme.neonGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                "SYSTEM DIAGNOSTICS",
                style: TextStyle(
                  color: AppTheme.neonGreen,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.5),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _logs[index],
                    style: TextStyle(
                      color: _logs[index].contains("[CRITICAL]") 
                          ? AppTheme.neonRed 
                          : _logs[index].contains("[WARNING]")
                            ? Colors.amber
                            : Colors.greenAccent,
                      fontFamily: 'Courier',
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
