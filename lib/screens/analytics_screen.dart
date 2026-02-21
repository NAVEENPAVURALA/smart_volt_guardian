import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/battery_state.dart';
import '../services/telemetry_service.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryStateAsync = ref.watch(batteryStateProvider);
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let parent handle background
      body: batteryStateAsync.when(
        data: (state) => _buildAnalyticsDashboard(context, state, historyAsync),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppTheme.neonRed))),
      ),
    );
  }

  Widget _buildAnalyticsDashboard(BuildContext context, BatteryState state, AsyncValue<List<BatteryState>> historyAsync) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh simulation or trigger data fetch if needed
      },
      color: AppTheme.primaryBlue,
      backgroundColor: AppTheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFotaReadinessCard(state),
          const SizedBox(height: 24),
          _buildVampireDrainCard(state),
          const SizedBox(height: 24),
          _buildHistoricalTrendsCard(historyAsync),
        ],
      ),
    );
  }

  Widget _buildFotaReadinessCard(BatteryState state) {
    // FOTA Readiness logic:
    // Requires minimum SOC of 60% and battery health (RUL/Risk) to be good.
    // Assuming an update takes 45 mins drawing 10A = ~7.5Ah needed.
    
    // Simplistic grading based on realistic factors
    bool isEngineRunning = state.voltage > 13.0;
    
    // If the engine (or DC-DC) is actively charging, it's generally safe because the HV battery is doing the work.
    // If parked, we must rely solely on the 12V reserve.
    
    String readinessStatus;
    Color statusColor;
    String recommendation;
    double readinessScore; // 0.0 to 1.0

    if (isEngineRunning) {
      readinessStatus = "READY (CHARGING)";
      statusColor = AppTheme.neonGreen;
      recommendation = "Vehicle is ON. Software update will draw from HV pack. Safe to proceed.";
      readinessScore = 1.0;
    } else {
      if (state.soc > 70 && state.voltage > 12.4) {
        readinessStatus = "READY (PARKED)";
        statusColor = AppTheme.primaryBlue;
        recommendation = "12V reserve is strong enough to sustain 45-min FOTA update module load.";
        readinessScore = state.soc / 100.0;
      } else if (state.soc > 40) {
        readinessStatus = "MARGINAL";
        statusColor = Colors.orange;
        recommendation = "12V capacity is low. Please start the vehicle (READY mode) before initiating update to prevent bricking.";
        readinessScore = 0.5;
      } else {
        readinessStatus = "NOT RECOMMENDED";
        statusColor = AppTheme.neonRed;
        recommendation = "CRITICAL RISK: Initiating FOTA will likely drain the 12V battery and brick the vehicle mid-update.";
        readinessScore = 0.1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.system_update_alt, color: Colors.white70),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "FOTA READINESS ANALYZER",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
               Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  readinessStatus,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${state.soc.toInt()}%",
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  "SOC",
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Est. 45m Update Load:", style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  Text(
                    isEngineRunning ? "Direct from HV Pack" : "-7.5 Ah Required",
                    style: TextStyle(
                      color: isEngineRunning ? AppTheme.neonGreen : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
           ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: readinessScore,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: statusColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  readinessScore > 0.6 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVampireDrainCard(BatteryState state) {
    // Vampire Drain Logic:
    // If Engine is OFF (< 13.0V):
    // - < 0.2A: Normal System Sleep Output
    // - 0.5A - 2.5A: Constant Accessory Drain (Likely a Dashcam in parking mode or ODB tool)
    // - > 5.0A: Heavy Module Wakeup (AdrenoX)
    
    bool isParked = state.voltage < 13.0; // Simplistic approximation
    
    // Default (Driving)
    String drainStatus = "MONITORING PAUSED";
    Color statusColor = AppTheme.textGrey;
    String drainText = "Vehicle is currently active. Vampire drain is only analyzed while parked.";
    IconData drainIcon = Icons.motion_photos_paused;

    if (isParked) {
      double drainA = state.current.abs();
      
       if (drainA > 5.0) {
         drainStatus = "ACTIVE MODULE WAKE-UP";
         statusColor = AppTheme.neonRed;
         drainText = "Massive current draw detected (${state.current.toStringAsFixed(1)}A). Target: Telematics (AdrenoX) or faulty BCM module constantly waking up.";
         drainIcon = Icons.wifi_tethering_error_rounded;
       } else if (drainA > 0.4 && drainA < 3.0 && state.current < 0) {
          // A steady 1A - 2.5A draw is classic aftermarket Dashcam behavior
         drainStatus = "CONSTANT ACCESSORY DRAIN";
         statusColor = Colors.orange;
         drainText = "Steady parasitic draw detected (${state.current.toStringAsFixed(1)}A). Target: Aftermarket Dashcam in Parking Mode or OBD-II Dongle.";
         drainIcon = Icons.videocam_outlined;
       } else if (drainA <= 0.4) {
         drainStatus = "SYSTEM IN DEEP SLEEP";
         statusColor = AppTheme.neonGreen;
         drainText = "Vehicle is sleeping peacefully. Minimal standby current draw (${state.current.toStringAsFixed(1)}A).";
         drainIcon = Icons.bedtime_outlined;
       } else {
           // Catch-all 
           drainStatus = "ANALYZING PATTERNS...";
           statusColor = AppTheme.primaryBlue;
           drainText = "Observing current draw (${state.current.toStringAsFixed(1)}A). Waiting for steady state.";
           drainIcon = Icons.manage_search;
       }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              const Icon(Icons.radar, color: Colors.white70),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "VAMPIRE DRAIN TRACKER",
                   style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isParked)
                  Text(
                    "${state.current.toStringAsFixed(1)} A",
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                  )
            ],
          ),
          const SizedBox(height: 20),
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: statusColor.withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: statusColor.withValues(alpha: 0.3)),
             ),
             child: Row(
               children: [
                 Icon(drainIcon, color: statusColor, size: 32),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(drainStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                       const SizedBox(height: 4),
                       Text(drainText, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.4)),
                     ],
                   )
                 )
               ],
             )
          ),
          if (isParked && state.current.abs() > 0.4) ...[
            const SizedBox(height: 24),
            const Text("ENERGY AUDIT BREAKDOWN", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: _generatePieSections(state.current.abs()),
                      )
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _generatePieLegend(state.current.abs()),
                    )
                  )
                ]
              )
            )
          ]
        ],
      )
    );
  }

  List<PieChartSectionData> _generatePieSections(double drainA) {
    if (drainA > 5.0) {
      // AdrenoX heavy drain
      return [
        PieChartSectionData(color: AppTheme.neonRed, value: 75, title: '75%', radius: 30, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(color: Colors.orange, value: 15, title: '15%', radius: 25, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(color: AppTheme.neonGreen, value: 10, title: '10%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      ];
    } else {
      // Dashcam / accessory drain
      return [
        PieChartSectionData(color: Colors.orange, value: 65, title: '65%', radius: 30, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(color: AppTheme.primaryBlue, value: 25, title: '25%', radius: 25, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        PieChartSectionData(color: AppTheme.neonGreen, value: 10, title: '10%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      ];
    }
  }

  List<Widget> _generatePieLegend(double drainA) {
    if (drainA > 5.0) {
      return [
        _buildLegendItem(AppTheme.neonRed, "Telematics / AdrenoX"),
        const SizedBox(height: 8),
        _buildLegendItem(Colors.orange, "BCM Module Wakeups"),
        const SizedBox(height: 8),
        _buildLegendItem(AppTheme.neonGreen, "Base Deep Sleep"),
      ];
    } else {
      return [
        _buildLegendItem(Colors.orange, "Accessory / Dashcam"),
        const SizedBox(height: 8),
        _buildLegendItem(AppTheme.primaryBlue, "Security Sensors"),
        const SizedBox(height: 8),
        _buildLegendItem(AppTheme.neonGreen, "Base Deep Sleep"),
      ];
    }
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildHistoricalTrendsCard(AsyncValue<List<BatteryState>> historyAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Colors.white70),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "VOLTAGE HISTORY (LAST 4 MINS)",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Center(child: Text("Waiting for historical data...", style: TextStyle(color: AppTheme.textGrey)));
                }
                
                // We want oldest first for L-to-R graph, but firestore returned descending (newest first).
                final reversed = history.reversed.toList();
                
                List<FlSpot> spots = [];
                double maxVolt = 15.0;
                for (int i = 0; i < reversed.length; i++) {
                  spots.add(FlSpot(i.toDouble(), reversed[i].voltage));
                  if (reversed[i].voltage > maxVolt - 0.5) {
                      maxVolt = reversed[i].voltage + 1.0;
                  }
                }

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide X axis labels for now
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text("${value.toStringAsFixed(1)}V", style: const TextStyle(color: AppTheme.textGrey, fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 8.0,
                    maxY: maxVolt,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppTheme.primaryBlue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
              error: (err, stack) => Center(child: Text('Error (Are you in Demo Mode?):\n$err', style: const TextStyle(color: AppTheme.neonRed))),
            )
          )
        ],
      )
    );
  }
}
