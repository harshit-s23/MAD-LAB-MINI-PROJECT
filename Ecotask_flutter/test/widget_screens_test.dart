import 'package:ecotask/models/badge.dart';
import 'package:ecotask/models/dashboard_data.dart';
import 'package:ecotask/providers/auth_provider.dart';
import 'package:ecotask/providers/dashboard_provider.dart';
import 'package:ecotask/providers/task_provider.dart';
import 'package:ecotask/router/app_router.dart';
import 'package:ecotask/screens/dashboard_screen.dart';
import 'package:ecotask/screens/login_screen.dart';
import 'package:ecotask/screens/register_screen.dart';
import 'package:ecotask/screens/tasks_screen.dart';
import 'package:ecotask/services/carbon_engine.dart';
import 'package:ecotask/theme/app_theme.dart';
import 'package:ecotask/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

void bigScreen(WidgetTester tester, {double w = 420, double h = 2400}) {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<AuthProvider> authWith(FakeAuthService service) async {
  final auth = AuthProvider(authService: service, seeder: FakeSeed());
  await auth.bootstrap();
  return auth;
}

Widget app(AuthProvider auth, Widget home,
    {FakeDashboardRepository? dash, FakeTaskRepository? tasks}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<TaskProvider>(
          create: (_) => TaskProvider(
              repository: tasks ?? FakeTaskRepository([]), auth: auth)),
      ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(
              repository: dash ?? FakeDashboardRepository(), auth: auth)),
    ],
    child: MaterialApp(
        theme: AppTheme.light,
        scaffoldMessengerKey: AppToast.messengerKey,
        home: home),
  );
}

DashboardData sampleDashboard(
        {double change = -12.5, double score = 67.5, int streak = 5}) =>
    DashboardData(
      todayCarbon: 15.6,
      weeklyCarbon: 15.31,
      weekChange: change,
      monthlyCarbon: 22.64,
      weeklyTrend: [
        for (var i = 0; i < 7; i++)
          TrendPoint(
              date: 'd$i',
              day: ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'][i],
              carbon: i * 1.5)
      ],
      categoryData: const [
        CategoryStat(
            category: 'food', totalCarbon: 13.5, count: 1, percentage: 59.6)
      ],
      recentTasks: [
        fakeTask(title: 'Steak dinner', category: 'food', carbon: 13.5),
        fakeTask(id: 't2', title: 'Recycling', category: 'waste', carbon: -2)
      ],
      suggestions: CarbonEngine.generateSuggestions({}),
      user: fakeUser(score: score, streak: streak),
    );

void main() {
  group('LoginScreen', () {
    testWidgets('empty form shows validation messages and does not call login',
        (tester) async {
      bigScreen(tester);
      final service = FakeAuthService();
      final auth = await authWith(service);
      await tester.pumpWidget(app(auth, const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(service.loginEmails, isEmpty);
    });

    testWidgets('invalid e-mail is rejected', (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService());
      await tester.pumpWidget(app(auth, const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(find.byKey(const Key('login-email')), 'nope');
      await tester.enterText(
          find.byKey(const Key('login-password')), 'secret1');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Use Demo Account fills the credentials', (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService());
      await tester.pumpWidget(app(auth, const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Use Demo Account'));
      await tester.pump();
      expect(find.text('demo@ecotask.com'), findsOneWidget);
    });

    testWidgets('server error is shown as a toast', (tester) async {
      bigScreen(tester);
      final service = FakeAuthService()..failLoginWith = 'Invalid credentials';
      final auth = await authWith(service);
      await tester.pumpWidget(app(auth, const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(
          find.byKey(const Key('login-email')), 'jane@example.com');
      await tester.enterText(
          find.byKey(const Key('login-password')), 'wrongpw');
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(service.loginEmails, ['jane@example.com']);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('validates name, e-mail and password length', (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService());
      await tester.pumpWidget(app(auth, const RegisterScreen()));
      await tester.pump(const Duration(milliseconds: 600));

      await tester.enterText(find.byKey(const Key('register-name')), 'J');
      await tester.enterText(find.byKey(const Key('register-email')), 'bad');
      await tester.enterText(find.byKey(const Key('register-password')), '123');
      await tester.tap(find.text('Create Account'));
      await tester.pump();
      expect(find.textContaining('Name must be between'), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });

  group('DashboardScreen', () {
    testWidgets('shows a loading state, then the data', (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(app(auth, const Scaffold(body: DashboardScreen()),
          dash: FakeDashboardRepository()));
      await tester.pump();
      expect(find.text('Loading your eco data...'), findsOneWidget);
    });

    testWidgets(
        'renders score, streak, stats, insight, suggestions, badges and recent tasks',
        (tester) async {
      bigScreen(tester);
      final auth = await authWith(
          FakeAuthService(restoreUser: fakeUser(score: 67.5, streak: 5)));
      await tester.pumpWidget(app(auth, const Scaffold(body: DashboardScreen()),
          dash: FakeDashboardRepository(sampleDashboard())));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('Hello, Jane'), findsOneWidget);
      expect(find.text('68'), findsOneWidget);
      expect(find.text('Tree'), findsOneWidget);
      expect(find.text('🔥 5'), findsOneWidget);
      expect(find.text('15.60'), findsOneWidget);
      expect(find.text('15.31'), findsOneWidget);
      expect(find.text('22.64'), findsOneWidget);
      expect(find.text('-12.5% vs last week'), findsOneWidget);
      expect(
          find.textContaining('You reduced your emissions by'), findsOneWidget);
      expect(find.text('Smart Suggestions 💡'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('Recent Activities'), findsOneWidget);
      expect(find.text('Steak dinner'), findsOneWidget);
    });

    testWidgets('an increase shows the amber banner', (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(app(auth, const Scaffold(body: DashboardScreen()),
          dash: FakeDashboardRepository(sampleDashboard(change: 40))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('You increased your emissions by'),
          findsOneWidget);
      expect(find.text('+40% vs last week'), findsOneWidget);
    });

    testWidgets('no banner and "No previous data" when the change is 0',
        (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(app(auth, const Scaffold(body: DashboardScreen()),
          dash: FakeDashboardRepository(sampleDashboard(change: 0))));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('insight-banner')), findsNothing);
      expect(find.text('No previous data'), findsOneWidget);
    });

    testWidgets('earned badges are highlighted', (tester) async {
      bigScreen(tester);
      final base = sampleDashboard();
      final data = DashboardData(
        todayCarbon: base.todayCarbon,
        weeklyCarbon: base.weeklyCarbon,
        weekChange: base.weekChange,
        monthlyCarbon: base.monthlyCarbon,
        weeklyTrend: base.weeklyTrend,
        categoryData: base.categoryData,
        recentTasks: base.recentTasks,
        suggestions: base.suggestions,
        user: base.user.copyWith(badges: const [
          EarnedBadge(id: 'week_streak', name: 'Week Warrior', emoji: '🔥')
        ]),
      );
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(app(auth, const Scaffold(body: DashboardScreen()),
          dash: FakeDashboardRepository(data)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(
          tester
              .widget<Opacity>(find.byKey(const Key('badge-week_streak')))
              .opacity,
          1);
      expect(
          tester
              .widget<Opacity>(find.byKey(const Key('badge-first_task')))
              .opacity,
          0.4);
    });
  });

  group('TasksScreen', () {
    testWidgets('empty state', (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(app(auth, const Scaffold(body: TasksScreen())));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No activities yet'), findsOneWidget);
      expect(find.text('Log your first activity'), findsOneWidget);
    });

    testWidgets('lists activities with summary totals and filters by title',
        (tester) async {
      bigScreen(tester);
      final repo = FakeTaskRepository([
        fakeTask(
            id: 'a',
            title: 'Bike to work',
            category: 'transport',
            subcategory: 'cycling',
            carbon: -0.16),
        fakeTask(
            id: 'b',
            title: 'Steak dinner',
            category: 'food',
            subcategory: 'beef',
            carbon: 13.5),
      ]);
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(
          app(auth, const Scaffold(body: TasksScreen()), tasks: repo));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Bike to work'), findsOneWidget);
      expect(find.text('Steak dinner'), findsOneWidget);
      expect(find.text('13.50'), findsOneWidget); // emitted
      expect(find.text('0.16'), findsOneWidget); // saved
      expect(find.text('13.34'), findsOneWidget); // net

      await tester.enterText(find.byKey(const Key('task-search')), 'bike');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Bike to work'), findsOneWidget);
      expect(find.text('Steak dinner'), findsNothing);
      expect(find.byKey(const Key('clear-filters')), findsOneWidget);
    });

    testWidgets('delete asks for confirmation first', (tester) async {
      bigScreen(tester);
      final repo =
          FakeTaskRepository([fakeTask(id: 'a', title: 'Bike to work')]);
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(
          app(auth, const Scaffold(body: TasksScreen()), tasks: repo));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('🗑 Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this activity?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.deleted, isEmpty);

      await tester.tap(find.text('🗑 Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(repo.deleted, ['a']);
      expect(find.text('Bike to work'), findsNothing);
    });

    testWidgets('the add button opens the log sheet', (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(app(auth, const Scaffold(body: TasksScreen())));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('add-activity')));
      await tester.pumpAndSettle();
      expect(find.text('Track your carbon impact'), findsOneWidget);
    });
  });

  group('router guards', () {
    Widget routerApp(AuthProvider auth, {FakeDashboardRepository? dash}) {
      final router = createRouter(auth);
      addTearDown(router.dispose);
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<TaskProvider>(
              create: (_) =>
                  TaskProvider(repository: FakeTaskRepository([]), auth: auth)),
          ChangeNotifierProvider<DashboardProvider>(
              create: (_) => DashboardProvider(
                  repository: dash ?? FakeDashboardRepository(), auth: auth)),
        ],
        child: MaterialApp.router(
            theme: AppTheme.light,
            scaffoldMessengerKey: AppToast.messengerKey,
            routerConfig: router),
      );
    }

    testWidgets(
        'signed-out users land on the login screen and cannot reach protected routes',
        (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService());
      await tester.pumpWidget(routerApp(auth));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Welcome back'), findsOneWidget);

      final router = GoRouter.of(tester.element(find.byType(LoginScreen)));
      router.go('/tasks');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Activities'), findsNothing);
    });

    testWidgets(
        'a restored session goes straight to the dashboard with navigation',
        (tester) async {
      bigScreen(tester);
      final auth = await authWith(FakeAuthService(restoreUser: fakeUser()));
      await tester.pumpWidget(routerApp(auth));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Loading your eco data...'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);

      await tester.tap(find.text('Tasks'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Activities'), findsOneWidget);
    });

    testWidgets('logout returns to the login screen', (tester) async {
      bigScreen(tester);
      final service = FakeAuthService(restoreUser: fakeUser());
      final auth = await authWith(service);
      await tester.pumpWidget(routerApp(auth));
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('account-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Jane Doe'), findsOneWidget);
      await tester.tap(find.byKey(const Key('logout')));
      await tester.pump(const Duration(milliseconds: 800));
      expect(service.loggedOut, isTrue);
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });
}
