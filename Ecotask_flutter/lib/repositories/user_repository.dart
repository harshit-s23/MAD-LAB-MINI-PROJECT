import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/app_date.dart';
import '../core/app_exception.dart';
import '../database/database_helper.dart';
import '../database/schema.dart';
import '../models/app_user.dart';
import '../models/badge.dart';
import 'repository_guard.dart';

/// Access to the `users` table.
class UserRepository {
  UserRepository(this._helper);

  final DatabaseHelper _helper;
  static const Uuid _uuid = Uuid();

  /// Creates a user with the model defaults of the original `User` model:
  /// `totalEcoScore = 100`, `streak = 0`, `lastActiveDate = today`,
  /// `badges = []`, `level = 'Seedling'`.
  Future<AppUser> create({
    required String name,
    required String email,
    required String passwordHash,
  }) {
    final now = AppDate.now().toUtc();
    final user = AppUser(
      id: _uuid.v4(),
      name: name,
      email: email,
      totalEcoScore: 100,
      streak: 0,
      lastActiveDate: AppDate.today(),
      badges: const <EarnedBadge>[],
      level: 'Seedling',
      createdAt: now,
      updatedAt: now,
    );
    return insert(user, passwordHash);
  }

  /// Inserts a fully specified user (used by registration and the demo seeder).
  Future<AppUser> insert(AppUser user, String passwordHash) =>
      guardDb(() async {
        final db = await _helper.database;
        try {
          await db.insert(
            Schema.usersTable,
            {...user.toMap(), 'password': passwordHash},
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        } on DatabaseException catch (e) {
          if (e.isUniqueConstraintError()) {
            throw const AppException('Email already registered');
          }
          rethrow;
        }
        return user;
      });

  Future<AppUser?> findById(String id) => guardDb(() async {
        final db = await _helper.database;
        return findByIdOn(db, id);
      });

  /// Same as [findById] but runs on an existing executor (transaction).
  Future<AppUser?> findByIdOn(DatabaseExecutor ex, String id) async {
    final rows = await ex.query(Schema.usersTable,
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  /// Exact-match lookup (e-mails are normalised before they get here).
  Future<UserCredentials?> findCredentialsByEmail(String email) =>
      guardDb(() async {
        final db = await _helper.database;
        final rows = await db.query(Schema.usersTable,
            where: 'email = ?', whereArgs: [email], limit: 1);
        if (rows.isEmpty) return null;
        return UserCredentials(
          user: AppUser.fromMap(rows.first),
          passwordHash: rows.first['password']! as String,
        );
      });

  Future<bool> emailExists(String email) => guardDb(() async {
        final db = await _helper.database;
        final rows = await db.query(Schema.usersTable,
            columns: ['id'], where: 'email = ?', whereArgs: [email], limit: 1);
        return rows.isNotEmpty;
      });

  Future<int> count() => guardDb(() async {
        final db = await _helper.database;
        return Sqflite.firstIntValue(await db
                .rawQuery('SELECT COUNT(*) FROM ${Schema.usersTable}')) ??
            0;
      });
}
