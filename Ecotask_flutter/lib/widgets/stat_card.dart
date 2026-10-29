import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'entrance.dart';
import 'glass_card.dart';

enum StatTone { forest, earth, sage }

/// Metric card (StatCard.jsx). Note: in the original CSS `.glass-card` wins
/// over the tone background, so the tone only affects the text colour.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.sub,
    this.tone = StatTone.forest,
    this.delay = Duration.zero,
  });

  final String icon;
  final String label;
  final String value;
  final String? unit;
  final String? sub;
  final StatTone tone;
  final Duration delay;

  Color get _color => switch (tone) {
        StatTone.forest => AppColors.forest800,
        StatTone.earth => AppColors.earth800,
        StatTone.sage => AppColors.sage800,
      };

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Entrance(
      delay: delay,
      offset: const Offset(0, 20),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: AppText.bodyStyle(12,
                          weight: FontWeight.w500,
                          color: c.withAlpha(178),
                          letterSpacing: 0.6,
                          height: 1.33)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(value,
                            style: AppText.displayStyle(24,
                                color: c, height: 1.33),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (unit != null) ...[
                        const SizedBox(width: 4),
                        Text(unit!,
                            style:
                                AppText.bodyStyle(14, color: c.withAlpha(153))),
                      ],
                    ],
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 4),
                    Text(sub!,
                        style: AppText.bodyStyle(12,
                            color: c.withAlpha(153), height: 1.33)),
                  ],
                ],
              ),
            ),
            Text(icon, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
