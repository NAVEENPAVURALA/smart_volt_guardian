
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

// Stream Provider for Historical Timeseries Data
final historyProvider = StreamProvider<List<BatteryState>>((ref) {
  final settings = ref.watch(settingsProvider);
  
  if (settings.demoMode) {
    return MockTelemetryService().getHistoryStream();
  }

  final service = ref.watch(telemetryServiceProvider);
  return service.getHistoryStream();
});

abstract class TelemetryService {
  Stream<BatteryState> getTelemetryStream();
  Stream<List<BatteryState>> getHistoryStream();
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

  @override
  Stream<List<BatteryState>> getHistoryStream() {
    return _firestore
        .collection('telemetry')
        .doc('latest_state')
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(50) // e.g., last 50 data points (250s of history at 5s intervals)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => BatteryState.fromSnapshot(doc)).toList();
        });
  }
}

class MockTelemetryService implements TelemetryService {
  @override
  Stream<BatteryState> getTelemetryStream() {
    // 1000ms tick = 1Hz (matches real device simulator rate).
    // 30 ticks = 30-second loop.
    return Stream.periodic(const Duration(milliseconds: 1000), (totalTicks) {
      int cycleTick = totalTicks % 30; // 30-second loop
      double t = totalTicks * 0.05; // continuous time for noise
      Random rng = Random(totalTicks);

      // Persistent State Variables (Simulated)
      // We calculate these based on totalTicks to make it deterministic but "evolving"
      // In a real app, this would be stored in a database.
      
      // SOH (State of Health) Simulation
      double baseDecay = 0.0005;
      double stressModifier = 1.0;
      
      // Simulation State Machine
      double voltage = 12.6;
      double current = 0.5;
      
      // Drifting Ambient Weather
      double weatherTrend = (totalTicks ~/ 600) % 2 == 0 ? 1.0 : -1.0;
      double ambientTemp = 25.0 + ((totalTicks % 600) * 0.05 * weatherTrend);
      ambientTemp = ambientTemp.clamp(-10.0, 45.0);
      
      double tempBase = ambientTemp;
      bool isAnomaly = false;
      int risk = 15;

      // 1. ENGINE OFF (0-5s) -> Ticks 0-5
      if (cycleTick < 5) {
        // Occasional Parasitic Drain (Once every 5 loops)
        if (totalTicks % 150 < 30) {
           voltage = 12.2 + (sin(t) * 0.02);
           current = -1.5; // Drain!
           tempBase = 28.0;
           isAnomaly = true;
           risk = 60;
        } else {
           voltage = 12.6 + (sin(t) * 0.02); // Resting
           current = -0.2; // Normal drain
           tempBase = 30.0;
        }
      } 
      // 2. TELEMATICS WAKEUP (AdrenoX App Refresh) -> Ticks 5-7
      else if (cycleTick < 7) {
        voltage = 12.1 + (rng.nextDouble() * 0.1);
        current = -8.5 + (rng.nextDouble() * 2); // 8.5A Wakeup drain
        risk = 65;
        tempBase = 30.0;
        isAnomaly = true;
      }
      // 3. HV CONTACTOR CLOSE (Pre-Charge) -> Ticks 7-8
      else if (cycleTick < 8) {
        voltage = 9.5 + (rng.nextDouble() * 0.5); // Huge drop
        current = -150.0 + (rng.nextDouble() * 20); // Massive draw
        risk = 50; // Temporary stress
        
        // Cranking heats up the battery chemically
        tempBase = 32.0; 
      }
      // 4. DC-DC CHARGING -> Ticks 8-20
      else if (cycleTick < 20) {
        // Recovery curve
        double progress = (cycleTick - 8) / 12.0;
        voltage = 13.8 + (0.6 * sin(t * 0.5)) + (rng.nextDouble() * 0.1); // Charging
        current = 15.0 * (1 - progress) + 2.0; // Tapering charge current
        tempBase = 30.0 + (10.0 * progress); // Engine warming up
        risk = 10;
      }
      // 5. HEAVY LOAD/ANOMALY -> Ticks 20-25
      else if (cycleTick < 25) {
         voltage = 11.8 + (sin(t * 2) * 0.1); // Sag
         current = -25.0; // Discharge
         risk = 85 + rng.nextInt(10);
      }
      // 6. RECOVERY -> Ticks 25-30
      else {
        voltage = 14.1;
        current = 5.0;
        risk = 20;
      }
      
      double finalTemp = tempBase + (sin(t * 0.1) * 0.2);

      // Nonlinear SOC Calculation (Peukert Approximation)
      double vDiff = (voltage - 11.8).clamp(0.0, 1.0);
      double calculatedSoc = (pow(vDiff, 0.6) / pow(1.0, 0.6)) * 100.0;
      
      // Basic Temperature Compensation
      if (finalTemp < 15.0) {
          calculatedSoc -= (15.0 - finalTemp) * 1.5;
      }
      
      double soc = calculatedSoc.clamp(0.0, 100.0);
      
      // Dynamic RUL Degradation
      if (finalTemp < 0 || finalTemp > 40) stressModifier += 2.0;
      if (current < -50) stressModifier += 3.0;
      
      // deterministic degradation for demo purposes
      double totalDegradation = totalTicks * baseDecay * stressModifier;
      double stateOfHealth = max(0.0, 100.0 - pow(totalDegradation, 1.1));
      int rulDays = (1200 * (stateOfHealth / 100.0)).toInt();

      return BatteryState(
        voltage: voltage,
        temperature: finalTemp, // Thermal inertia
        current: current,
        soc: soc, // Use the dynamically calculated SOC
        riskIndex: risk,
        isAnomaly: isAnomaly,
        rulDays: rulDays,
      );
    }).asBroadcastStream();
  }

  @override
  Stream<List<BatteryState>> getHistoryStream() {
    // Generate an elegant procedural fake history for Demo Mode
    List<BatteryState> fakeHistory = [];
    for (int i = 0; i < 50; i++) {
        double t = i * 0.2;
        double voltage = 12.8 + (sin(t) * 1.2); // Sweeps between 11.6 and 14.0
        fakeHistory.add(
            BatteryState(
                voltage: voltage,
                temperature: 25.0,
                current: 0.0,
                soc: 100.0,
                riskIndex: 10,
                isAnomaly: false,
                rulDays: 1200,
            )
        );
    }
    // AnalyticsScreen expects newest first (descending timestamp order)
    return Stream.value(fakeHistory.reversed.toList());
  }
}
