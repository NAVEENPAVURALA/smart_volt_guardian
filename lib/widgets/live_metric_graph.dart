import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_volt_guardian/services/telemetry_service.dart';
import 'package:smart_volt_guardian/models/battery_state.dart';
import 'package:smart_volt_guardian/theme/app_theme.dart';

class LiveMetricGraph extends ConsumerStatefulWidget {
  final String title;
  final double Function(BatteryState) valueMapper;
  final Color graphColor;
  final String unit;
  final double minY;
  final double maxY;

  const LiveMetricGraph({
    super.key,
    required this.title,
    required this.valueMapper,
    required this.graphColor,
    required this.unit,
    this.minY = 0,
    this.maxY = 100,
  });

  @override
  ConsumerState<LiveMetricGraph> createState() => _LiveMetricGraphState();
}

class _LiveMetricGraphState extends ConsumerState<LiveMetricGraph> {
  final List<FlSpot> _spots = [];
  final int _maxPoints = 100; // Increased history for liquid trail
  late double _minY;
  late double _maxY;
  double _xValue = 0;

  @override
  void initState() {
    super.initState();
    _minY = widget.minY;
    _maxY = widget.maxY;
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(batteryStateProvider, (previous, next) {
      next.whenData((batteryState) {
        final newValue = widget.valueMapper(batteryState);

        setState(() {
          _spots.add(FlSpot(_xValue, newValue));
          _xValue += 1;

          if (_spots.length > _maxPoints) {
            _spots.removeAt(0);
          }

          // Dynamic Auto-Scaling
          if (newValue < _minY + 2) _minY = newValue - 5;
          if (newValue > _maxY - 2) _maxY = newValue + 5;
        });
      });
    });

    double minVal = 0;
    double maxVal = 0;
    double avgVal = 0;
    if (_spots.isNotEmpty) {
      minVal = _spots.first.y;
      maxVal = _spots.first.y;
      double sum = 0;
      for (var spot in _spots) {
        if (spot.y < minVal) minVal = spot.y;
        if (spot.y > maxVal) maxVal = spot.y;
        sum += spot.y;
      }
      avgVal = sum / _spots.length;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.graphColor.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
          )
        ],
      ),
      height: 380, // Increased height for stats
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(Icons.show_chart, color: widget.graphColor, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _spots.isEmpty
                ? const Center(child: Text("Waiting for data...", style: TextStyle(color: Colors.grey)))
                : LineChart(
                    LineChartData(
                      lineTouchData: const LineTouchData(enabled: false), // Disable touch for performance
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
                                '${value.toStringAsFixed(1)}${widget.unit}',
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
                          curveSmoothness: 0.35, // Optimized smoothness
                          preventCurveOverShooting: true,
                          color: widget.graphColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                widget.graphColor.withValues(alpha: 0.3),
                                widget.graphColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: Duration.zero,
                  ),
          ),
          const SizedBox(height: 20),
          // Statistics Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("MIN", minVal.toStringAsFixed(1), widget.graphColor.withValues(alpha: 0.7)),
                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
                _buildStatItem("AVG", avgVal.toStringAsFixed(1), Colors.white),
                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
                _buildStatItem("MAX", maxVal.toStringAsFixed(1), widget.graphColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
