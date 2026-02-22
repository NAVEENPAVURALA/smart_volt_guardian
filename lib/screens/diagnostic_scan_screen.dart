import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import 'diagnostic_report_screen.dart';

class DiagnosticScanScreen extends StatefulWidget {
  const DiagnosticScanScreen({super.key});

  @override
  State<DiagnosticScanScreen> createState() => _DiagnosticScanScreenState();
}

class _DiagnosticScanScreenState extends State<DiagnosticScanScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _pulseController;
  final List<String> _logs = [];

  final List<_ScanStep> _steps = [
    _ScanStep("Initializing OBD-II Interface...", 800),
    _ScanStep("Connecting to Body Control Module (BCM)...", 1200),
    _ScanStep("Interrogating Telematics Gateway...", 900),
    _ScanStep("Analyzing Parasitic Current Draw...", 1500),
    _ScanStep("Testing HV Contactor Relays...", 1100),
    _ScanStep("Checking DC-DC Converter Output...", 1000),
    _ScanStep("Verifying Battery Thermal Management...", 800),
    _ScanStep("Compiling Diagnostic Matrix...", 1200),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);
    _runScanSequence();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runScanSequence() async {
    for (int i = 0; i < _steps.length; i++) {
        if (!mounted) return;
        setState(() {
          _currentStep = i;
          _logs.add("[OBD-II] ${_steps[i].message}");
        });
        await Future.delayed(Duration(milliseconds: _steps[i].durationMs));
        if (!mounted) return;
        setState(() {
           _logs.last = "${_logs.last} [OK]";
        });
    }

    if (!mounted) return;
    
    // Scan Complete
    setState(() {
      _logs.add("\n>> DIAGNOSTIC SCAN COMPLETE <<");
    });
    
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Transition seamlessly to the report
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const DiagnosticReportScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = _currentStep / (_steps.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("SYSTEM SCAN", style: TextStyle(letterSpacing: 2)),
        automaticallyImplyLeading: false, // Prevent backing out during scan
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(
               child: Stack(
                 alignment: Alignment.center,
                 children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        backgroundColor: AppTheme.surface,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    AnimatedBuilder(
                       animation: _pulseController,
                       builder: (context, child) {
                           return Icon(
                             Icons.satellite_alt_outlined, 
                             size: 60, 
                             color: AppTheme.primaryBlue.withValues(alpha: 0.5 + (_pulseController.value * 0.5))
                           );
                       }
                    )
                 ]
               ),
             ),
             const SizedBox(height: 40),
             Text(
               progress >= 1.0 ? "ANALYZING RESULTS..." : "INTERROGATING MODULES...",
               style: const TextStyle(
                 color: AppTheme.primaryBlue,
                 fontSize: 14,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 2
               ),
             ),
             const SizedBox(height: 16),
             Expanded(
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppTheme.surface,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                 ),
                 child: ListView.builder(
                   itemCount: _logs.length,
                   itemBuilder: (context, index) {
                      bool isLast = index == _logs.length - 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _logs[index],
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: isLast ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      );
                   },
                 ),
               ),
             )
          ],
        ),
      ),
    );
  }
}

class _ScanStep {
  final String message;
  final int durationMs;
  _ScanStep(this.message, this.durationMs);
}
