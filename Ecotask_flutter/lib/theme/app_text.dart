import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Typography. Playfair Display for headings (h1–h3 in index.css), DM Sans for
/// body copy and JetBrains Mono for numeric values (`font-mono`).
class AppText {
  AppText._();

  static const String display = 'PlayfairDisplay';
  static const String body = 'DMSans';
  static const String mono = 'JetBrainsMono';

  static TextStyle displayStyle(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.forest900,
    double? height,
  }) =>
      TextStyle(
          fontFamily: display,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height);

  static TextStyle bodyStyle(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
          fontFamily: body,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing);

  static TextStyle monoStyle(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
  }) =>
      TextStyle(
          fontFamily: mono, fontSize: size, fontWeight: weight, color: color);

  // ---- Named styles (Tailwind sizes: xs 12/16, sm 14/20, lg 18/28, 3xl 30/36)
  static TextStyle get pageTitle => displayStyle(30, height: 1.2);
  static TextStyle get sectionTitle =>
      displayStyle(18, weight: FontWeight.w600, height: 1.55);
  static TextStyle get cardTitle => displayStyle(20,
      height: 1.4, color: AppColors.forest800, weight: FontWeight.w400);
  static TextStyle get subtitle =>
      bodyStyle(14, color: AppColors.sage500, height: 1.43);
  static TextStyle get label => bodyStyle(14,
      weight: FontWeight.w500, color: AppColors.forest800, height: 1.43);
  static TextStyle get fieldLabel => bodyStyle(12,
      weight: FontWeight.w600,
      color: AppColors.forest800,
      height: 1.33,
      letterSpacing: 0.6);
  static TextStyle get input =>
      bodyStyle(14, color: AppColors.forest900, height: 1.43);
  static TextStyle get hint =>
      bodyStyle(14, color: AppColors.sage400, height: 1.43);
  static TextStyle get small =>
      bodyStyle(12, color: AppColors.sage500, height: 1.33);
  static TextStyle get button => bodyStyle(14,
      weight: FontWeight.w600, color: AppColors.surface, height: 1.43);
}
