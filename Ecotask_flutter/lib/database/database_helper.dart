import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/app_exception.dart';
import 'schema.dart';

/// Owns the single SQLite connection: opening, creating tables/indexes,
/// versioned migrations and closing.
///
/// Repositories obtain the connection through [database]; UI code never talks
/// to SQLite directly.
class DatabaseHelper {
  /// [factory] and [path] exist so tests can inject an in-memory FFI database;
  /// production code uses the defaults.
  DatabaseHelper({DatabaseFactory? factory, String? path})
      : _factory = factory,
        _path = path;

  final DatabaseFactory? _factory;
  final String? _path;

  Database? _db;
  Future<Database>? _opening;

  /// Lazily opens the database (safe to await from many callers at once).
  Future<Database> get database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final factory = _factory ?? databaseFactory;
      final path =
          _path ?? p.join(await factory.getDatabasesPath(), Schema.fileName);
      final db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: Schema.version,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
      _db = db;
      return db;
    } on DatabaseException {
      throw const AppException('Could not open the local database.');
    } finally {
      // Allow a retry if opening failed; harmless when it succeeded.
      _opening = null;
    }
  }

  Future<void> _onConfigure(Database db) async {
    // SQLite ignores foreign keys unless this is enabled per connection.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final statement in Schema.createStatements) {
      batch.execute(statement);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Apply each pending migration in order, atomically.
    await db.transaction((txn) async {
      for (var v = oldVersion + 1; v <= newVersion; v++) {
        for (final statement in Schema.migrations[v] ?? const <String>[]) {
          await txn.execute(statement);
        }
      }
    });
  }

  /// Runs [action] in a transaction.
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    _opening = null;
    if (db != null && db.isOpen) await db.close();
  }
}
