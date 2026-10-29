import 'package:flutter/material.dart';

import '../models/badge.dart';
import '../services/carbon_engine.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'entrance.dart';

/// Badge collection (BadgeGrid.jsx): all eight badges, unearned ones dimmed.
/// The description tooltip (hover on web) opens on tap / long-press.
class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.earnedBadges});

  final List<EarnedBadge> earnedBadges;

  @override
  Widget build(BuildContext context) {
    final earnedIds = earnedBadges.map((b) => b.id).toSet();
    final all = CarbonEngine.badges;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badges', style: AppText.sectionTitle),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: all.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 84,
          ),
          itemBuilder: (context, i) {
            final badge = all[i];
            final earned = earnedIds.contains(badge.id);
            return Entrance(
              delay: Duration(milliseconds: i * 50),
              duration: const Duration(milliseconds: 300),
              beginScale: 0.8,
              child: Tooltip(
                message: badge.displayDescription,
                triggerMode: TooltipTriggerMode.tap,
                child: Opacity(
                  key: Key('badge-${badge.id}'),
                  opacity: earned ? 1 : 0.4,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: earned ? AppColors.forest50 : AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              earned ? AppColors.forest200 : AppColors.gray100),
                      boxShadow: earned
                          ? const [
                              BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1))
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(badge.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          badge.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStyle(9,
                              weight: FontWeight.w500,
                              color: AppColors.forest700,
                              height: 1.15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
