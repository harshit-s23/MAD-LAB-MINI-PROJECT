import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Picks the SQLite implementation for the current platform.
///
/// * Android / iOS: the normal `sqflite` plugin (returns null = use default).
/// * Windows / Linux / macOS: `sqflite_common_ffi`, with the database stored in
///   the user's application-data folder (so it does not depend on the working
///   directory).
Future<DatabaseFactory?> desktopDatabaseFactory() async {
  if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS))
    return null;

  sqfliteFfiInit();
  final env = Platform.environment;
  final String base;
  if (Platform.isWindows) {
    base = env['APPDATA'] ?? env['USERPROFILE'] ?? Directory.current.path;
  } else if (Platform.isMacOS) {
    base = p.join(env['HOME'] ?? Directory.current.path, 'Library',
        'Application Support');
  } else {
    base = env['XDG_DATA_HOME'] ??
        p.join(env['HOME'] ?? Directory.current.path, '.local', 'share');
  }
  final dir = Directory(p.join(base, 'EcoTask'));
  await dir.create(recursive: true);
  databaseFactoryFfi.setDatabasesPath(dir.path);
  return databaseFactoryFfi;
}
