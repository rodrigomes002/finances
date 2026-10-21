import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Future<Database>? _database;

  Future<Database> get database => _database ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();

    return openDatabase(
      join(databasesPath, 'finances.db'),
      version: 2,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            amount REAL NOT NULL CHECK (amount > 0),
            type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
            category TEXT NOT NULL,
            occurred_at TEXT NOT NULL,
            import_key TEXT UNIQUE
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE transactions ADD COLUMN import_key TEXT',
          );
          await database.execute(
            'CREATE UNIQUE INDEX transactions_import_key '
            'ON transactions (import_key)',
          );
        }
      },
    );
  }
}
