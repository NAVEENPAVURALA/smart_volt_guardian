import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/live_metric_graph.dart';
import '../widgets/diagnostics_log.dart';

class RulMonitorScreen extends StatelessWidget {
  const RulMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("REMAINING USEFUL LIFE"),
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
                title: "PREDICTED LIFESPAN (DAYS)",
                valueMapper: (state) => state.rulDays.toDouble(),
                graphColor: AppTheme.neonGreen,
                unit: "d",
                minY: 0,
                maxY: 500,
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
