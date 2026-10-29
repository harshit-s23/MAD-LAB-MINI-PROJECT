import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tasks_screen.dart';
import '../widgets/app_shell.dart';

/// Route table mirroring App.jsx:
///   /            -> /dashboard
///   /login, /register  (guest only)
///   /dashboard, /tasks (protected, inside the shell)
/// plus /splash while the saved session is restored.
GoRouter createRouter(AuthProvider auth) {
  const guestPaths = {'/login', '/register'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.matchedLocation;

      if (auth.status == AuthStatus.initializing) {
        return path == '/splash' ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return guestPaths.contains(path) ? null : '/login';
      }
      if (path == '/splash' || path == '/' || guestPaths.contains(path)) {
        return '/dashboard';
      }
      return null;
    },
    errorBuilder: (context, state) => const SplashScreen(),
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
      GoRoute(
          path: '/splash',
          pageBuilder: (c, s) => _fade(s, const SplashScreen())),
      GoRoute(
          path: '/login', pageBuilder: (c, s) => _fade(s, const LoginScreen())),
      GoRoute(
          path: '/register',
          pageBuilder: (c, s) => _fade(s, const RegisterScreen())),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
              path: '/dashboard',
              pageBuilder: (c, s) => _fade(s, const DashboardScreen())),
          GoRoute(
              path: '/tasks',
              pageBuilder: (c, s) => _fade(s, const TasksScreen())),
        ],
      ),
    ],
  );
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
    );
