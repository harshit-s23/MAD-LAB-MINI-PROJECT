import 'package:flutter/material.dart';

import '../models/suggestion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'entrance.dart';

/// "Smart Suggestions 💡" (SuggestionsPanel.jsx). Renders nothing when empty.
class SuggestionsPanel extends StatelessWidget {
  const SuggestionsPanel({super.key, required this.suggestions});

  final List<Suggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Smart Suggestions 💡', style: AppText.sectionTitle),
        const SizedBox(height: 12),
        for (var i = 0; i < suggestions.length; i++)
          Padding(
            padding:
                EdgeInsets.only(bottom: i == suggestions.length - 1 ? 0 : 12),
            child: Entrance(
              delay: Duration(milliseconds: i * 100),
              offset: const Offset(-20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.forest50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.forest100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestions[i].icon,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(suggestions[i].tip,
                              style: AppText.bodyStyle(14,
                                  weight: FontWeight.w500,
                                  color: AppColors.forest800,
                                  height: 1.35)),
                          const SizedBox(height: 4),
                          Text(suggestions[i].impact,
                              style: AppText.monoStyle(12,
                                  color: AppColors.forest600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
