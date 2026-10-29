import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../widgets/eco_background.dart';
import '../widgets/entrance.dart';
import '../widgets/glass_card.dart';

/// Shared chrome of the login and register screens: eco background, soft
/// blobs, centred max-w-md column and the floating emoji header.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.blobs,
    required this.cardChildren,
    required this.below,
  });

  final String emoji;
  final String title;
  final String subtitle;

  /// Decorative [Positioned] blobs behind the card.
  final List<Widget> blobs;
  final List<Widget> cardChildren;
  final Widget below;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: EcoBackground(
        child: Stack(
          children: [
            ...blobs,
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: AppSpacing.page,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                        maxWidth: AppSpacing.authCardWidth),
                    child: Entrance(
                      duration: const Duration(milliseconds: 500),
                      offset: const Offset(0, 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GlassCard(
                            radius: AppRadius.xxl,
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.forest600,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.xl),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x4D000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 6))
                                      ],
                                    ),
                                    child: FloatingEmoji(emoji, size: 30),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(title,
                                    textAlign: TextAlign.center,
                                    style: AppText.pageTitle),
                                const SizedBox(height: 4),
                                Text(subtitle,
                                    textAlign: TextAlign.center,
                                    style: AppText.subtitle),
                                const SizedBox(height: 32),
                                ...cardChildren,
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          below,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
