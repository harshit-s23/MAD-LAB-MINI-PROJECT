import 'app_user.dart';
import 'suggestion.dart';
import 'task.dart';

class TrendPoint {
  const TrendPoint(
      {required this.date, required this.day, required this.carbon});

  /// `yyyy-MM-dd`
  final String date;

  /// Short weekday ("Mon").
  final String day;
  final double carbon;
}

class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.totalCarbon,
    required this.count,
    required this.percentage,
  });

  final String category;
  final double totalCarbon;
  final int count;
  final double percentage;
}

/// Mirror of the `dashboard` object returned by GET /api/dashboard.
class DashboardData {
  const DashboardData({
    required this.todayCarbon,
    required this.weeklyCarbon,
    required this.weekChange,
    required this.monthlyCarbon,
    required this.weeklyTrend,
    required this.categoryData,
    required this.recentTasks,
    required this.suggestions,
    required this.user,
  });

  final double todayCarbon;
  final double weeklyCarbon;

  /// Percent change vs previous week (0 when no previous data).
  final double weekChange;
  final double monthlyCarbon;
  final List<TrendPoint> weeklyTrend;
  final List<CategoryStat> categoryData;
  final List<Task> recentTasks;
  final List<Suggestion> suggestions;
  final AppUser user;
}
