import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/live_metric_graph.dart';
import '../widgets/diagnostics_log.dart';

class CurrentMonitorScreen extends StatelessWidget {
  const CurrentMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CURRENT LOAD"),
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
                title: "SYSTEM CURRENT (AMPS)",
                valueMapper: (state) => state.current,
                graphColor: Colors.purpleAccent,
                unit: "A",
                minY: -50,
                maxY: 50,
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
