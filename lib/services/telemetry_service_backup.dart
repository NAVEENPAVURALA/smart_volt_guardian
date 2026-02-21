
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/battery_state.dart';
import '../providers/settings_provider.dart';
import 'dart:async';
import 'dart:math';

// Provider for the TelemetryService - defaults to throw UnimplementedError or waiting for override
final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  throw UnimplementedError("Provider must be overridden in main.dart");
});

// Stream Provider for the latest BatteryState
final batteryStateProvider = StreamProvider<BatteryState>((ref) {
  final settings = ref.watch(settingsProvider);
  
  if (settings.demoMode) {
    return MockTelemetryService().getTelemetryStream();
  }

  final service = ref.watch(telemetryServiceProvider);
  return service.getTelemetryStream();
});

abstract class TelemetryService {
  Stream<BatteryState> getTelemetryStream();
}

class FirestoreTelemetryService implements TelemetryService {
  final FirebaseFirestore _firestore;

  FirestoreTelemetryService(this._firestore);

  @override
  Stream<BatteryState> getTelemetryStream() {
    return _firestore
        .collection('telemetry')
        .doc('latest_state')
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return BatteryState.fromSnapshot(snapshot);
          } else {
            return BatteryState.initial();
          }
        });
  }
}

class MockTelemetryService implements TelemetryService {
  @override
  Stream<BatteryState> getTelemetryStream() {
    // 50ms tick = 20Hz.
    // 1000 ticks = 50 seconds total loop.
    return Stream.periodic(const Duration(milliseconds: 50), (totalTicks) {
      int cycleTick = totalTicks % 600; // 30-second loop
      double t = totalTicks * 0.05; // continuous time for noise
      Random rng = Random(totalTicks);

      // Persistent State Variables (Simulated)
      // We calculate these based on totalTicks to make it deterministic but "evolving"
      // In a real app, this would be stored in a database.
      
      // SOH (State of Health) Simulation
      // Starts at 100%, degrades based on "Virtual Time" (totalTicks).
      // Accelerated Aging: 1 hour of real life = 1 year of battery life for demo?
      // Let's make it drop visible amounts during "Stress Events".
      
      double degradation = 0.0;
      
      // Base aging (Time)
      degradation += totalTicks * 0.00001; 
      
      // Cycle Stress (Every 600 ticks is a start cycle)
      int cycles = (totalTicks / 600).floor();
      degradation += cycles * 0.05; // Each start drops 0.05% health
      
      double stateOfHealth = 100.0 - degradation;
      if (stateOfHealth < 0) stateOfHealth = 0; // Dead Battery
      
      // Calculate RUL in Days based on SOH
      // standard battery lasts ~1200 days (3-4 years)
      int rulDays = (1200 * (stateOfHealth / 100)).toInt();

      // Simulation State Machine
      double voltage = 12.6;
      double current = 0.5;
      double tempBase = 35.0;
      bool isAnomaly = false;
      int risk = 15;

      // 1. ENGINE OFF (0-5s) -> Ticks 0-100
      if (cycleTick < 100) {
        voltage = 12.6 + (sin(t) * 0.02); // Resting voltage
        current = -0.2; // Parasitic drain
        tempBase = 30.0;
      } 
      // 2. CRANKING (5-6s) -> Ticks 100-120
      else if (cycleTick < 120) {
        voltage = 9.5 + (rng.nextDouble() * 0.5); // Huge drop
        current = -150.0 + (rng.nextDouble() * 20); // Massive draw
        risk = 50; // Temporary stress
        
        // Cranking heats up the battery chemically
        tempBase = 32.0; 
      }
      // 3. ALTERNATOR CHARGING (6-20s) -> Ticks 120-400
      else if (cycleTick < 400) {
        // Recovery curve
        double progress = (cycleTick - 120) / 280.0;
        voltage = 13.8 + (0.6 * sin(t * 0.5)) + (rng.nextDouble() * 0.1); // Charging
        current = 15.0 * (1 - progress) + 2.0; // Tapering charge current
        tempBase = 30.0 + (10.0 * progress); // Engine warming up
        risk = 10;
        
        // Heat accelerates aging
        if (tempBase > 38) {
           // Hot battery degrades faster!
           // We can't easily modify the 'degradation' variable above since it's re-calc'd
           // But visuals work:
           rulDays -= 2; // Penalty for heat
        }
      }
      // 4. HEAVY LOAD/ANOMALY (20-25s) -> Ticks 400-500
      else if (cycleTick < 500) {
         voltage = 11.8 + (sin(t * 2) * 0.1); // Voltage sagging under load
         current = -25.0; // Discharge despite running? Alternator failure sim?
         isAnomaly = true;
         risk = 85 + rng.nextInt(10);
         
         // Anomaly drastically reduces confidence in RUL
         rulDays = (rulDays * 0.8).toInt(); 
      }
      // 5. RECOVERY (25-30s) -> Ticks 500-600
      else {
        voltage = 14.1;
        current = 5.0;
        risk = 20;
      }

      return BatteryState(
        voltage: voltage,
        temperature: tempBase + (sin(t * 0.1) * 0.2), // Thermal inertia
        current: current,
        soc: stateOfHealth, // SOC roughly tracks SOH in a simplified model, or we can separate
        riskIndex: risk,
        isAnomaly: isAnomaly,
        rulDays: rulDays,
      );
    }).asBroadcastStream();
  }
}
