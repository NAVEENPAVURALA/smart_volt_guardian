import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/live_metric_graph.dart';
import '../widgets/diagnostics_log.dart';

class VoltageMonitorScreen extends StatelessWidget {
  const VoltageMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VOLTAGE MONITOR"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: LiveMetricGraph(
                title: "LIVE VOLTAGE MONITOR (V)",
                valueMapper: (state) => state.voltage,
                graphColor: AppTheme.neonGreen,
                unit: "V",
                minY: 10,
                maxY: 16,
              ),
            ),
            const SizedBox(height: 20),
            
            // Diagnostics Log
            const Expanded(
              flex: 1,
              child: DiagnosticsLog(),
            ),
          ],
        ),
      ),
    );
  }
}
