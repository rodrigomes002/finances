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
  Future<void> addTransaction(FinanceTransaction transaction);
  Future<void> updateExpenseAmount({
    required FinanceTransaction transaction,
    required double amount,
    required DateTime month,
  });
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
  Future<void> addTransaction(FinanceTransaction transaction) async {
    if (transaction.description.trim().isEmpty) {
      throw ArgumentError.value(
        transaction.description,
        'description',
        'A descrição é obrigatória.',
      );
    }
    if (!transaction.amount.isFinite || transaction.amount <= 0) {
      throw ArgumentError.value(
        transaction.amount,
        'amount',
        'O valor deve ser maior que zero.',
      );
    }
    if (transaction.category.trim().isEmpty) {
      throw ArgumentError.value(
        transaction.category,
        'category',
        'A categoria é obrigatória.',
      );
    }
    if (transaction.isFixed &&
        transaction.type != FinanceTransactionType.expense) {
      throw ArgumentError.value(
        transaction.type,
        'type',
        'Despesas fixas devem ser lançamentos de despesa.',
      );
    }

    final database = await _appDatabase.database;
    if (transaction.isFixed) {
      await database.insert('fixed_expenses', {
        'description': transaction.description.trim(),
        'amount': transaction.amount,
        'category': transaction.category,
        'started_at': DateTime(
          transaction.occurredAt.year,
          transaction.occurredAt.month,
        ).toIso8601String(),
      });
    } else {
      await database.insert('transactions', {
        'description': transaction.description.trim(),
        'amount': transaction.amount,
        'type': transaction.type.databaseValue,
        'category': transaction.category,
        'occurred_at': transaction.occurredAt.toIso8601String(),
        'import_key': null,
      });
    }
    notifyListeners();
  }

  @override
  Future<void> updateExpenseAmount({
    required FinanceTransaction transaction,
    required double amount,
    required DateTime month,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'O valor deve ser maior que zero.',
      );
    }
    if (transaction.id == null) {
      throw ArgumentError('O lançamento não possui identificador.');
    }

    final database = await _appDatabase.database;
    if (transaction.isFixed) {
      final selectedMonth = DateTime(month.year, month.month);
      final batch = database.batch();
      batch.insert('fixed_expense_monthly_values', {
        'fixed_expense_id': transaction.id,
        'month': _monthKey(selectedMonth),
        'amount': amount,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    } else {
      final updatedRows = await database.update(
        'transactions',
        {'amount': amount},
        where: 'id = ? AND type = ?',
        whereArgs: [
          transaction.id,
          FinanceTransactionType.expense.databaseValue,
        ],
      );
      if (updatedRows != 1) {
        throw StateError('O lançamento de despesa não foi encontrado.');
      }
    }
    notifyListeners();
  }

  @override
  Future<FinanceOverview> loadOverview({DateTime? now, DateTime? month}) async {
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
    final fixedExpenses = await database.rawQuery(
      '''
      SELECT COALESCE(SUM(COALESCE(monthly.amount, fixed.amount)), 0) AS expenses
      FROM fixed_expenses AS fixed
      LEFT JOIN fixed_expense_monthly_values AS monthly
        ON monthly.fixed_expense_id = fixed.id AND monthly.month = ?
      WHERE fixed.started_at < ?
      ''',
      [_monthKey(monthStart), nextMonth.toIso8601String()],
    );
    final fixedExpenseTotal = (fixedExpenses.first['expenses']! as num)
        .toDouble();
    final monthlyIncome = (monthlyTotals.first['income']! as num).toDouble();
    final monthlyExpenseTotal =
        (monthlyTotals.first['expenses']! as num).toDouble() +
        fixedExpenseTotal;

    return FinanceOverview(
      balance: monthlyIncome - monthlyExpenseTotal,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenseTotal,
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
      where:
          "type = 'expense' AND occurred_at >= ? AND occurred_at < ? "
          'AND is_fixed = 0',
      whereArgs: [monthStart.toIso8601String(), nextMonth.toIso8601String()],
      orderBy: 'occurred_at DESC, id DESC',
    );
    final fixedRows = await database.rawQuery(
      '''
      SELECT
        fixed.id AS id,
        fixed.description AS description,
        COALESCE(monthly.amount, fixed.amount) AS amount,
        'expense' AS type,
        fixed.category AS category,
        ? AS occurred_at,
        NULL AS import_key,
        1 AS is_fixed
      FROM fixed_expenses AS fixed
      LEFT JOIN fixed_expense_monthly_values AS monthly
        ON monthly.fixed_expense_id = fixed.id AND monthly.month = ?
      WHERE fixed.started_at < ?
      ORDER BY fixed.description COLLATE NOCASE
      ''',
      [
        monthStart.toIso8601String(),
        _monthKey(monthStart),
        nextMonth.toIso8601String(),
      ],
    );
    final transactions =
        [
          ...rows.map(FinanceTransaction.fromMap),
          ...fixedRows.map(FinanceTransaction.fromMap),
        ]..sort((first, second) {
          final dateOrder = second.occurredAt.compareTo(first.occurredAt);
          return dateOrder != 0
              ? dateOrder
              : first.description.compareTo(second.description);
        });
    return transactions;
  }

  String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';
}
