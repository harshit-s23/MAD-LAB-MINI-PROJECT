import 'package:sqflite/sqflite.dart';

import '../core/app_date.dart';
import '../core/app_exception.dart';
import '../database/schema.dart';
import '../models/app_user.dart';
import '../models/badge.dart';
import '../models/user_stats.dart';
import '../services/carbon_engine.dart';

/// Port of `refreshUserStats` from taskController.js.
///
/// Runs after every task create / update / delete: recomputes the 30-day eco
/// score, level, streak and badges and persists them on the user row.
class StatsRepository {
  const StatsRepository();

  Future<UserStats> refreshUserStats(
    DatabaseExecutor ex,
    String userId, {
    DateTime? now,
  }) async {
    final current = now ?? AppDate.now();
    final today = AppDate.dayOf(current);
    final thirtyDaysAgo = AppDate.daysAgo(30, from: current);

    // Sum in Dart (sequentially, like Array.reduce) rather than SQL SUM() so
    // floating point results are identical to the original.
    final logs = await ex.query(
      Schema.carbonLogsTable,
      columns: ['carbonAmount'],
      where: 'userId = ? AND date >= ?',
      whereArgs: [userId, thirtyDaysAgo],
      orderBy: 'rowid ASC',
    );
    var totalCarbon = 0.0;
    for (final l in logs) {
      totalCarbon += (l['carbonAmount'] as num).toDouble();
    }

    final ecoScore = CarbonEngine.calculateEcoScore(totalCarbon, 30);
    final level = CarbonEngine.getEcoLevel(ecoScore);

    final userRows = await ex.query(Schema.usersTable,
        where: 'id = ?', whereArgs: [userId], limit: 1);
    if (userRows.isEmpty) throw const AppException('User not found');
    final user = AppUser.fromMap(userRows.first);

    final totalTasks = Sqflite.firstIntValue(
          await ex.rawQuery(
              'SELECT COUNT(*) FROM ${Schema.tasksTable} WHERE userId = ?',
              [userId]),
        ) ??
        0;

    final newStreak = CarbonEngine.updateStreak(
      streak: user.streak,
      lastActiveDate: user.lastActiveDate,
      now: current,
    );
    // NOTE: uses the *old* streak, exactly like the original controller.
    final newBadges = CarbonEngine.checkBadges(
      currentBadges: user.badges,
      streak: user.streak,
      totalTasks: totalTasks,
      ecoScore: ecoScore,
    );

    await ex.update(
      Schema.usersTable,
      {
        'totalEcoScore': ecoScore,
        'level': level.name,
        'badges': EarnedBadge.encodeList(newBadges),
        'streak': newStreak,
        'lastActiveDate': today,
        'updatedAt': current.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    return UserStats(ecoScore: ecoScore, level: level, streak: newStreak);
  }
}
