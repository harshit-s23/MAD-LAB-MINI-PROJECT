import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_dependencies.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/task_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/app_toast.dart';

/// Root widget: providers + router + theme.
class EcoTaskApp extends StatefulWidget {
  const EcoTaskApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<EcoTaskApp> createState() => _EcoTaskAppState();
}

class _EcoTaskAppState extends State<EcoTaskApp> {
  late final AuthProvider _auth =
      AuthProvider(authService: widget.deps.auth, seeder: widget.deps.seed);
  late final GoRouter _router = createRouter(_auth);

  @override
  void initState() {
    super.initState();
    _auth.bootstrap();
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<TaskProvider>(
          create: (_) =>
              TaskProvider(repository: widget.deps.tasks, auth: _auth),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) =>
              DashboardProvider(repository: widget.deps.dashboard, auth: _auth),
        ),
      ],
      child: MaterialApp.router(
        title: 'EcoTask 🌱',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scaffoldMessengerKey: AppToast.messengerKey,
        routerConfig: _router,
      ),
    );
  }
}
