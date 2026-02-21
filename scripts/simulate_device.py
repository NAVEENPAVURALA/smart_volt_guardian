import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import time
import math
import random
import os
import threading

# Initialize Firebase Admin
cred = credentials.Certificate('serviceAccountKey.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def generate_telemetry():
    """Generates procedural battery data matches App's internal physics engine."""
    
    print("🚀 Starting SmartVolt Physics Engine (External Device)...")
    
    # ---------------------------------------------------------
    # Bidirectional Command Listener
    # ---------------------------------------------------------
    is_deep_sleep = False
    
    def on_command_snapshot(doc_snapshot, changes, read_time):
        nonlocal is_deep_sleep
        for doc in doc_snapshot:
            if doc.exists:
                cmd = doc.to_dict().get('command')
                if cmd == 'DEEP_SLEEP' and not is_deep_sleep:
                    is_deep_sleep = True
                    print("\n⚠️ [REMOTE CONTROL] FORCE DEEP SLEEP ACTIVE. Killing all auxiliary power.")

    cmd_watch = db.collection('commands').document('active').on_snapshot(on_command_snapshot)
    # ---------------------------------------------------------

    collection_ref = db.collection('telemetry')
    doc_ref = collection_ref.document('latest_state')

    total_ticks = 0
    
    # State tracking
    soh_degradation = 0.0
    ambient_temp = 25.0 # Start comfortable
    weather_trend = 1.0 # 1=warming, -1=cooling

    while True:
        # Loop Logic: 30 seconds per cycle at 1Hz = 30 ticks
        cycle_tick = total_ticks % 30
        t = total_ticks * 1.0
        
        # Slow drifting ambient temperature (real-world weather simulation)
        if total_ticks % 600 == 0: # Change trend occasionally
            weather_trend = random.choice([1.0, -1.0])
        ambient_temp += (random.random() * 0.1 * weather_trend)
        ambient_temp = max(-10.0, min(45.0, ambient_temp)) # Clamp between -10C and 45C
        
        # State Machine Variables
        voltage = 12.6
        current = 0.5
        temp = ambient_temp
        risk = 15
        is_anomaly = False
        
        # 1. ENGINE OFF (0-5s) -> Ticks 0-5
        if cycle_tick < 5:
             # Occasionally simulate Parasitic Drain
             if total_ticks % 150 < 30: # Once every 5 cycles
                 voltage = 12.2 + (math.sin(t) * 0.02)
                 current = -1.5 # High parasitic drain!
                 temp = ambient_temp + 2.0
                 is_anomaly = True
                 risk = 60
             else:
                 voltage = 12.6 + (math.sin(t) * 0.02)
                 current = -0.2
                 temp = ambient_temp
             
        # 2. TELEMATICS WAKEUP (AdrenoX App Refresh) -> Ticks 5-7
        elif cycle_tick < 7:
             voltage = 12.1 + (random.random() * 0.1)
             current = -8.5 + (random.random() * 2) # 8.5A Wakeup drain
             risk = 65
             temp = ambient_temp + 2.0
             is_anomaly = True # Mark as anomaly for the UI to catch
             
        # 3. HV CONTACTOR CLOSE (Pre-Charge) -> Ticks 7-8
        elif cycle_tick < 8:
             voltage = 9.5 + (random.random() * 0.5)
             current = -150.0 + (random.random() * 20)
             risk = 50
             temp = ambient_temp + 5.0
             
        # 3. ALTERNATOR CHARGING (6-20s) -> Ticks 6-20
        elif cycle_tick < 20:
             progress = (cycle_tick - 6) / 14.0
             voltage = 13.8 + (0.6 * math.sin(t * 0.5))
             current = 15.0 * (1 - progress) + 2.0
             temp = ambient_temp + 10.0 + (10.0 * progress)
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

        # --- "Elon Mode" Remote Override Control ---
        if is_deep_sleep and current < 0:
             current = -0.1  # Force minimal standby current
             is_anomaly = False # Clean state since we initiated it
             risk = max(5, risk - 40) # Drop risk significantly
        # -------------------------------------------

        # Non-Linear SOC Calculation (Approximating Lead-Acid discharge curve)
        # Instead of straight linear 11.8->12.8, we use an exponential curve representing surface charge dropout
        v_diff = max(0, min(1.0, voltage - 11.8)) 
        calculated_soc = (math.pow(v_diff, 0.6) / math.pow(1.0, 0.6)) * 100.0

        # Dynamic Temperature Compensation: Cold severely hampers chemical reaction
        if temp < 15.0:
            calculated_soc -= (15.0 - temp) * 1.5 # Steeper drop in extreme cold
            
        soc = max(0.0, min(100.0, calculated_soc))

        # Accelerated RUL Degradation Logic
        # Degrades faster when cold, hot, or under heavy load
        base_decay = 0.0005
        stress_modifier = 1.0
        if temp < 0 or temp > 40:
             stress_modifier += 2.0
        if current < -50:
             stress_modifier += 3.0
        
        soh_degradation += (base_decay * stress_modifier)
        soh = max(0, 100.0 - (math.pow(soh_degradation, 1.1))) # Exponential decay over time
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
