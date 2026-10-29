import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/eco_level.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Animated score ring (EcoScoreRing.jsx: 120x120 viewBox, r=54, stroke 10).
class EcoScoreRing extends StatelessWidget {
  const EcoScoreRing(
      {super.key, required this.score, required this.level, this.size = 160});

  final double score;
  final EcoLevel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = size / 120;
    final fraction = (score / 100).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (context, value, _) => CustomPaint(
              painter: _RingPainter(
                  progress: value,
                  color: AppColors.forScore(score),
                  scale: scale),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.round()}',
                      key: const Key('eco-score-value'),
                      style: AppText.displayStyle(22 * scale,
                          color: AppColors.forest900, height: 1.1),
                    ),
                    Text('ECO SCORE',
                        style: AppText.bodyStyle(9 * scale,
                            color: AppColors.muted, height: 1.4)),
                    Text(level.emoji,
                        style: TextStyle(fontSize: 14 * scale, height: 1.4)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(level.name,
            style: AppText.bodyStyle(14,
                weight: FontWeight.w600, color: AppColors.forest800)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(
      {required this.progress, required this.color, required this.scale});

  final double progress;
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: 54 * scale);
    final stroke = 10 * scale;

    canvas.drawCircle(
      center,
      54 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.forest100,
    );
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.scale != scale;
}
