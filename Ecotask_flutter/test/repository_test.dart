import 'package:ecotask/core/app_date.dart';
import 'package:ecotask/core/app_exception.dart';
import 'package:ecotask/models/task_input.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_env.dart';

TaskInput input({
  String title = 'Commute',
  String category = 'transport',
  String subcategory = 'car_petrol',
  double quantity = 10,
  String unit = 'km',
  String? date,
}) =>
    TaskInput(
        title: title,
        category: category,
        subcategory: subcategory,
        quantity: quantity,
        unit: unit,
        date: date ?? AppDate.today());

void main() {
  late TestEnv env;
  late String userId;

  setUp(() async {
    env = await TestEnv.create();
    userId = (await env.users
            .create(name: 'Test User', email: 't@x.com', passwordHash: 'h'))
        .id;
  });
  tearDown(() => env.dispose());

  group('UserRepository', () {
    test('new users get the original model defaults', () async {
      final u = (await env.users.findById(userId))!;
      expect(u.totalEcoScore, 100);
      expect(u.streak, 0);
      expect(u.level, 'Seedling');
      expect(u.badges, isEmpty);
      expect(u.lastActiveDate, '2026-10-22');
      // ...but the displayed level is derived from the score (100 -> Earth Guardian).
      expect(u.levelData.name, 'Earth Guardian');
    });

    test('duplicate e-mail is rejected', () async {
      expect(
          () => env.users
              .create(name: 'Other', email: 't@x.com', passwordHash: 'h'),
          throwsA(isA<AppException>()));
    });

    test('lookups', () async {
      expect(await env.users.findById('missing'), isNull);
      expect((await env.users.findCredentialsByEmail('t@x.com'))!.passwordHash,
          'h');
      expect(await env.users.findCredentialsByEmail('nobody@x.com'), isNull);
      expect(await env.users.emailExists('t@x.com'), isTrue);
    });
  });

  group('createTask', () {
    test('stores carbon value, a carbon log, and refreshes user stats',
        () async {
      final r = await env.tasks.createTask(userId, input());
      expect(r.task.carbonValue, 2.1);
      expect(r.task.completed, isFalse);
      expect(r.stats.ecoScore, 99.7);
      expect(r.stats.level.name, 'Earth Guardian');

      final db = await env.helper.database;
      final logs = await db.query('carbon_logs');
      expect(logs.length, 1);
      expect(logs.single['carbonAmount'], 2.1);
      expect(logs.single['taskId'], r.task.id);
      expect(logs.single['description'], 'Commute');

      final u = (await env.users.findById(userId))!;
      expect(u.totalEcoScore, 99.7);
      expect(u.level, 'Earth Guardian');
      expect(
          u.badges.map((b) => b.id).toList(), ['first_task', 'earth_guardian']);
    });

    test('the very first streak stays 0 on the signup day (original behaviour)',
        () async {
      final r = await env.tasks.createTask(userId, input());
      expect(r.stats.streak, 0);
    });

    test('subcategory without a factor stores 0 carbon', () async {
      final r = await env.tasks.createTask(userId, input(subcategory: ''));
      expect(r.task.carbonValue, 0);
    });

    test('empty unit falls back to "unit"', () async {
      final r = await env.tasks.createTask(userId, input(unit: ''));
      expect(r.task.unit, 'unit');
    });

    test('validation errors are user-presentable AppExceptions', () async {
      expect(() => env.tasks.createTask(userId, input(title: '  ')),
          throwsA(isA<AppException>()));
      expect(() => env.tasks.createTask(userId, input(title: 'x' * 201)),
          throwsA(isA<AppException>()));
      expect(() => env.tasks.createTask(userId, input(category: 'bogus')),
          throwsA(isA<AppException>()));
      expect(() => env.tasks.createTask(userId, input(date: '2026-02-30')),
          throwsA(isA<AppException>()));
      expect(() => env.tasks.createTask(userId, input(quantity: 0)),
          throwsA(isA<AppException>()));
      expect(await env.tasks.getTasks(userId), isEmpty);
    });
  });

  group('streak and badges (original quirks)', () {
    Future<void> setUser({int? streak, String? lastActive}) async {
      final db = await env.helper.database;
      await db.update(
          'users',
          {
            if (streak != null) 'streak': streak,
            if (lastActive != null) 'lastActiveDate': lastActive
          },
          where: 'id = ?',
          whereArgs: [userId]);
    }

    test('active yesterday -> streak increments', () async {
      await setUser(streak: 2, lastActive: '2026-10-21');
      final r = await env.tasks.createTask(userId, input());
      expect(r.stats.streak, 3);
      expect((await env.users.findById(userId))!.lastActiveDate, '2026-10-22');
    });

    test('a gap resets the streak to 1', () async {
      await setUser(streak: 9, lastActive: '2026-10-18');
      expect((await env.tasks.createTask(userId, input())).stats.streak, 1);
    });

    test('a second task on the same day does not change the streak', () async {
      await setUser(streak: 2, lastActive: '2026-10-21');
      await env.tasks.createTask(userId, input());
      expect((await env.tasks.createTask(userId, input())).stats.streak, 3);
    });

    test('week_streak is awarded from the OLD streak value', () async {
      await setUser(streak: 6, lastActive: '2026-10-21');
      final r = await env.tasks.createTask(userId, input());
      expect(r.stats.streak, 7);
      expect(
          (await env.users.findById(userId))!
              .badges
              .any((b) => b.id == 'week_streak'),
          isFalse);

      await setUser(streak: 7, lastActive: '2026-10-21');
      await env.tasks.createTask(userId, input());
      expect(
          (await env.users.findById(userId))!
              .badges
              .any((b) => b.id == 'week_streak'),
          isTrue);
    });
  });

  group('updateTask', () {
    test('changing quantity recalculates the task and its carbon log',
        () async {
      final created = (await env.tasks.createTask(userId, input())).task;
      final r = await env.tasks
          .updateTask(userId, created.id, const TaskUpdate(quantity: 20));
      expect(r.task.carbonValue, 4.2);
      final db = await env.helper.database;
      expect((await db.query('carbon_logs')).single['carbonAmount'], 4.2);
      expect(r.stats.ecoScore, 99.5);
    });

    test('changing category and date moves the log', () async {
      final created = (await env.tasks.createTask(userId, input())).task;
      await env.tasks.updateTask(
          userId,
          created.id,
          const TaskUpdate(
              category: 'food',
              subcategory: 'beef',
              quantity: 1,
              date: '2026-10-20'));
      final log =
          (await (await env.helper.database).query('carbon_logs')).single;
      expect(log['category'], 'food');
      expect(log['date'], '2026-10-20');
      expect(log['carbonAmount'], 27.0);
    });

    test('toggling completed leaves carbon untouched and is reversible',
        () async {
      final created = (await env.tasks.createTask(userId, input())).task;
      final done = await env.tasks
          .updateTask(userId, created.id, const TaskUpdate(completed: true));
      expect(done.task.completed, isTrue);
      expect(done.task.carbonValue, 2.1);
      final undone = await env.tasks
          .updateTask(userId, created.id, const TaskUpdate(completed: false));
      expect(undone.task.completed, isFalse);
    });

    test(
        'empty strings keep old values (JS || semantics); description may be cleared',
        () async {
      final created = (await env.tasks.createTask(
              userId,
              TaskInput(
                  title: 'Orig',
                  description: 'note',
                  category: 'transport',
                  subcategory: 'bus',
                  quantity: 10,
                  unit: 'km',
                  date: AppDate.today())))
          .task;
      final r = await env.tasks.updateTask(userId, created.id,
          const TaskUpdate(title: '', description: '', unit: ''));
      expect(r.task.title, 'Orig');
      expect(r.task.unit, 'km');
      expect(r.task.description, '');
    });

    test('isRecurring cannot be changed by an update (original behaviour)',
        () async {
      final created = (await env.tasks.createTask(
              userId,
              TaskInput(
                  title: 'R',
                  category: 'food',
                  subcategory: 'dairy',
                  date: AppDate.today(),
                  isRecurring: true)))
          .task;
      final r = await env.tasks
          .updateTask(userId, created.id, const TaskUpdate(title: 'R2'));
      expect(r.task.isRecurring, isTrue);
    });

    test('missing task and other users tasks are "not found"', () async {
      expect(
          () => env.tasks
              .updateTask(userId, 'nope', const TaskUpdate(title: 'x')),
          throwsA(isA<AppException>()));
      final other = (await env.users
              .create(name: 'Other', email: 'o@x.com', passwordHash: 'h'))
          .id;
      final t = (await env.tasks.createTask(other, input())).task;
      expect(
          () =>
              env.tasks.updateTask(userId, t.id, const TaskUpdate(title: 'x')),
          throwsA(isA<AppException>()));
      expect(() => env.tasks.deleteTask(userId, t.id),
          throwsA(isA<AppException>()));
    });
  });

  group('deleteTask', () {
    test('removes task and log and recomputes the score; badges are kept',
        () async {
      final created =
          (await env.tasks.createTask(userId, input(quantity: 3000))).task;
      expect((await env.users.findById(userId))!.totalEcoScore < 100, isTrue);
      final stats = await env.tasks.deleteTask(userId, created.id);
      expect(stats.ecoScore, 100);
      final db = await env.helper.database;
      expect(await db.query('tasks'), isEmpty);
      expect(await db.query('carbon_logs'), isEmpty);
      expect(
          (await env.users.findById(userId))!
              .badges
              .any((b) => b.id == 'first_task'),
          isTrue);
    });
  });

  group('getTasks', () {
    setUp(() async {
      await env.tasks.createTask(userId, input(title: 'A', date: '2026-10-20'));
      await env.tasks.createTask(
          userId,
          input(
              title: 'B',
              category: 'food',
              subcategory: 'dairy',
              date: '2026-10-22'));
      await env.tasks.createTask(
          userId,
          input(
              title: 'C',
              category: 'food',
              subcategory: 'beef',
              date: '2026-10-22'));
      await env.tasks.createTask(userId, input(title: 'D', date: '2026-10-18'));
    });

    test('sorted by date desc then newest first', () async {
      expect((await env.tasks.getTasks(userId)).map((t) => t.title).toList(),
          ['C', 'B', 'A', 'D']);
    });

    test('category, date and range filters', () async {
      expect((await env.tasks.getTasks(userId, category: 'food')).length, 2);
      expect(
          (await env.tasks.getTasks(userId, date: '2026-10-20')).single.title,
          'A');
      expect(
          (await env.tasks.getTasks(userId,
                  startDate: '2026-10-19', endDate: '2026-10-22'))
              .length,
          3);
      expect(
          (await env.tasks
              .getTasks(userId, category: 'food', date: '2026-10-20')),
          isEmpty);
    });

    test('tasks are isolated per user', () async {
      final other = (await env.users
              .create(name: 'Other', email: 'o@x.com', passwordHash: 'h'))
          .id;
      expect(await env.tasks.getTasks(other), isEmpty);
    });
  });

  group('dashboard', () {
    Future<void> seedWindow() async {
      Future<void> add(String t, String c, String s, double q, int ago) =>
          env.tasks.createTask(
              userId,
              TaskInput(
                  title: t,
                  category: c,
                  subcategory: s,
                  quantity: q,
                  date: AppDate.daysAgo(ago)));
      await add('Petrol', 'transport', 'car_petrol', 10, 0); // 2.1
      await add('Steak', 'food', 'beef', 0.5, 0); // 13.5
      await add('Train', 'transport', 'train', 20, 1); // 0.82
      await add('Recycle', 'waste', 'recycling', 4, 1); // -2
      await add('Bus', 'transport', 'bus', 10, 6); // 0.89
      await add(
          'Power', 'energy', 'electricity', 10, 8); // 2.33 (previous week)
      await add('Shirt', 'shopping', 'clothing', 1, 20); // 5 (month only)
      await add(
          'Laptop', 'shopping', 'electronics', 1, 40); // 70 (outside 30 days)
    }

    test('aggregates match hand-computed values', () async {
      await seedWindow();
      final d = await env.dashboard.getDashboard(userId);
      expect(d.todayCarbon, 15.6);
      expect(d.weeklyCarbon, 15.31);
      expect(d.monthlyCarbon, 22.64);
      expect(d.weekChange, 557.1);
    });

    test('weekly trend has 7 labelled days, oldest first', () async {
      await seedWindow();
      final d = await env.dashboard.getDashboard(userId);
      expect(d.weeklyTrend.map((p) => p.day).toList(),
          ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu']);
      expect(d.weeklyTrend.map((p) => p.carbon).toList(),
          [0.89, 0, 0, 0, 0, -1.18, 15.6]);
      expect(d.weeklyTrend.first.date, '2026-10-16');
    });

    test('category breakdown is sorted by total with percentages of the month',
        () async {
      await seedWindow();
      final d = await env.dashboard.getDashboard(userId);
      expect(d.categoryData.map((c) => c.category).toList(),
          ['food', 'shopping', 'transport', 'energy', 'waste']);
      final food = d.categoryData.first;
      expect(food.totalCarbon, 13.5);
      expect(food.count, 1);
      expect(food.percentage, 59.6);
      expect(
          d.categoryData.firstWhere((c) => c.category == 'transport').count, 3);
    });

    test('suggestions follow the original rules', () async {
      await seedWindow();
      final d = await env.dashboard.getDashboard(userId);
      expect(d.suggestions.map((s) => s.category).toList(), ['food', 'waste']);
    });

    test('recent tasks: five newest', () async {
      await seedWindow();
      final d = await env.dashboard.getDashboard(userId);
      expect(d.recentTasks.length, 5);
      expect(d.recentTasks.first.title, 'Steak');
    });

    test('empty account', () async {
      final d = await env.dashboard.getDashboard(userId);
      expect(d.todayCarbon, 0);
      expect(d.weekChange, 0);
      expect(d.categoryData, isEmpty);
      expect(d.recentTasks, isEmpty);
      expect(d.weeklyTrend.length, 7);
      expect(
          d.suggestions.map((s) => s.category).toList(), ['waste', 'general']);
      expect(d.user.totalEcoScore, 100);
    });

    test('missing user is an AppException', () async {
      expect(() => env.dashboard.getDashboard('ghost'),
          throwsA(isA<AppException>()));
    });
  });

  group('demo seed', () {
    test('creates the demo account once with 21 tasks', () async {
      expect(await env.seed.ensureDemoUser(), isTrue);
      expect(await env.seed.ensureDemoUser(), isFalse);
      final demo =
          (await env.users.findCredentialsByEmail('demo@ecotask.com'))!;
      expect(demo.user.name, 'Alex Green');
      expect(demo.user.streak, 5);
      expect(demo.user.badges.map((b) => b.id).toList(),
          ['first_task', 'week_streak']);
      final tasks = await env.tasks.getTasks(demo.user.id);
      expect(tasks.length, 21);
      final db = await env.helper.database;
      expect(
          (await db.query('carbon_logs',
                  where: 'userId = ?', whereArgs: [demo.user.id]))
              .length,
          21);
      expect(tasks.first.date, '2026-10-22');
    });

    test('demo dashboard is populated', () async {
      await env.seed.ensureDemoUser();
      final demo =
          (await env.users.findCredentialsByEmail('demo@ecotask.com'))!.user;
      final d = await env.dashboard.getDashboard(demo.id);
      expect(d.categoryData, isNotEmpty);
      expect(d.weeklyTrend.any((p) => p.carbon != 0), isTrue);
      expect(d.user.level, d.user.levelData.name);
    });
  });
}
