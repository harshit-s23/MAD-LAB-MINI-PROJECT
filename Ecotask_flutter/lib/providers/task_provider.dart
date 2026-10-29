import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/task.dart';
import '../models/task_input.dart';
import '../repositories/task_repository.dart';
import 'auth_provider.dart';
import 'op_result.dart';

/// Replaces the state in `TasksPage.jsx`: the task list, server-side filters
/// (category, date), client-side title search and the summary totals.
class TaskProvider extends ChangeNotifier {
  TaskProvider({required TaskRepository repository, required AuthProvider auth})
      : _repo = repository,
        _auth = auth {
    _userId = auth.user?.id;
    _auth.addListener(_onAuthChanged);
  }

  final TaskRepository _repo;
  final AuthProvider _auth;

  String? _userId;
  List<Task> _tasks = const [];
  bool _loading = false;
  String? _error;
  String _category = '';
  String _date = '';
  String _search = '';
  int _loadSeq = 0;
  bool _disposed = false;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  String? get error => _error;
  String get category => _category;
  String get date => _date;
  String get search => _search;
  bool get hasActiveFilters =>
      _category.isNotEmpty || _date.isNotEmpty || _search.isNotEmpty;

  /// Tasks after the client-side title search (`toLowerCase().includes`).
  List<Task> get filtered {
    if (_search.isEmpty) return _tasks;
    final q = _search.toLowerCase();
    return _tasks
        .where((t) => t.title.toLowerCase().contains(q))
        .toList(growable: false);
  }

  /// Sum of positive carbon values of the visible tasks.
  double get totalEmissions =>
      filtered.fold(0.0, (s, t) => s + (t.carbonValue > 0 ? t.carbonValue : 0));

  /// Absolute value of the sum of negative carbon values.
  double get totalSaved => filtered
      .fold(0.0, (s, t) => s + (t.carbonValue < 0 ? t.carbonValue : 0))
      .abs();

  double get netCarbon => filtered.fold(0.0, (s, t) => s + t.carbonValue);

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Reset everything when another user logs in or the user logs out.
  void _onAuthChanged() {
    final id = _auth.user?.id;
    if (id == _userId) return;
    _userId = id;
    _loadSeq++;
    _tasks = const [];
    _error = null;
    _category = '';
    _date = '';
    _search = '';
    _loading = false;
    _notify();
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    final seq = ++_loadSeq;
    _loading = true;
    _error = null;
    _notify();
    try {
      final result = await _repo.getTasks(
        userId,
        category: _category.isEmpty ? null : _category,
        date: _date.isEmpty ? null : _date,
      );
      if (seq != _loadSeq) return; // a newer request superseded this one
      _tasks = result;
    } on AppException catch (e) {
      if (seq != _loadSeq) return;
      _error = e.message;
    } catch (_) {
      if (seq != _loadSeq) return;
      _error = 'Failed to load tasks';
    } finally {
      if (seq == _loadSeq) {
        _loading = false;
        _notify();
      }
    }
  }

  Future<void> setCategory(String value) {
    _category = value;
    return load();
  }

  Future<void> setDate(String value) {
    _date = value;
    return load();
  }

  void setSearch(String value) {
    _search = value;
    _notify();
  }

  Future<void> clearFilters() {
    _category = '';
    _date = '';
    _search = '';
    return load();
  }

  /// Creates ([editingId] == null) or updates a task.
  Future<OpResult> save(TaskInput input, {String? editingId}) async {
    final userId = _userId;
    if (userId == null) return const OpResult.fail('Please sign in again.');
    try {
      if (editingId == null) {
        await _repo.createTask(userId, input);
      } else {
        await _repo.updateTask(
          userId,
          editingId,
          TaskUpdate(
            title: input.title,
            description: input.description,
            category: input.category,
            subcategory: input.subcategory,
            quantity: input.quantity,
            unit: input.unit,
            date: input.date,
          ),
        );
      }
      await _auth.refreshUser();
      await load();
      return OpResult.ok(
          editingId == null ? 'Activity logged! 🌱' : 'Activity updated 🌿');
    } on AppException catch (e) {
      return OpResult.fail(e.message);
    } catch (_) {
      return const OpResult.fail('Failed to save');
    }
  }

  Future<OpResult> delete(String id) async {
    final userId = _userId;
    if (userId == null) return const OpResult.fail('Please sign in again.');
    try {
      await _repo.deleteTask(userId, id);
      await _auth.refreshUser();
      await load();
      return const OpResult.ok('Deleted');
    } on AppException catch (e) {
      return OpResult.fail(e.message);
    } catch (_) {
      return const OpResult.fail('Failed to delete');
    }
  }

  /// Toggle the completed flag. The completed flag does not change carbon
  /// numbers, but (as in the original) it still re-runs the user stats.
  Future<OpResult> toggle(Task task) async {
    final userId = _userId;
    if (userId == null) return const OpResult.fail('Please sign in again.');
    try {
      await _repo.updateTask(
          userId, task.id, TaskUpdate(completed: !task.completed));
      await _auth.refreshUser();
      await load();
      return const OpResult.ok();
    } on AppException catch (e) {
      return OpResult.fail(e.message);
    } catch (_) {
      return const OpResult.fail('Failed to update task');
    }
  }
}
