import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/live_metric_graph.dart';
import '../widgets/diagnostics_log.dart';

class TemperatureMonitorScreen extends StatelessWidget {
  const TemperatureMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("THERMAL MONITOR"),
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
                title: "BATTERY TEMPERATURE (°C)",
                valueMapper: (state) => state.temperature,
                graphColor: Colors.orangeAccent,
                unit: "°C",
                minY: 20,
                maxY: 60,
              ),
            ),
            const SizedBox(height: 20),
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
