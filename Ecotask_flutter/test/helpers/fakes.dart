import 'dart:async';

import 'package:ecotask/core/app_exception.dart';

import 'package:ecotask/models/app_user.dart';
import 'package:ecotask/models/dashboard_data.dart';
import 'package:ecotask/models/task.dart';
import 'package:ecotask/models/user_stats.dart';
import 'package:ecotask/repositories/dashboard_repository.dart';
import 'package:ecotask/repositories/seed_repository.dart';
import 'package:ecotask/repositories/task_repository.dart';
import 'package:ecotask/services/auth_service.dart';
import 'package:ecotask/services/carbon_engine.dart';

AppUser fakeUser({double score = 100, int streak = 0}) => AppUser(
      id: 'user-1',
      name: 'Jane Doe',
      email: 'jane@example.com',
      totalEcoScore: score,
      streak: streak,
      lastActiveDate: '2026-10-22',
      badges: const [],
      level: 'Seedling',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

Task fakeTask({
  String id = 't1',
  String title = 'Morning commute',
  String category = 'transport',
  String subcategory = 'car_petrol',
  double carbon = 2.1,
  double quantity = 10,
  String unit = 'km',
  String date = '2026-10-22',
  bool completed = false,
  String description = '',
}) =>
    Task(
      id: id,
      userId: 'user-1',
      title: title,
      description: description,
      category: category,
      subcategory: subcategory,
      carbonValue: carbon,
      quantity: quantity,
      unit: unit,
      date: date,
      completed: completed,
      isRecurring: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

class FakeAuthService implements AuthService {
  FakeAuthService({this.restoreUser});

  AppUser? restoreUser;
  AppUser? loggedIn;
  String? failLoginWith;
  final List<String> loginEmails = [];
  bool loggedOut = false;

  @override
  Future<AppUser?> restoreSession() async => restoreUser;

  @override
  Future<AppUser> login(
      {required String email, required String password}) async {
    loginEmails.add(email);
    if (failLoginWith != null) throw AppException(failLoginWith!);
    loggedIn = fakeUser();
    return loggedIn!;
  }

  @override
  Future<AppUser?> currentUser(String userId) async => loggedIn ?? restoreUser;

  @override
  Future<void> logout() async => loggedOut = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSeed implements SeedRepository {
  @override
  Future<bool> ensureDemoUser({DateTime? now}) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(this.tasks);

  List<Task> tasks;
  final List<String> deleted = [];

  @override
  Future<List<Task>> getTasks(String userId,
      {String? date,
      String? category,
      String? startDate,
      String? endDate}) async {
    return tasks
        .where((t) =>
            (category == null || t.category == category) &&
            (date == null || t.date == date))
        .toList();
  }

  @override
  Future<UserStats> deleteTask(String userId, String taskId,
      {DateTime? now}) async {
    deleted.add(taskId);
    tasks = tasks.where((t) => t.id != taskId).toList();
    return UserStats(
        ecoScore: 100, level: CarbonEngine.ecoLevels.last, streak: 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository([this.data]);

  /// When null the request never completes (keeps the loading state).
  DashboardData? data;

  @override
  Future<DashboardData> getDashboard(String userId, {DateTime? now}) {
    final d = data;
    if (d == null) return Completer<DashboardData>().future;
    return Future.value(d);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
