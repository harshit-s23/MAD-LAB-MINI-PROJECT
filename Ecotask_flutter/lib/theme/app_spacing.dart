import 'package:flutter/painting.dart';

/// Spacing (Tailwind 4px scale) and radii used across the app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Page padding (`p-4`).
  static const EdgeInsets page = EdgeInsets.all(16);

  /// Max content width on tablets / landscape (`max-w-6xl`).
  static const double maxContentWidth = 1152;

  /// Auth card width (`max-w-md`).
  static const double authCardWidth = 448;
}

class AppRadius {
  AppRadius._();

  static const double md = 8; // rounded-lg
  static const double lg = 12; // rounded-xl
  static const double xl = 16; // rounded-2xl
  static const double xxl = 24; // rounded-3xl

  static BorderRadius get card => BorderRadius.circular(xl);
  static BorderRadius get control => BorderRadius.circular(lg);
  static BorderRadius get sheet =>
      const BorderRadius.vertical(top: Radius.circular(xxl));
}
