# SmartVolt Guardian ⚡️🏎️

**SmartVolt Guardian** is a high-performance, real-time advanced EV/Vehicle auxiliary battery telemetry dashboard built with Flutter. It utilizes asynchronous reactive state management (Riverpod) to consume high-frequency (1Hz - 20Hz) incoming voltage, current, and temperature data from a Firestore backend to predict battery failure, track parasitic drain, and evaluate Engine Off / Cranking status in real-time.

Aimed at providing an "Industry Grade" diagnosis experience, the software intelligently calculates **State of Health (SOH)**, identifies **Time-to-Brick (TTB)** scenarios caused by aftermarket infotainment systems mapping, and flags recurring telematics wakeup calls (such as overzealous AdrenoX pings).

---

## 🚀 Key Features

### 1. 🏎️ Real-Time Telemetry Dashboard
A beautiful, highly optimized reactive dashboard displaying live incoming metrics from the vehicle's 12V auxiliary system or EV low-voltage architecture:
*   **Live Voltage:** Track the dynamic battery curve directly in a liquid-smooth chart.
*   **Discharge Current:** Monitor exactly how many Amps the vehicle is pulling while parked or driving.
*   **Thermal Monitoring:** Watch battery cell temperature spikes to prevent degradation.
*   **Remaining Useful Life (RUL):** Machine learning extrapolated metric predicting how many days the 12V system will survive before replacement is needed.

### 2. ⚡️ Industry-Grade Diagnostics
*   **Pre-Charge / Cranking Sag Analysis:** Actively listens to the raw telemetry curve. Upon detecting a massive voltage dip (e.g., dropping to 9.5V while drawing -150A), it automatically flags it as a "crank" or HV Contactor engagement. The system temperature-compensates this sag to grade the health of the 12V battery on every start!
*   **Alternator / DC-DC Output Evaluation:** Distinctly recognizes when the vehicle engine/HV loop is active vs resting. It evaluates whether the alternator (or EV DC-DC converter) is successfully supplying the optimal 13.5V to 14.8V baseline.
*   **Parasitic Drain & TTB Alert:** Detects low continuous draws (e.g., -1.5A over hours) that slowly kill batteries, triggering a pop-up alert calculating exactly how many hours/minutes are left until the vehicle is "Bricked" and cannot start.

### 3. 🛡️ Risk Gauge & Anomaly Detection
An animated gauge utilizing a calculated `Risk Index`. When high-risk anomalies are recognized—such as extreme voltage sag or high temperature paired with massive current discharge—it alerts the user with a dismissable `CRITICAL ALERT` dialog box to prevent stranding scenarios.

### 4. 📝 On-Demand Diagnostic Reporting
Need to share the status with a mechanic or dealership? Users can navigate to the **Action Center -> Diagnostic Report** to generate a full breakdown of the State of Health (SOH), HV Contactor Draw, DC-DC Output, and technical boolean anomaly flags in a shareable interface.

---

## 🛠️ Architecture & Under the Hood

### 💧 Riverpod State Management
The entire application relies on `flutter_riverpod` to achieve $O(1)$ performance reactivity.
*   **No UI Jank:** Instead of wrapping massive screens in `.watch()`, the UI separates large static widget sub-trees from data-bound leaf nodes. Components like `RiskGauge` and `MetricCard` use tightly scoped `Consumer` blocks leveraging targeted `.select()` queries. This means a 20Hz data stream updates *only the numerical text blocks* and not the surrounding aesthetic containers.
*   **Autonomous Logic Blocks:** Critical features, such as the `CrankingVoltageNotifier`, track the global telemetry stream *inside* the Provider build method. This guarantees the application captures a ½-second cranking event regardless of whether the user is viewing the Dashboard or the Analytics screen at the time of ignition.

### ⚡️ $O(N)$ Arithmetic Engine
History tracking and min/max/avg statistical charting computations are done using heavily optimized $O(N)$ mathematical single-pass loops replacing standard iterable reductions ($O(N \log N)$), ensuring smooth 60fps scrolling even when parsing thousands of incoming data points every few minutes.

---

## 📁 Directory Structure

```text
smart_volt_guardian/
├── android/                   # Native Android Build Files
├── ios/                       # Native iOS Build Files
├── lib/
│   ├── models/                # Core Data Schemas (battery_state.dart)
│   ├── providers/             # Global Application State Layer (settings_provider.dart)
│   ├── screens/               # Main Page Views (dashboard_screen, action_center)
│   ├── services/              # API and Backend Abstractions (telemetry_service.dart)
│   ├── theme/                 # Global UI Color Palettes and Styling
│   ├── widgets/               # Reusable Modular UI Components 
│   └── main.dart              # Application Entry Point & ProviderScope
├── scripts/                   # Data Simulation Python Engines
│   ├── generate_dataset.py    # Generates a CSV of mathematical mock battery life
│   ├── simulate_device.py     # Local daemon that acts as an External Vehicle Device
│   └── serviceAccountKey.json # Firebase Admin Credentials (DO NOT COMMIT)
├── test/                      # Flutter Automated Tests
├── pubspec.yaml               # Dependency Declarations
└── README.md                  # This file!
```

---

## 🔧 Setup & Installation

Follow these steps to deploy SmartVolt Guardian to your machine.

### Prerequisites
*   Flutter SDK (>= 3.0)
*   Python 3 (For running the vehicle hardware mock simulator)
*   Firebase Project (Realtime Telemetry)

### 1. Firebase Setup
1. Standard Firebase Initialization: Go to the Firebase Console, create a project, and add an Android/iOS app.
2. Replace `android/app/google-services.json` or `ios/Runner/GoogleService-Info.plist` with your configurations.
3. Turn on **Firestore Database** and create a collection called `telemetry` with a document named `latest_state`.
4. Go to **Project Settings -> Service Accounts**, generate a new private key, rename it to `serviceAccountKey.json`, and place it in the `scripts/` folder.

### 2. Run the Vehicle Hardware Simulator
The Flutter app requires real data being streamed to Firestore to function in default mode.
```bash
cd scripts
python3 -m pip install firebase-admin pandas numpy
python3 simulate_device.py
```
*Leave this terminal window open. It will print the TX transmission logs acting as a physical remote OBDII scanner.*

### 3. Run the Flutter App
Open a new terminal and boot the app on your emulator or physical device.
```bash
flutter pub get
flutter run
```

---

## 📦 Building Final Releases (APKs)

### Default Debug Build (Massive Size, slow)
```bash
flutter build apk --debug
```

### Highly Compressed Production Release (Recommended)
To drastically reduce the `.apk` size from ~190MB down to ~17MB, split the builds by ABI (Application Binary Interface) architecture. This tree-shakes the code and removes debugging observers.
```bash
flutter build apk --release --split-per-abi
```
Share the `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` with your friends or colleagues!

---

*Built with passion to keep vehicle auxiliary systems alive.* ⚡️
