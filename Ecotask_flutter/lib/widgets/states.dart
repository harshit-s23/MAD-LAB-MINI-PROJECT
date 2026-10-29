import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'eco_button.dart';
import 'entrance.dart';
import 'glass_card.dart';

/// Loading state: floating emoji + caption (as in DashboardPage / TasksPage).
class LoadingView extends StatelessWidget {
  const LoadingView(
      {super.key, required this.message, this.emoji = '🌱', this.height = 256});

  final String message;
  final String emoji;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingEmoji(emoji),
            const SizedBox(height: 12),
            Text(message, style: AppText.subtitle),
          ],
        ),
      ),
    );
  }
}

/// Empty list state ("No activities yet").
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      child: GlassCard(
        padding: const EdgeInsets.all(48),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(title,
                  style: AppText.cardTitle, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: AppText.subtitle, textAlign: TextAlign.center),
              if (actionLabel != null) ...[
                const SizedBox(height: 24),
                EcoButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    expand: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state with retry.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Text('🥀', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(message,
                style: AppText.bodyStyle(14, color: AppColors.red500),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            EcoButton(label: 'Try again', onPressed: onRetry, expand: false),
          ],
        ),
      ),
    );
  }
}
