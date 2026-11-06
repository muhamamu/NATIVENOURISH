import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedRadialRings extends StatelessWidget {
  final double calorieRatio;
  final double proteinRatio;
  final double carbsRatio;
  final double fatRatio;
  final double eatenCalories;
  final double targetCalories;
  final double remainingCalories;
  final double size;

  const AnimatedRadialRings({
    super.key,
    required this.calorieRatio,
    required this.proteinRatio,
    required this.carbsRatio,
    required this.fatRatio,
    required this.eatenCalories,
    required this.targetCalories,
    required this.remainingCalories,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _RadialRingsPainter(
                  calorieProgress: (calorieRatio * animValue).clamp(0.0, 1.0),
                  proteinProgress: (proteinRatio * animValue).clamp(0.0, 1.0),
                  carbsProgress: (carbsRatio * animValue).clamp(0.0, 1.0),
                  fatProgress: (fatRatio * animValue).clamp(0.0, 1.0),
                  isDark: isDark,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(remainingCalories * animValue).round()}',
                    style: TextStyle(
                      fontSize: size * 0.16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'kcal remaining',
                    style: TextStyle(
                      fontSize: size * 0.065,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(eatenCalories * animValue).round()} / ${targetCalories.round()}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadialRingsPainter extends CustomPainter {
  final double calorieProgress;
  final double proteinProgress;
  final double carbsProgress;
  final double fatProgress;
  final bool isDark;

  _RadialRingsPainter({
    required this.calorieProgress,
    required this.proteinProgress,
    required this.carbsProgress,
    required this.fatProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.045;
    final ringSpacing = strokeWidth + 4;

    // Ring 1 (Outer): Calories
    final r1 = (size.width / 2) - strokeWidth;
    _drawRing(
      canvas,
      center,
      r1,
      strokeWidth,
      calorieProgress,
      isDark ? const Color(0xFF331E12) : const Color(0xFFFFE8D6),
      AppColors.primaryAccent,
      AppColors.primaryAccentLight,
    );

    // Ring 2 (Middle): Protein
    final r2 = r1 - ringSpacing;
    _drawRing(
      canvas,
      center,
      r2,
      strokeWidth,
      proteinProgress,
      isDark ? const Color(0xFF132A22) : const Color(0xFFD1FAE5),
      AppColors.accentGreen,
      AppColors.accentGreenLight,
    );

    // Ring 3 (Inner): Carbs
    final r3 = r2 - ringSpacing;
    _drawRing(
      canvas,
      center,
      r3,
      strokeWidth,
      carbsProgress,
      isDark ? const Color(0xFF152A3A) : const Color(0xFFE0F2FE),
      AppColors.accentBlue,
      const Color(0xFF7DD3FC),
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    double progress,
    Color trackColor,
    Color startColor,
    Color endColor,
  ) {
    if (radius <= 0) return;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      final rect = Rect.fromCircle(center: center, radius: radius);

      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [startColor, endColor],
          tileMode: TileMode.clamp,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialRingsPainter oldDelegate) {
    return oldDelegate.calorieProgress != calorieProgress ||
        oldDelegate.proteinProgress != proteinProgress ||
        oldDelegate.carbsProgress != carbsProgress ||
        oldDelegate.fatProgress != fatProgress ||
        oldDelegate.isDark != isDark;
  }
}
