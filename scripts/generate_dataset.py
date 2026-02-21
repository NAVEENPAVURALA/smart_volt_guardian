import pandas as pd
import numpy as np
import random

def generate_ultra_realistic_data():
    data = []
    
    # --- SIMULATION CONFIG ---
    print("🚀 Generating 'The Winning Demo' Dataset...")
    
    # 1. MORNING: COLD START (The "Wake Up")
    # Battery resting overnight -> Cranking -> Alternator kicks in
    for i in range(20): # Resting
        data.append({"voltage": 12.6, "temp": 15.0, "current": 0.1, "risk": 0, "rul": 365, "anomaly": False})
        
    for i in range(5): # CRANKING (Dramatic Sag)
        data.append({"voltage": 9.5 + (i/5.0), "temp": 16.0, "current": 200.0, "risk": 0, "rul": 365, "anomaly": False})
        
    # 2. COMMUTE: HIGHWAY DRIVE (Stable High Voltage)
    # Alternator maintains ~14.2V. Slight noise.
    # REDUCED LENGTH: 60 rows (was 100) -> 2 mins at 2s/update
    for i in range(60):
        voltage = 14.2 + np.random.normal(0, 0.1) # Alternator ripple
        # Natural Risk Fluctuation (4-8) based on tiny voltage noise
        noise_risk = int(abs(np.random.normal(0, 2)))
        data.append({"voltage": voltage, "temp": 35.0 + (i/10.0), "current": 15.0, "risk": 5 + noise_risk, "rul": 365, "anomaly": False})

    # 3. TRAFFIC: STOP & GO (Regenerative Braking Spikes)
    # Voltage rises/falls with speed
    for i in range(40): # Reduced from 50
        is_braking = i % 10 < 5
        voltage = 14.8 if is_braking else 13.5
        current = -30.0 if is_braking else 20.0 
        # Risk fluctuates with traffic load
        traffic_risk = 12 + int(np.random.normal(0, 3))
        data.append({"voltage": voltage, "temp": 45.0, "current": current, "risk": traffic_risk, "rul": 364, "anomaly": False})

    # 4. PARKING: OFF (The "Drain")
    # Voltage settles back to 12.7V
    for i in range(30): # Reduced from 50
        voltage = 12.8 - (i * 0.002)
        data.append({"voltage": voltage, "temp": 40.0 - (i/5.0), "current": 0.05, "risk": 0, "rul": 364, "anomaly": False})

    # 5. THE "WOW" MOMENT: ANOMALY (Alternator Failure)
    # Driving again, but voltage doesn't rise!
    for i in range(60):
        # Voltage drops LINEARLY as battery drains (Alternator dead)
        voltage = 12.5 - (i * 0.05) 
        
        # Risk skyrockets as voltage crosses 11.5V
        risk = 10 + i # Slowly rising base risk
        if voltage < 11.5: risk = 80
        if voltage < 11.0: risk = 100
        
        # Cap risk at 100
        if risk > 100: risk = 100
        
        is_anomaly = risk > 50
        
        data.append({
            "voltage": voltage, 
            "temp": 50.0 + (i/5.0), 
            "current": 40.0, 
            "risk": risk, 
            "rul": 364 - i, 
            "anomaly": is_anomaly
        })

    # Convert to DataFrame
    df = pd.DataFrame(data)
    
    # Check if 'isAnomaly' bool needs string conversion happens in simulate_device.py, so we keep bool here
    # Renaming cols to match strict CSV headers from before if needed
    df.rename(columns={
        "risk": "risk_index",
        "rul": "rulDays",
        "temp": "temperature",
        "anomaly": "isAnomaly"
    }, inplace=True)
    
    # Add fake SOC
    df['soc'] = 100 - (df.index / len(df) * 50) 
    
    # Add timestamp offset
    df['timestamp_offset'] = df.index
    
    return df

if __name__ == "__main__":
    df = generate_ultra_realistic_data()
    # Save to the scripts folder where simulate_device.py lives
    df.to_csv('smartvolt_dataset.csv', index=False)
    print(f"✅ Created 'smartvolt_dataset.csv' with {len(df)} rows.")
