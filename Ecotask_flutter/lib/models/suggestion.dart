/// One entry returned by `generateSuggestions`.
class Suggestion {
  const Suggestion({
    required this.category,
    required this.tip,
    required this.impact,
    required this.icon,
  });

  final String category;
  final String tip;
  final String impact;
  final String icon;
}
