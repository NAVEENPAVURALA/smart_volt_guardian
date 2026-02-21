import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_volt_guardian/services/telemetry_service.dart';
import 'package:smart_volt_guardian/theme/app_theme.dart';

class VoltageGraph extends ConsumerStatefulWidget {
  const VoltageGraph({super.key});

  @override
  ConsumerState<VoltageGraph> createState() => _VoltageGraphState();
}

class _VoltageGraphState extends ConsumerState<VoltageGraph> {
  final List<FlSpot> _spots = [];
  final int _maxPoints = 20;
  double _minY = 10.0;
  double _maxY = 15.0;
  double _xValue = 0;

  @override
  Widget build(BuildContext context) {
    // Listen to the stream to update the graph
    ref.listen(batteryStateProvider, (previous, next) {
      next.whenData((batteryState) {
        setState(() {
          _spots.add(FlSpot(_xValue, batteryState.voltage));
          _xValue += 1;

          // Keep only the last _maxPoints
          if (_spots.length > _maxPoints) {
            _spots.removeAt(0);
          }

          // Dynamic Y-axis adjustment
          if (batteryState.voltage < _minY) _minY = batteryState.voltage - 0.5;
          if (batteryState.voltage > _maxY) _maxY = batteryState.voltage + 0.5;
        });
      });
    });

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LIVE VOLTAGE MONITOR",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _spots.isEmpty
                ? const Center(child: Text("Waiting for data...", style: TextStyle(color: Colors.grey)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withValues(alpha: 0.05),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toStringAsFixed(1)}V',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: _spots.first.x,
                      maxX: _spots.last.x,
                      minY: _minY,
                      maxY: _maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: AppTheme.neonGreen, // Use neon green for the line
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.neonGreen.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
