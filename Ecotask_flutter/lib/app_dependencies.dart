import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_helper.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/seed_repository.dart';
import 'repositories/stats_repository.dart';
import 'repositories/task_repository.dart';
import 'repositories/user_repository.dart';
import 'services/auth_service.dart';
import 'services/password_service.dart';
import 'services/session_store.dart';

/// Composition root: builds the object graph
/// SQLite -> repositories -> services (providers are created in app.dart).
class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.users,
    required this.tasks,
    required this.dashboard,
    required this.seed,
    required this.auth,
  });

  factory AppDependencies.create(
      {required SharedPreferences prefs,
      DatabaseHelper? database,
      SessionStore? sessions}) {
    final db = database ?? DatabaseHelper();
    final users = UserRepository(db);
    return AppDependencies._(
      database: db,
      users: users,
      tasks: TaskRepository(db, const StatsRepository()),
      dashboard: DashboardRepository(db, users),
      seed: SeedRepository(db),
      auth: AuthService(
        users: users,
        passwords: PasswordService(),
        sessions: sessions ?? SecureSessionStore(prefs),
      ),
    );
  }

  final DatabaseHelper database;
  final UserRepository users;
  final TaskRepository tasks;
  final DashboardRepository dashboard;
  final SeedRepository seed;
  final AuthService auth;
}
