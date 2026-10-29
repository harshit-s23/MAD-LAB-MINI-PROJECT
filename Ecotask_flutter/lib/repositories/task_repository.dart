import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/app_date.dart';
import '../core/app_exception.dart';
import '../core/validators.dart';
import '../database/database_helper.dart';
import '../database/schema.dart';
import '../models/task.dart';
import '../models/task_input.dart';
import '../models/user_stats.dart';
import '../services/carbon_engine.dart';
import 'repository_guard.dart';
import 'stats_repository.dart';

/// Result of a task mutation: the stored task plus the refreshed user stats.
class TaskMutation {
  const TaskMutation(this.task, this.stats);

  final Task task;
  final UserStats stats;
}

/// Port of taskController.js (tasks + their carbon logs).
class TaskRepository {
  TaskRepository(this._helper, this._stats);

  final DatabaseHelper _helper;
  final StatsRepository _stats;
  static const Uuid _uuid = Uuid();

  static const String _order = 'date DESC, createdAt DESC, rowid DESC';

  /// `GET /tasks`: optional `date`, `category`, and `startDate`+`endDate`
  /// filters (a complete range overrides `date`, as in the original).
  Future<List<Task>> getTasks(
    String userId, {
    String? date,
    String? category,
    String? startDate,
    String? endDate,
  }) =>
      guardDb(() async {
        final db = await _helper.database;
        final where = StringBuffer('userId = ?');
        final args = <Object?>[userId];

        final hasRange =
            (startDate?.isNotEmpty ?? false) && (endDate?.isNotEmpty ?? false);
        if (hasRange) {
          where.write(' AND date BETWEEN ? AND ?');
          args
            ..add(startDate)
            ..add(endDate);
        } else if (date != null && date.isNotEmpty) {
          where.write(' AND date = ?');
          args.add(date);
        }
        if (category != null && category.isNotEmpty) {
          where.write(' AND category = ?');
          args.add(category);
        }

        final rows = await db.query(
          Schema.tasksTable,
          where: where.toString(),
          whereArgs: args,
          orderBy: _order,
        );
        return rows.map(Task.fromMap).toList(growable: false);
      });

  Future<Task?> findById(String userId, String id) => guardDb(() async {
        final db = await _helper.database;
        return _find(db, userId, id);
      });

  Future<Task?> _find(DatabaseExecutor ex, String userId, String id) async {
    final rows = await ex.query(
      Schema.tasksTable,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : Task.fromMap(rows.first);
  }

  /// `POST /tasks`: stores the task, its carbon log and refreshes user stats
  /// in a single transaction.
  Future<TaskMutation> createTask(String userId, TaskInput input,
          {DateTime? now}) =>
      guardDb(() async {
        final title = input.title.trim();
        _validate(
            title: title,
            category: input.category,
            date: input.date,
            quantity: input.quantity);

        final stamp = (now ?? AppDate.now()).toUtc();
        final quantity = input.quantity;
        final carbonValue = CarbonEngine.calculateCarbonValue(
            input.category, input.subcategory, quantity);

        final task = Task(
          id: _uuid.v4(),
          userId: userId,
          title: title,
          description: input.description,
          category: input.category,
          subcategory: input.subcategory,
          carbonValue: carbonValue,
          quantity: quantity,
          unit: input.unit.isEmpty ? 'unit' : input.unit,
          date: input.date,
          completed: false,
          isRecurring: input.isRecurring,
          createdAt: stamp,
          updatedAt: stamp,
        );

        return _helper.transaction((txn) async {
          await txn.insert(Schema.tasksTable, task.toMap());
          await txn.insert(Schema.carbonLogsTable, {
            'id': _uuid.v4(),
            'userId': userId,
            'taskId': task.id,
            'date': task.date,
            'category': task.category,
            'carbonAmount': carbonValue,
            'description': title,
            'createdAt': stamp.toIso8601String(),
            'updatedAt': stamp.toIso8601String(),
          });
          final stats = await _stats.refreshUserStats(txn, userId, now: now);
          return TaskMutation(task, stats);
        });
      });

  /// `PUT /tasks/:id`. Field fallbacks reproduce the original `||` / `!==
  /// undefined` rules (an empty title/category/unit/date keeps the old value,
  /// description/subcategory/completed accept empty or false).
  Future<TaskMutation> updateTask(
    String userId,
    String taskId,
    TaskUpdate u, {
    DateTime? now,
  }) =>
      guardDb(() async {
        return _helper.transaction((txn) async {
          final old = await _find(txn, userId, taskId);
          if (old == null) throw const AppException('Task not found');

          String orOld(String? v, String o) => (v == null || v.isEmpty) ? o : v;

          final category = orOld(u.category, old.category);
          final quantity = (u.quantity == null || u.quantity == 0)
              ? old.quantity
              : u.quantity!;
          // Carbon is recalculated with `subcategory || task.subcategory`.
          final carbonValue = CarbonEngine.calculateCarbonValue(
            category,
            orOld(u.subcategory, old.subcategory),
            quantity,
          );

          final title = orOld(u.title, old.title).trim();
          final date = orOld(u.date, old.date);
          _validate(
              title: title, category: category, date: date, quantity: quantity);

          final stamp = (now ?? AppDate.now()).toUtc();
          final updated = Task(
            id: old.id,
            userId: old.userId,
            title: title,
            description: u.description ?? old.description,
            category: category,
            subcategory: u.subcategory ?? old.subcategory,
            carbonValue: carbonValue,
            quantity: quantity,
            unit: orOld(u.unit, old.unit),
            date: date,
            completed: u.completed ?? old.completed,
            // The original update endpoint ignores `isRecurring`.
            isRecurring: old.isRecurring,
            createdAt: old.createdAt,
            updatedAt: stamp,
          );

          await txn.update(
            Schema.tasksTable,
            {
              'title': updated.title,
              'description': updated.description,
              'category': updated.category,
              'subcategory': updated.subcategory,
              'carbonValue': updated.carbonValue,
              'quantity': updated.quantity,
              'unit': updated.unit,
              'date': updated.date,
              'completed': updated.completed ? 1 : 0,
              'updatedAt': stamp.toIso8601String(),
            },
            where: 'id = ? AND userId = ?',
            whereArgs: [taskId, userId],
          );

          // Keep the carbon log in sync (amount, category, date).
          await txn.update(
            Schema.carbonLogsTable,
            {
              'carbonAmount': carbonValue,
              'category': updated.category,
              'date': updated.date,
              'updatedAt': stamp.toIso8601String(),
            },
            where: 'taskId = ?',
            whereArgs: [taskId],
          );

          final stats = await _stats.refreshUserStats(txn, userId, now: now);
          return TaskMutation(updated, stats);
        });
      });

  /// `DELETE /tasks/:id`: removes the logs and the task, then refreshes stats.
  Future<UserStats> deleteTask(String userId, String taskId, {DateTime? now}) =>
      guardDb(() async {
        return _helper.transaction((txn) async {
          final task = await _find(txn, userId, taskId);
          if (task == null) throw const AppException('Task not found');
          await txn.delete(Schema.carbonLogsTable,
              where: 'taskId = ?', whereArgs: [taskId]);
          await txn
              .delete(Schema.tasksTable, where: 'id = ?', whereArgs: [taskId]);
          return _stats.refreshUserStats(txn, userId, now: now);
        });
      });

  void _validate({
    required String title,
    required String category,
    required String date,
    required double quantity,
  }) {
    final error = Validators.taskTitle(title) ??
        Validators.category(category) ??
        Validators.date(date) ??
        (quantity.isFinite && quantity >= Validators.minQuantity
            ? null
            : 'Quantity must be at least ${Validators.minQuantity}');
    if (error != null) throw AppException(error);
  }
}
