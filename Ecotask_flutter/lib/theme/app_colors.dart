import 'package:flutter/painting.dart';

/// Colour tokens from `tailwind.config.js` (forest / earth / sage palettes),
/// `index.css` CSS variables and the Tailwind defaults the app relies on.
class AppColors {
  AppColors._();

  // forest
  static const Color forest50 = Color(0xFFF0FDF4);
  static const Color forest100 = Color(0xFFDCFCE7);
  static const Color forest200 = Color(0xFFBBF7D0);
  static const Color forest300 = Color(0xFF86EFAC);
  static const Color forest400 = Color(0xFF4ADE80);
  static const Color forest500 = Color(0xFF22C55E);
  static const Color forest600 = Color(0xFF16A34A);
  static const Color forest700 = Color(0xFF15803D);
  static const Color forest800 = Color(0xFF166534);
  static const Color forest900 = Color(0xFF14532D);
  static const Color forest950 = Color(0xFF052E16);

  // earth
  static const Color earth50 = Color(0xFFFDF8F0);
  static const Color earth100 = Color(0xFFFAEFD9);
  static const Color earth200 = Color(0xFFF4DCA9);
  static const Color earth300 = Color(0xFFECC470);
  static const Color earth400 = Color(0xFFE2A340);
  static const Color earth500 = Color(0xFFD97706);
  static const Color earth600 = Color(0xFFB45309);
  static const Color earth700 = Color(0xFF92400E);
  static const Color earth800 = Color(0xFF78350F);
  static const Color earth900 = Color(0xFF451A03);

  // sage
  static const Color sage50 = Color(0xFFF6F7F3);
  static const Color sage100 = Color(0xFFEAEDE2);
  static const Color sage200 = Color(0xFFD4DBC6);
  static const Color sage300 = Color(0xFFB3C29E);
  static const Color sage400 = Color(0xFF90A574);
  static const Color sage500 = Color(0xFF718A55);
  static const Color sage600 = Color(0xFF576C42);
  static const Color sage700 = Color(0xFF455636);
  static const Color sage800 = Color(0xFF39452E);
  static const Color sage900 = Color(0xFF303B28);

  // index.css :root variables
  static const Color background = Color(0xFFF6F7F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1C2617);
  static const Color muted = Color(0xFF6B7280);
  static const Color ecoBg = Color(0xFFF0FDF4);

  // Tailwind defaults used by the original markup
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red500 = Color(0xFFEF4444);
  static const Color orange500 = Color(0xFFF97316);

  // .glass-card: rgba(255,255,255,.85) fill, rgba(212,219,198,.6) border
  static const Color glassFill = Color(0xD9FFFFFF);
  static const Color glassBorder = Color(0x99D4DBC6);

  // --shadow-card: 0 2px 20px rgba(21,128,61,.08)
  static const Color shadowCard = Color(0x1415803D);

  // Toast colours (react-hot-toast config in App.jsx)
  static const Color toastBg = Color(0xFF1C2617);
  static const Color toastFg = Color(0xFFF0FDF4);
  static const Color toastSuccess = Color(0xFF4ADE80);
  static const Color toastError = Color(0xFFF87171);

  // EcoScoreRing colour ramp
  static const Color scoreHigh = Color(0xFF16A34A);
  static const Color scoreGood = Color(0xFF22C55E);
  static const Color scoreMid = Color(0xFF84CC16);
  static const Color scoreLow = Color(0xFFEAB308);
  static const Color scoreBad = Color(0xFFEF4444);

  /// Colour of the score ring for [score] (EcoScoreRing.jsx thresholds).
  static Color forScore(double score) {
    if (score >= 80) return scoreHigh;
    if (score >= 60) return scoreGood;
    if (score >= 40) return scoreMid;
    if (score >= 20) return scoreLow;
    return scoreBad;
  }
}
