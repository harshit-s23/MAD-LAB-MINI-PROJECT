import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';
import 'auth_provider.dart';

/// Replaces the fetch/state logic of `DashboardPage.jsx`.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(
      {required DashboardRepository repository, required AuthProvider auth})
      : _repo = repository,
        _auth = auth {
    _userId = auth.user?.id;
    _auth.addListener(_onAuthChanged);
  }

  final DashboardRepository _repo;
  final AuthProvider _auth;

  String? _userId;
  DashboardData? _data;
  bool _loading = false;
  String? _error;
  int _seq = 0;
  bool _disposed = false;

  DashboardData? get data => _data;

  /// True only for the very first load (no data to show yet); refreshes keep
  /// the previous numbers on screen.
  bool get loading => _loading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onAuthChanged() {
    final id = _auth.user?.id;
    if (id == _userId) return;
    _userId = id;
    _seq++;
    _data = null;
    _error = null;
    _loading = false;
    _notify();
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    final seq = ++_seq;
    _loading = true;
    _error = null;
    _notify();
    try {
      final result = await _repo.getDashboard(userId);
      if (seq != _seq) return;
      _data = result;
    } on AppException catch (e) {
      if (seq != _seq) return;
      _error = e.message;
    } catch (_) {
      if (seq != _seq) return;
      _error = 'Failed to load dashboard';
    } finally {
      if (seq == _seq) {
        _loading = false;
        _notify();
      }
    }
  }
}
