
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class StatusBanner extends StatelessWidget {
  final bool isAnomaly;
  final String? anomalyMessage;

  const StatusBanner({super.key, required this.isAnomaly, this.anomalyMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: isAnomaly ? AppTheme.neonRed.withValues(alpha: 0.15) : AppTheme.neonGreen.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: isAnomaly ? AppTheme.neonRed : AppTheme.neonGreen,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAnomaly ? Icons.warning_rounded : Icons.check_circle_outline,
            color: isAnomaly ? AppTheme.neonRed : AppTheme.neonGreen,
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(duration: 600.ms, begin: const Offset(1, 1), end: isAnomaly ? const Offset(1.2, 1.2) : const Offset(1, 1)), // Pulse only if anomaly
          
          const SizedBox(width: 12),
          
          Flexible(
            child: Text(
              isAnomaly 
                  ? (anomalyMessage ?? "CRITICAL ALERT: IMPENDING FAILURE") 
                  : "SYSTEM OPTIMAL",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isAnomaly ? AppTheme.neonRed : AppTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
