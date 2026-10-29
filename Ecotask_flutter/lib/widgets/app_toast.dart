import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// react-hot-toast replacement: dark rounded snackbars with a coloured icon.
class AppToast {
  AppToast._();

  /// Attached to MaterialApp so toasts work from anywhere, even across routes.
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void success(String message) => _show(message, error: false);

  static void error(String message) => _show(message, error: true);

  static void _show(String message, {required bool error}) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Row(
            children: [
              Icon(
                error ? Icons.cancel : Icons.check_circle,
                size: 20,
                color: error ? AppColors.toastError : AppColors.toastSuccess,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
