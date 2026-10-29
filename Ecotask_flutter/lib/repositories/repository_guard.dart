import 'package:sqflite/sqflite.dart';

import '../core/app_exception.dart';

/// Converts low-level database failures into user-presentable
/// [AppException]s so raw SQL errors / stack traces never reach the UI.
Future<T> guardDb<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } on DatabaseException catch (e) {
    if (e.isUniqueConstraintError()) {
      throw const AppException('This record already exists.');
    }
    throw const AppException('A database error occurred. Please try again.');
  }
}
