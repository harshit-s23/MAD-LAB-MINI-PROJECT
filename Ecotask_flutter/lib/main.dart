import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'database/database_helper.dart';
import 'database/platform_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  final prefs = await SharedPreferences.getInstance();
  final factory = await desktopDatabaseFactory();
  runApp(
    EcoTaskApp(
      deps: AppDependencies.create(
        prefs: prefs,
        database: DatabaseHelper(factory: factory),
      ),
    ),
  );
}
