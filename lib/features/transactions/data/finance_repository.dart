import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/finance_transaction.dart';

abstract interface class FinanceRepository implements Listenable {
  @override
  void addListener(VoidCallback listener);

  @override
  void removeListener(VoidCallback listener);

  Future<int> importTransactions(List<FinanceTransaction> transactions);
  Future<FinanceOverview> loadOverview({DateTime? now, DateTime? month});
  Future<List<FinanceTransaction>> loadRecentTransactions({int limit = 10});
  Future<List<FinanceTransaction>> loadExpensesForMonth(DateTime month);
}

class SqliteFinanceRepository extends ChangeNotifier
    implements FinanceRepository {
  SqliteFinanceRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  @override
  Future<int> importTransactions(List<FinanceTransaction> transactions) async {
    if (transactions.isEmpty) return 0;

    final database = await _appDatabase.database;
    final importedCount = await database.transaction((transaction) async {
      var count = 0;
      for (final item in transactions) {
        final id = await transaction.insert('transactions', {
          'description': item.description,
          'amount': item.amount,
          'type': item.type.databaseValue,
          'category': item.category,
          'occurred_at': item.occurredAt.toIso8601String(),
          'import_key': item.importKey,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        if (id != 0) count++;
      }
      return count;
    });

    if (importedCount > 0) notifyListeners();
    return importedCount;
  }

  @override
  Future<FinanceOverview> loadOverview({
    DateTime? now,
    DateTime? month,
  }) async {
    final database = await _appDatabase.database;
    final selectedMonth = month ?? now ?? DateTime.now();
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month);
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    final monthlyTotals = await database.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0) AS balance,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS expenses
      FROM transactions
      WHERE occurred_at >= ? AND occurred_at < ?
      ''',
      [monthStart.toIso8601String(), nextMonth.toIso8601String()],
    );

    return FinanceOverview(
      balance: (monthlyTotals.first['balance']! as num).toDouble(),
      monthlyIncome: (monthlyTotals.first['income']! as num).toDouble(),
      monthlyExpenses: (monthlyTotals.first['expenses']! as num).toDouble(),
    );
  }

  @override
  Future<List<FinanceTransaction>> loadRecentTransactions({
    int limit = 10,
  }) async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'transactions',
      orderBy: 'occurred_at DESC, id DESC',
      limit: limit,
    );
    return rows.map(FinanceTransaction.fromMap).toList(growable: false);
  }

  @override
  Future<List<FinanceTransaction>> loadExpensesForMonth(DateTime month) async {
    final database = await _appDatabase.database;
    final monthStart = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    final rows = await database.query(
      'transactions',
      where: "type = 'expense' AND occurred_at >= ? AND occurred_at < ?",
      whereArgs: [monthStart.toIso8601String(), nextMonth.toIso8601String()],
      orderBy: 'occurred_at DESC, id DESC',
    );
    return rows.map(FinanceTransaction.fromMap).toList(growable: false);
  }
}
