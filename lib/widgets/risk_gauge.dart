
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../theme/app_theme.dart';

class RiskGauge extends StatefulWidget {
  final int riskIndex;
  final int criticalThreshold;

  const RiskGauge({super.key, required this.riskIndex, this.criticalThreshold = 75});

  @override
  State<RiskGauge> createState() => _RiskGaugeState();
}

class _RiskGaugeState extends State<RiskGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 10.0, end: 30.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RiskGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isCritical = widget.riskIndex >= widget.criticalThreshold;
    final wasCritical = oldWidget.riskIndex >= oldWidget.criticalThreshold;
    
    if (isCritical && !wasCritical) {
      _controller.repeat(reverse: true);
    } else if (!isCritical && wasCritical) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  Color _getRiskColor(int value) {
    if (value <= 30) return AppTheme.neonGreen;
    if (value <= 70) return Colors.amber;
    return AppTheme.neonRed;
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(widget.riskIndex);
    final isCritical = widget.riskIndex >= widget.criticalThreshold;

    // Fast-path initialization if gauge spawns in critical state
    if (isCritical && !_controller.isAnimating) {
        _controller.repeat(reverse: true);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 250,
          width: 250,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: 100,
                startAngle: 150,
                endAngle: 30,
                showLabels: false,
                showTicks: false,
                axisLineStyle: AxisLineStyle(
                  thickness: 0.2,
                  cornerStyle: CornerStyle.bothCurve,
                  color: AppTheme.surface,
                  thicknessUnit: GaugeSizeUnit.factor,
                ),
                pointers: <GaugePointer>[
                  RangePointer(
                    value: widget.riskIndex.toDouble(),
                    cornerStyle: CornerStyle.bothCurve,
                    width: 0.2,
                    sizeUnit: GaugeSizeUnit.factor,
                    enableAnimation: true,
                    animationDuration: 1500,
                    animationType: AnimationType.ease,
                    gradient: const SweepGradient(
                      colors: <Color>[AppTheme.neonGreen, Colors.amber, AppTheme.neonRed],
                      stops: <double>[0.0, 0.5, 1.0],
                    ),
                  ),
                  MarkerPointer(
                    value: widget.riskIndex.toDouble(),
                    enableAnimation: true,
                    animationDuration: 1500,
                    animationType: AnimationType.ease,
                    markerType: MarkerType.circle,
                    color: Colors.white,
                    markerHeight: 20,
                    markerWidth: 20,
                    borderWidth: 4,
                    borderColor: riskColor,
                  )
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    positionFactor: 0.1,
                    angle: 90,
                    widget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.riskIndex.toString(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                            shadows: [
                              Shadow(
                                color: riskColor.withValues(alpha: isCritical ? 0.8 : 0.5), 
                                blurRadius: isCritical ? _animation.value * 1.5 : 20
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'RISK INDEX',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textGrey,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
