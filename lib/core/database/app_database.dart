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
      version: 4,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            amount REAL NOT NULL CHECK (amount > 0),
            type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
            category TEXT NOT NULL,
            occurred_at TEXT NOT NULL,
            import_key TEXT UNIQUE,
            is_fixed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await _createFixedTransactionTables(database);
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
        if (oldVersion < 3) {
          await database.execute(
            'ALTER TABLE transactions ADD COLUMN '
            'is_fixed INTEGER NOT NULL DEFAULT 0',
          );
          await _createLegacyFixedExpenseTables(database);
        }
        if (oldVersion < 4) {
          await _createFixedTransactionTables(database);
          await database.execute('''
            INSERT INTO fixed_transactions (
              id, description, amount, category, started_at, type
            )
            SELECT id, description, amount, category, started_at, 'expense'
            FROM fixed_expenses
            ''');
          await database.execute('''
            INSERT INTO fixed_transaction_monthly_values (
              fixed_transaction_id, month, amount
            )
            SELECT fixed_expense_id, month, amount
            FROM fixed_expense_monthly_values
            ''');
          await database.execute('DROP TABLE fixed_expense_monthly_values');
          await database.execute('DROP TABLE fixed_expenses');
        }
      },
    );
  }

  Future<void> _createFixedTransactionTables(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE fixed_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL CHECK (amount > 0),
        category TEXT NOT NULL,
        started_at TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense'))
      )
    ''');
    await database.execute('''
      CREATE TABLE fixed_transaction_monthly_values (
        fixed_transaction_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        amount REAL NOT NULL CHECK (amount > 0),
        PRIMARY KEY (fixed_transaction_id, month),
        FOREIGN KEY (fixed_transaction_id) REFERENCES fixed_transactions (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createLegacyFixedExpenseTables(
    DatabaseExecutor database,
  ) async {
    await database.execute('''
      CREATE TABLE fixed_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL CHECK (amount > 0),
        category TEXT NOT NULL,
        started_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE fixed_expense_monthly_values (
        fixed_expense_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        amount REAL NOT NULL CHECK (amount > 0),
        PRIMARY KEY (fixed_expense_id, month),
        FOREIGN KEY (fixed_expense_id) REFERENCES fixed_expenses (id)
          ON DELETE CASCADE
      )
    ''');
  }
}
