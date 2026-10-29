import 'eco_level.dart';

/// Result of `refreshUserStats` in taskController.js.
class UserStats {
  const UserStats({
    required this.ecoScore,
    required this.level,
    required this.streak,
  });

  final double ecoScore;
  final EcoLevel level;
  final int streak;
}
