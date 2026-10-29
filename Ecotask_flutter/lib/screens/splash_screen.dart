import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../widgets/eco_background.dart';
import '../widgets/entrance.dart';

/// Shown while the persisted session is being restored.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EcoBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FloatingEmoji('🌱', size: 56),
              const SizedBox(height: 12),
              Text('EcoTask', style: AppText.pageTitle),
              const SizedBox(height: 4),
              Text('Carbon Tracker', style: AppText.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
