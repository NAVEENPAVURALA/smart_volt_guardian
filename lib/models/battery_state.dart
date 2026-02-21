
import 'package:cloud_firestore/cloud_firestore.dart';

class BatteryState {
  final double voltage;
  final double temperature;
  final double current;
  final double soc;
  final int riskIndex;
  final bool isAnomaly;
  final int rulDays;

  BatteryState({
    required this.voltage,
    required this.temperature,
    required this.current,
    required this.soc,
    required this.riskIndex,
    required this.isAnomaly,
    required this.rulDays,
  });

  factory BatteryState.fromMap(Map<String, dynamic> map) {
    return BatteryState(
      voltage: (map['voltage'] ?? 0.0).toDouble(),
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      current: (map['current'] ?? 0.0).toDouble(),
      soc: (map['soc'] ?? 0.0).toDouble(),
      riskIndex: (map['riskIndex'] ?? map['risk_index'] ?? 0).toInt(),
      isAnomaly: map['isAnomaly'] ?? false,
      rulDays: (map['rulDays'] ?? 0).toInt(),
    );
  }

  factory BatteryState.fromSnapshot(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return BatteryState.fromMap(map);
  }

  // Placeholder for initial/empty state if needed
  factory BatteryState.initial() {
    return BatteryState(
      voltage: 0.0,
      temperature: 0.0,
      current: 0.0,
      soc: 0.0,
      riskIndex: 0,
      isAnomaly: false,
      rulDays: 0,
    );
  }
}
