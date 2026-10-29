/// SQLite schema, equivalent to what Sequelize `sync()` generated for the
/// original `User`, `Task` and `CarbonLog` models (camelCase column names are
/// kept so the data model is 1:1 with the web app).
class Schema {
  Schema._();

  static const String fileName = 'ecotask.db';

  /// Bump when adding an entry to [migrations].
  static const int version = 1;

  static const String usersTable = 'users';
  static const String tasksTable = 'tasks';
  static const String carbonLogsTable = 'carbon_logs';

  static const String _categoryCheck =
      "'transport','food','energy','shopping','waste','water','other'";

  static const List<String> createStatements = [
    '''
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  totalEcoScore REAL NOT NULL DEFAULT 100,
  streak INTEGER NOT NULL DEFAULT 0,
  lastActiveDate TEXT,
  badges TEXT NOT NULL DEFAULT '[]',
  level TEXT NOT NULL DEFAULT 'Seedling',
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)''',
    '''
CREATE TABLE tasks (
  id TEXT PRIMARY KEY NOT NULL,
  userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
  title TEXT NOT NULL CHECK (length(title) BETWEEN 1 AND 200),
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL CHECK (category IN ($_categoryCheck)),
  subcategory TEXT NOT NULL DEFAULT '',
  carbonValue REAL NOT NULL,
  quantity REAL NOT NULL DEFAULT 1,
  unit TEXT NOT NULL DEFAULT 'unit',
  date TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  isRecurring INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)''',
    '''
CREATE TABLE carbon_logs (
  id TEXT PRIMARY KEY NOT NULL,
  userId TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
  taskId TEXT REFERENCES tasks(id) ON DELETE SET NULL ON UPDATE CASCADE,
  date TEXT NOT NULL,
  category TEXT NOT NULL,
  carbonAmount REAL NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)''',
    'CREATE INDEX idx_tasks_user_date ON tasks(userId, date DESC, createdAt DESC)',
    'CREATE INDEX idx_tasks_user_category ON tasks(userId, category)',
    'CREATE INDEX idx_logs_user_date ON carbon_logs(userId, date)',
    'CREATE INDEX idx_logs_task ON carbon_logs(taskId)',
  ];

  /// Upgrade scripts keyed by the version they migrate *to*.
  /// Example for a future version 2:
  /// `2: ['ALTER TABLE tasks ADD COLUMN notes TEXT']`
  static const Map<int, List<String>> migrations = {};
}
