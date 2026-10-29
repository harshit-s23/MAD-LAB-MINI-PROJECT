import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// `.glass-card rounded-2xl` surface used by every card in the app.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadius.xl,
    this.opacity = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Whole-card opacity (completed tasks are rendered at 60%).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: AppTheme.glassCard(radius: radius),
      child: Padding(padding: padding, child: child),
    );
    return opacity >= 1 ? card : Opacity(opacity: opacity, child: card);
  }
}
