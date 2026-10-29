/// One entry of ECO_LEVELS in carbonEngine.js.
class EcoLevel {
  const EcoLevel({
    required this.name,
    required this.minScore,
    required this.maxScore,
    required this.emoji,
    required this.colorValue,
  });

  final String name;
  final double minScore;
  final double maxScore;
  final String emoji;

  /// ARGB colour value (convert with `Color(level.colorValue)` in the UI).
  final int colorValue;
}
