import '../core/app_date.dart';
import '../core/app_exception.dart';
import '../core/number_format.dart';
import '../database/database_helper.dart';
import '../database/schema.dart';
import '../models/dashboard_data.dart';
import '../models/task.dart';
import '../services/carbon_engine.dart';
import 'repository_guard.dart';
import 'user_repository.dart';

/// Port of `getDashboard` from dashboardController.js.
class DashboardRepository {
  DashboardRepository(this._helper, this._users);

  final DatabaseHelper _helper;
  final UserRepository _users;

  /// Matches `toLocaleDateString('en', { weekday: 'short' })`.
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  Future<DashboardData> getDashboard(String userId, {DateTime? now}) =>
      guardDb(() async {
        final current = now ?? AppDate.now();
        final db = await _helper.database;

        final today = AppDate.dayOf(current);
        final weekAgo = AppDate.daysAgo(7, from: current);
        final monthAgo = AppDate.daysAgo(30, from: current);
        final prevWeekStart = AppDate.daysAgo(14, from: current);
        final prevWeekEnd = weekAgo;

        // One query covers every window (all of them start within 30 days).
        final rows = await db.query(
          Schema.carbonLogsTable,
          columns: ['date', 'category', 'carbonAmount'],
          where: 'userId = ? AND date >= ?',
          whereArgs: [userId, monthAgo],
          orderBy: 'rowid ASC',
        );
        final logs = rows
            .map((r) => (
                  date: r['date']! as String,
                  category: r['category']! as String,
                  amount: (r['carbonAmount']! as num).toDouble(),
                ))
            .toList(growable: false);

        double sum(
            Iterable<({String date, String category, double amount})> items) {
          var total = 0.0;
          for (final l in items) {
            total += l.amount;
          }
          return total;
        }

        final todayCarbon = sum(logs.where((l) => l.date == today));
        final weeklyLogs = logs
            .where((l) => l.date.compareTo(weekAgo) >= 0)
            .toList(growable: false);
        final weeklyCarbon = sum(weeklyLogs);
        final prevWeekCarbon = sum(logs.where(
          (l) =>
              l.date.compareTo(prevWeekStart) >= 0 &&
              l.date.compareTo(prevWeekEnd) <= 0,
        ));
        final monthlyCarbon = sum(logs);

        // Weekly trend (last 7 days, oldest first).
        final weeklyTrend = <TrendPoint>[];
        for (var i = 6; i >= 0; i--) {
          final d = AppDate.minusDays(current, i);
          final dateStr = AppDate.dayOf(d);
          final dayCarbon = sum(weeklyLogs.where((l) => l.date == dateStr));
          weeklyTrend.add(TrendPoint(
            date: dateStr,
            day: _weekdays[d.weekday - 1],
            carbon: JsNumber.round(dayCarbon, 2),
          ));
        }

        // Category breakdown over the last 30 days (insertion ordered).
        final breakdown = <String, CategoryAggregate>{};
        for (final l in logs) {
          final agg = breakdown.putIfAbsent(l.category, CategoryAggregate.new);
          agg.totalCarbon += l.amount;
          agg.count++;
        }
        final denominator = monthlyCarbon == 0 ? 1.0 : monthlyCarbon;
        final indexed = breakdown.entries.toList(growable: false);
        final categoryData = <CategoryStat>[
          for (final e in indexed)
            CategoryStat(
              category: e.key,
              totalCarbon: JsNumber.round(e.value.totalCarbon, 2),
              count: e.value.count,
              percentage:
                  JsNumber.round((e.value.totalCarbon / denominator) * 100, 1),
            ),
        ];
        // Stable sort by totalCarbon desc (Dart's sort is not guaranteed stable).
        final order = {
          for (var i = 0; i < categoryData.length; i++) categoryData[i]: i
        };
        categoryData.sort((a, b) {
          final c = b.totalCarbon.compareTo(a.totalCarbon);
          return c != 0 ? c : order[a]!.compareTo(order[b]!);
        });

        final recentRows = await db.query(
          Schema.tasksTable,
          where: 'userId = ?',
          whereArgs: [userId],
          orderBy: 'date DESC, createdAt DESC, rowid DESC',
          limit: 5,
        );
        final recentTasks =
            recentRows.map(Task.fromMap).toList(growable: false);

        final suggestions = CarbonEngine.generateSuggestions(breakdown);

        final weekChange = prevWeekCarbon > 0
            ? JsNumber.round(
                ((weeklyCarbon - prevWeekCarbon) / prevWeekCarbon) * 100, 1)
            : 0.0;

        final user = await _users.findById(userId);
        if (user == null) throw const AppException('User not found');

        return DashboardData(
          todayCarbon: JsNumber.round(todayCarbon, 2),
          weeklyCarbon: JsNumber.round(weeklyCarbon, 2),
          weekChange: weekChange,
          monthlyCarbon: JsNumber.round(monthlyCarbon, 2),
          weeklyTrend: weeklyTrend,
          categoryData: categoryData,
          recentTasks: recentTasks,
          suggestions: suggestions,
          user: user,
        );
      });
}
