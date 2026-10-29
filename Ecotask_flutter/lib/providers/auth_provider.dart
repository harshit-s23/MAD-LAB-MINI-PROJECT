import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/app_user.dart';
import '../repositories/seed_repository.dart';
import '../services/auth_service.dart';
import 'op_result.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

/// Replaces `AuthContext.jsx`: current user, login / register / logout and
/// session restoration (the router listens to this to guard routes).
class AuthProvider extends ChangeNotifier {
  AuthProvider(
      {required AuthService authService, required SeedRepository seeder})
      : _auth = authService,
        _seeder = seeder;

  final AuthService _auth;
  final SeedRepository _seeder;

  AuthStatus _status = AuthStatus.initializing;
  AppUser? _user;
  bool _loading = false;
  bool _disposed = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Called once at start-up (splash screen): makes sure the demo account
  /// exists, then restores the persisted session if there is a valid one.
  Future<void> bootstrap() async {
    try {
      await _seeder.ensureDemoUser();
    } catch (_) {
      // The demo account is a convenience; never block start-up on it.
    }
    try {
      _user = await _auth.restoreSession();
    } catch (_) {
      _user = null;
    }
    _status =
        _user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    _notify();
  }

  Future<OpResult> login(String email, String password) async {
    _loading = true;
    _notify();
    try {
      _user = await _auth.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      return const OpResult.ok();
    } on AppException catch (e) {
      return OpResult.fail(e.message);
    } catch (_) {
      return const OpResult.fail('Login failed');
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<OpResult> register(String name, String email, String password) async {
    _loading = true;
    _notify();
    try {
      _user =
          await _auth.register(name: name, email: email, password: password);
      _status = AuthStatus.authenticated;
      return const OpResult.ok();
    } on AppException catch (e) {
      return OpResult.fail(e.message);
    } catch (_) {
      return const OpResult.fail('Registration failed');
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } catch (_) {
      // Even if clearing storage fails, drop the in-memory session.
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    _notify();
  }

  /// Reloads the user row (score, level, streak, badges changed by a task
  /// mutation).
  Future<void> refreshUser() async {
    final current = _user;
    if (current == null) return;
    try {
      final fresh = await _auth.currentUser(current.id);
      if (fresh != null) {
        _user = fresh;
        _notify();
      }
    } catch (_) {
      // Keep showing the last known values.
    }
  }
}
