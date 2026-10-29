import 'package:ecotask/core/app_date.dart';
import 'package:ecotask/database/database_helper.dart';
import 'package:ecotask/repositories/dashboard_repository.dart';
import 'package:ecotask/repositories/seed_repository.dart';
import 'package:ecotask/repositories/stats_repository.dart';
import 'package:ecotask/repositories/task_repository.dart';
import 'package:ecotask/repositories/user_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The fixed "now" used by repository tests: Thursday 22 Oct 2026, noon.
final DateTime kNow = DateTime(2026, 10, 22, 12);

/// Fresh in-memory SQLite database + the full repository graph.
class TestEnv {
  TestEnv._(this.helper)
      : users = UserRepository(helper),
        tasks = TaskRepository(helper, const StatsRepository()),
        seed = SeedRepository(helper) {
    dashboard = DashboardRepository(helper, users);
  }

  final DatabaseHelper helper;
  final UserRepository users;
  final TaskRepository tasks;
  final SeedRepository seed;
  late final DashboardRepository dashboard;

  static Future<TestEnv> create({DateTime? now}) async {
    sqfliteFfiInit();
    AppDate.now = () => now ?? kNow;
    final helper =
        DatabaseHelper(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    await helper.database; // create schema
    return TestEnv._(helper);
  }

  Future<void> dispose() async {
    AppDate.now = DateTime.now;
    await helper.close();
  }
}
