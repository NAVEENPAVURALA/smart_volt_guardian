import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import time
import math
import random
import os

# Initialize Firebase Admin
cred = credentials.Certificate('serviceAccountKey.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def generate_telemetry():
    """Generates procedural battery data matches App's internal physics engine."""
    
    print("🚀 Starting SmartVolt Physics Engine (External Device)...")
    
    collection_ref = db.collection('telemetry')
    doc_ref = collection_ref.document('latest_state')

    total_ticks = 0
    
    # State tracking
    soh_degradation = 0.0

    while True:
        # Loop Logic: 30 seconds per cycle at 1Hz = 30 ticks
        cycle_tick = total_ticks % 30
        t = total_ticks * 1.0
        
        # State Machine Variables
        voltage = 12.6
        current = 0.5
        temp = 35.0
        risk = 15
        is_anomaly = False
        
        # 1. ENGINE OFF (0-5s) -> Ticks 0-5
        if cycle_tick < 5:
             # Occasionally simulate Parasitic Drain
             if total_ticks % 150 < 30: # Once every 5 cycles
                 voltage = 12.2 + (math.sin(t) * 0.02)
                 current = -1.5 # High parasitic drain!
                 temp = 28.0
                 is_anomaly = True
                 risk = 60
             else:
                 voltage = 12.6 + (math.sin(t) * 0.02)
                 current = -0.2
                 temp = 30.0
             
        # 2. TELEMATICS WAKEUP (AdrenoX App Refresh) -> Ticks 5-7
        elif cycle_tick < 7:
             voltage = 12.1 + (random.random() * 0.1)
             current = -8.5 + (random.random() * 2) # 8.5A Wakeup drain
             risk = 65
             temp = 30.0
             is_anomaly = True # Mark as anomaly for the UI to catch
             
        # 3. HV CONTACTOR CLOSE (Pre-Charge) -> Ticks 7-8
        elif cycle_tick < 8:
             voltage = 9.5 + (random.random() * 0.5)
             current = -150.0 + (random.random() * 20)
             risk = 50
             temp = 32.0
             
        # 3. ALTERNATOR CHARGING (6-20s) -> Ticks 6-20
        elif cycle_tick < 20:
             progress = (cycle_tick - 6) / 14.0
             voltage = 13.8 + (0.6 * math.sin(t * 0.5))
             current = 15.0 * (1 - progress) + 2.0
             temp = 30.0 + (10.0 * progress)
             risk = 10
             
        # 4. LOAD TEST (20-25s) -> Ticks 20-25
        elif cycle_tick < 25:
             voltage = 11.8 + (math.sin(t * 2) * 0.1)
             current = -25.0
             # Not an anomaly if expected load, just high risk
             risk = 85
             
        # 5. RECOVERY (25-30s) -> Ticks 25-30
        else:
             voltage = 14.1
             current = 5.0
             risk = 20

        # Intelligent SOC Calculation (Based on Resting Voltage 11.8V - 12.8V)
        # Only accurate when resting, but we approximate it continuously for demo
        calculated_soc = ((voltage - 11.8) / (12.8 - 11.8)) * 100.0
        # Basic Temperature Compensation: Cold drops apparent SOC
        if temp < 10.0:
            calculated_soc -= (10.0 - temp) * 0.5
            
        soc = max(0.0, min(100.0, calculated_soc))

        # RUL Logic
        soh_degradation += 0.0005 # Adjusted decay for 1Hz
        soh = max(0, 100.0 - soh_degradation)
        rul_days = int(1200 * (soh / 100.0))

        data = {
            'voltage': float(f"{voltage:.2f}"),
            'current': float(f"{current:.2f}"),
            'temperature': float(f"{temp:.1f}"),
            'soc': float(f"{soc:.1f}"),
            'riskIndex': risk,
            'isAnomaly': is_anomaly,
            'rulDays': rul_days,
            'timestamp': firestore.SERVER_TIMESTAMP
        }

        try:
            doc_ref.set(data)
            if total_ticks % 5 == 0:
                history_ref = doc_ref.collection('history')
                history_ref.add(data)
            print(f"📡 TX: {data['voltage']}V | {data['current']}A | RUL: {data['rulDays']} days")
        except Exception as e:
            print(f"❌ Upload Error: {e}")

        total_ticks += 1
        time.sleep(1.0) # 1Hz Update Rate to respect Firestore quota

def main():
    try:
        generate_telemetry()
    except KeyboardInterrupt:
        print("\n🛑 Simulation stopped.")
    except Exception as e:
        print(f"\n❌ Error: {e}")

if __name__ == "__main__":
    main()
