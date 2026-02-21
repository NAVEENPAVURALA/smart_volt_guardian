import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/main_scaffold_screen.dart';
import 'services/telemetry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using Manual Configuration
  await Firebase.initializeApp();

  // Run app with Real Firestore Service
  runApp(
    ProviderScope(
      overrides: [
        telemetryServiceProvider.overrideWithValue(FirestoreTelemetryService(FirebaseFirestore.instance)),
      ],
      child: const SmartVoltApp(),
    ),
  );
}

class SmartVoltApp extends StatelessWidget {
  const SmartVoltApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartVolt Guardian',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.deepDarkTheme,
      home: const MainScaffoldScreen(),
    );
  }
}
