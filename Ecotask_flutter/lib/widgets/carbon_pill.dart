import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Green (saving) / amber (emission) value chip, e.g. "+3.78 kg".
class CarbonPill extends StatelessWidget {
  const CarbonPill({super.key, required this.value, this.large = false});

  final double value;

  /// Large = task card chip (14px bold + 10px unit); small = dashboard row chip.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final negative = value < 0;
    final fg = negative ? AppColors.forest700 : AppColors.earth700;
    final bg = negative ? AppColors.forest100 : AppColors.earth100;
    final sign = negative ? '−' : '+';
    final number = value.abs().toStringAsFixed(2);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 10 : 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: large
          ? Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: '$sign$number',
                      style: AppText.monoStyle(14,
                          weight: FontWeight.w700, color: fg)),
                  TextSpan(
                      text: ' kg', style: AppText.monoStyle(10, color: fg)),
                ],
              ),
            )
          : Text('$sign$number kg',
              style: AppText.monoStyle(12, weight: FontWeight.w500, color: fg)),
    );
  }
}
