import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// `.eco-bg`: pale green base with soft radial highlights.
class EcoBackground extends StatelessWidget {
  const EcoBackground({super.key, required this.child});

  final Widget child;

  Widget _glow(Alignment center, Color color, double radius) => Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: center,
                radius: radius,
                colors: [color, color.withAlpha(0)],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ecoBg,
      child: Stack(
        children: [
          _glow(const Alignment(-0.6, -0.6), const Color(0x2686EFAC), 0.9),
          _glow(const Alignment(0.6, 0.6), const Color(0x1A718A55), 0.9),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Large soft blurred circle used as login/register decoration
/// (`absolute w-96 h-96 rounded-full opacity-30 blur-3xl`).
class SoftBlob extends StatelessWidget {
  const SoftBlob({super.key, required this.color, this.size = 384});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color, color.withAlpha(0)], stops: const [0.4, 1]),
        ),
      ),
    );
  }
}
