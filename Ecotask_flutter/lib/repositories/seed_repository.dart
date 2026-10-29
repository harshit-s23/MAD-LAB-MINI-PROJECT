import 'dart:math';

import 'package:uuid/uuid.dart';

import '../core/app_date.dart';
import '../core/constants.dart';
import '../database/database_helper.dart';
import '../database/schema.dart';
import '../models/app_user.dart';
import '../models/badge.dart';
import '../models/task.dart';
import '../services/carbon_engine.dart';
import 'repository_guard.dart';

/// PBKDF2 hash of the public demo password ("demo123"), precomputed so the
/// first launch does not have to spend time hashing.
const String kDemoPasswordHash =
    r'pbkdf2_sha256$50000$ZWNvdGFzay1kZW1vLXNhbA==$AKemvyRJHx7VzDPYxIQTG5CnUpTIpl491XEDJiIeBog=';

class _SeedTask {
  const _SeedTask(this.title, this.category, this.subcategory, this.quantity,
      this.unit, this.daysAgo);

  final String title;
  final String category;
  final String subcategory;
  final double quantity;
  final String unit;
  final int daysAgo;
}

/// Port of `backend/seed.js`: creates the demo account
/// (`demo@ecotask.com` / `demo123`) with 21 sample tasks over the last 7 days
/// so the "Use Demo Account" button on the login screen works offline.
class SeedRepository {
  SeedRepository(this._helper, {Random? random}) : _random = random ?? Random();

  final DatabaseHelper _helper;
  final Random _random;
  static const Uuid _uuid = Uuid();

  // Same data as seed.js (`daysAgo(n)` relative to today).
  static const List<_SeedTask> _tasks = [
    _SeedTask('Drive to office', 'transport', 'car_petrol', 18, 'km', 0),
    _SeedTask('Chicken lunch', 'food', 'chicken', 0.3, 'kg', 0),
    _SeedTask('Home electricity', 'energy', 'electricity', 5, 'kWh', 0),
    _SeedTask('Train to city', 'transport', 'train', 30, 'km', 1),
    _SeedTask('Vegan dinner', 'food', 'vegan_meal', 1, 'meal', 1),
    _SeedTask('Recycled waste', 'waste', 'recycling', 2, 'kg', 1),
    _SeedTask('Cycling to gym', 'transport', 'cycling', 8, 'km', 2),
    _SeedTask('Beef steak', 'food', 'beef', 0.4, 'kg', 2),
    _SeedTask('Solar generated', 'energy', 'solar_panel', 3, 'kWh', 2),
    _SeedTask('Bus commute', 'transport', 'bus', 12, 'km', 3),
    _SeedTask('Plant-based meal', 'food', 'plant_based_meal', 2, 'meal', 3),
    _SeedTask('Online delivery', 'shopping', 'online_shopping', 2, 'parcel', 3),
    _SeedTask('Car trip', 'transport', 'car_petrol', 40, 'km', 4),
    _SeedTask('Electricity use', 'energy', 'electricity', 8, 'kWh', 4),
    _SeedTask('Tree planted', 'other', 'tree_planted', 1, 'tree', 4),
    _SeedTask('Train trip', 'transport', 'train', 50, 'km', 5),
    _SeedTask('Lamb dinner', 'food', 'lamb', 0.2, 'kg', 5),
    _SeedTask('Shower (8 min)', 'water', 'shower', 8, 'min', 5),
    _SeedTask('Walk to market', 'transport', 'walking', 2, 'km', 6),
    _SeedTask('Secondhand buy', 'shopping', 'secondhand', 1, 'item', 6),
    _SeedTask('Composting', 'waste', 'composting', 1.5, 'kg', 6),
  ];

  /// Creates the demo account once. Returns true when it was created.
  Future<bool> ensureDemoUser({DateTime? now}) => guardDb(() async {
        final db = await _helper.database;
        final existing = await db.query(
          Schema.usersTable,
          columns: ['id'],
          where: 'email = ?',
          whereArgs: [AppConstants.demoEmail],
          limit: 1,
        );
        if (existing.isNotEmpty) return false;

        final current = now ?? AppDate.now();
        final stamp = current.toUtc();

        // Same arithmetic as seed.js: sum every task's carbon value, then
        // derive the eco score / level from it.
        final carbons = [
          for (final t in _tasks)
            CarbonEngine.calculateCarbonValue(
                t.category, t.subcategory, t.quantity),
        ];
        final totalCarbon = carbons.fold<double>(0, (sum, c) => sum + c);
        final score = CarbonEngine.calculateEcoScore(totalCarbon, 30);
        final level = CarbonEngine.getEcoLevel(score);

        final userId = _uuid.v4();
        final user = AppUser(
          id: userId,
          name: AppConstants.demoName,
          email: AppConstants.demoEmail,
          totalEcoScore: score,
          streak: 5,
          lastActiveDate: AppDate.dayOf(current),
          badges: const [
            EarnedBadge(id: 'first_task', name: 'First Step', emoji: '🎯'),
            EarnedBadge(id: 'week_streak', name: 'Week Warrior', emoji: '🔥'),
          ],
          level: level.name,
          createdAt: stamp,
          updatedAt: stamp,
        );

        await _helper.transaction((txn) async {
          await txn.insert(Schema.usersTable,
              {...user.toMap(), 'password': kDemoPasswordHash});

          for (var i = 0; i < _tasks.length; i++) {
            final t = _tasks[i];
            final date = AppDate.daysAgo(t.daysAgo, from: current);
            // Offset createdAt by i ms so ordering is deterministic.
            final created = stamp.add(Duration(milliseconds: i));
            final task = Task(
              id: _uuid.v4(),
              userId: userId,
              title: t.title,
              description: '',
              category: t.category,
              subcategory: t.subcategory,
              carbonValue: carbons[i],
              quantity: t.quantity,
              unit: t.unit,
              date: date,
              completed: _random.nextDouble() > 0.3,
              isRecurring: false,
              createdAt: created,
              updatedAt: created,
            );
            await txn.insert(Schema.tasksTable, task.toMap());
            await txn.insert(Schema.carbonLogsTable, {
              'id': _uuid.v4(),
              'userId': userId,
              'taskId': task.id,
              'date': date,
              'category': t.category,
              'carbonAmount': carbons[i],
              'description': t.title,
              'createdAt': created.toIso8601String(),
              'updatedAt': created.toIso8601String(),
            });
          }
        });
        return true;
      });
}
