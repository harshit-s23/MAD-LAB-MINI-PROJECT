import 'dart:io';

import 'package:ecotask/database/database_helper.dart';
import 'package:ecotask/database/schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_env.dart';

void main() {
  late TestEnv env;

  setUpAll(sqfliteFfiInit);
  setUp(() async => env = await TestEnv.create());
  tearDown(() => env.dispose());

  Future<void> insertUser(String id, String email) async {
    final db = await env.helper.database;
    await db.insert('users', {
      'id': id,
      'name': 'N',
      'email': email,
      'password': 'h',
      'createdAt': 't',
      'updatedAt': 't',
    });
  }

  test('creates users, tasks and carbon_logs tables', () async {
    final db = await env.helper.database;
    final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
    expect(
        rows.map((r) => r['name']).toSet(), {'users', 'tasks', 'carbon_logs'});
  });

  test('creates the performance indexes', () async {
    final db = await env.helper.database;
    final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'");
    expect(rows.map((r) => r['name']).toSet(), {
      'idx_tasks_user_date',
      'idx_tasks_user_category',
      'idx_logs_user_date',
      'idx_logs_task'
    });
  });

  test('foreign keys are enforced', () async {
    final db = await env.helper.database;
    expect(((await db.rawQuery('PRAGMA foreign_keys')).first.values.first), 1);
    expect(
      () => db.insert('tasks', {
        'id': 't',
        'userId': 'ghost',
        'title': 'x',
        'category': 'food',
        'carbonValue': 1,
        'date': '2026-01-01',
        'createdAt': 't',
        'updatedAt': 't',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('e-mail is unique', () async {
    await insertUser('1', 'a@b.com');
    expect(() => insertUser('2', 'a@b.com'), throwsA(isA<DatabaseException>()));
  });

  test('category CHECK constraint rejects unknown categories', () async {
    await insertUser('1', 'a@b.com');
    final db = await env.helper.database;
    expect(
      () => db.insert('tasks', {
        'id': 't',
        'userId': '1',
        'title': 'x',
        'category': 'bogus',
        'carbonValue': 1,
        'date': '2026-01-01',
        'createdAt': 't',
        'updatedAt': 't',
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('deleting a user cascades; deleting a task detaches its log', () async {
    await insertUser('1', 'a@b.com');
    final db = await env.helper.database;
    await db.insert('tasks', {
      'id': 't',
      'userId': '1',
      'title': 'x',
      'category': 'food',
      'carbonValue': 1,
      'date': '2026-01-01',
      'createdAt': 't',
      'updatedAt': 't'
    });
    await db.insert('carbon_logs', {
      'id': 'l',
      'userId': '1',
      'taskId': 't',
      'date': '2026-01-01',
      'category': 'food',
      'carbonAmount': 1,
      'createdAt': 't',
      'updatedAt': 't'
    });
    await db.delete('tasks', where: 'id = ?', whereArgs: ['t']);
    expect((await db.query('carbon_logs')).single['taskId'], isNull);
    await db.delete('users', where: 'id = ?', whereArgs: ['1']);
    expect(await db.query('carbon_logs'), isEmpty);
  });

  test('data persists when the database is reopened', () async {
    final dir = await Directory.systemTemp.createTemp('ecotask_db');
    final path = '${dir.path}/test.db';
    final a = DatabaseHelper(factory: databaseFactoryFfi, path: path);
    await (await a.database).insert('users', {
      'id': '1',
      'name': 'N',
      'email': 'p@x.com',
      'password': 'h',
      'createdAt': 't',
      'updatedAt': 't'
    });
    await a.close();
    final b = DatabaseHelper(factory: databaseFactoryFfi, path: path);
    expect(
        (await (await b.database).query('users')).single['email'], 'p@x.com');
    expect((await (await b.database).getVersion()), Schema.version);
    await b.close();
    await dir.delete(recursive: true);
  });

  test('close can be called repeatedly and the database re-opens', () async {
    await env.helper.close();
    await env.helper.close();
    final db = await env.helper.database;
    expect(db.isOpen, isTrue);
  });
}
