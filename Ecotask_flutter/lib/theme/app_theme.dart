import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text.dart';

/// Central Material theme + reusable decoration builders for the EcoTask
/// design language (replaces Tailwind config and index.css).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest600,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.forest600,
      onPrimary: Colors.white,
      secondary: AppColors.earth500,
      error: AppColors.red500,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppText.body,
      textTheme: ThemeData.light().textTheme.apply(
            fontFamily: AppText.body,
            bodyColor: AppColors.text,
            displayColor: AppColors.text,
          ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.forest600,
        selectionColor: AppColors.forest200,
        selectionHandleColor: AppColors.forest600,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButton),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest600,
          textStyle: AppText.bodyStyle(14, weight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.toastBg,
        contentTextStyle: AppText.bodyStyle(14, color: AppColors.toastFg),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.xxl))),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.glassFill,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.forest600,
        indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.sage700,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppText.bodyStyle(
            12,
            weight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.forest700
                : AppColors.sage700,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.forest100, space: 1, thickness: 1),
    );
  }

  /// `bg-forest-600 text-white font-semibold rounded-xl shadow-md`
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.forest600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.forest600.withAlpha(153),
        disabledForegroundColor: Colors.white,
        elevation: 3,
        shadowColor: AppColors.forest200,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        textStyle: AppText.button,
      );

  /// `border border-forest-200 text-forest-700 rounded-xl font-medium`
  static ButtonStyle get outlineButton => OutlinedButton.styleFrom(
        foregroundColor: AppColors.forest700,
        side: const BorderSide(color: AppColors.forest200),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        textStyle: AppText.bodyStyle(14, weight: FontWeight.w500),
      );

  /// Input decoration: `px-4 py-3 rounded-xl border border-forest-200
  /// bg-white/70 focus:ring-2 focus:ring-forest-400`.
  static InputDecoration inputDecoration({
    String? hint,
    Widget? prefixIcon,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.hint,
      isDense: true,
      filled: true,
      fillColor: const Color(0xB3FFFFFF),
      contentPadding: contentPadding,
      prefixIcon: prefixIcon,
      border: border(AppColors.forest200, 1),
      enabledBorder: border(AppColors.forest200, 1),
      focusedBorder: border(AppColors.forest400, 2),
      errorBorder: border(AppColors.red500, 1),
      focusedErrorBorder: border(AppColors.red500, 2),
      errorStyle: AppText.bodyStyle(12, color: AppColors.red500),
    );
  }

  /// `.glass-card` decoration.
  static BoxDecoration glassCard({double radius = AppRadius.xl, Color? fill}) =>
      BoxDecoration(
        color: fill ?? AppColors.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 20,
              offset: Offset(0, 2)),
        ],
      );
}
