import 'dart:ui' show Size;

import 'package:finances/features/dashboard/presentation/view/dashboard_page.dart';
import 'package:finances/features/transactions/data/finance_repository.dart';
import 'package:finances/features/transactions/domain/finance_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the initial personal finance overview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: _FakeFinanceRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Saldo do mês'), findsOneWidget);
    expect(find.text('Entradas do mês'), findsOneWidget);
    expect(find.text('Despesas do mês'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNWidgets(3));
    expect(find.text('Gastos e entradas recentes'), findsNothing);
    expect(find.text('Gastos do mês'), findsOneWidget);
  });

  testWidgets('shows imported income and expense movements', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeFinanceRepository(
      overview: const FinanceOverview(
        balance: 250,
        monthlyIncome: 1000,
        monthlyExpenses: 750,
      ),
      transactions: [
        FinanceTransaction(
          description: 'Salário',
          amount: 1000,
          type: FinanceTransactionType.income,
          occurredAt: DateTime.now(),
          importKey: 'income-1',
          category: 'Entrada',
        ),
        FinanceTransaction(
          description: 'Mercado',
          amount: 750,
          type: FinanceTransactionType.expense,
          occurredAt: DateTime.now(),
          importKey: 'expense-1',
          category: 'Despesa',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('R\$ 250,00'), findsOneWidget);
    expect(find.text('R\$ 1000,00'), findsOneWidget);
    expect(find.text('R\$ 750,00'), findsOneWidget);
    expect(find.text('Salário'), findsNothing);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('-R\$ 750,00'), findsOneWidget);
  });

  testWidgets('filters expenses by selected month', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final currentMonth = DateTime.now();
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    final repository = _FakeFinanceRepository(
      transactions: [
        _transaction(
          description: 'Gasto do mês anterior',
          amount: 100,
          date: previousMonth,
          importKey: 'previous-month-expense',
        ),
        _transaction(
          description: 'Gasto do mês atual',
          amount: 250,
          date: currentMonth,
          importKey: 'current-month-expense',
        ),
        _transaction(
          description: 'Entrada do mês anterior',
          amount: 500,
          date: previousMonth,
          importKey: 'previous-month-income',
          type: FinanceTransactionType.income,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('R\$ 0,00'), findsOneWidget);
    expect(find.text('R\$ 250,00'), findsOneWidget);
    expect(find.text('-R\$ 250,00'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Mês anterior'));
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();

    expect(find.text('R\$ 400,00'), findsOneWidget);
    expect(find.text('R\$ 500,00'), findsOneWidget);
    expect(find.text('R\$ 100,00'), findsWidgets);
    expect(find.text('Gasto do mês anterior'), findsWidgets);
    expect(find.text('Gasto do mês atual'), findsNothing);
    expect(find.text('Entrada do mês anterior'), findsNothing);
    expect(find.text('Total: R\$ 100,00'), findsOneWidget);
  });
}

class _FakeFinanceRepository extends ChangeNotifier
    implements FinanceRepository {
  _FakeFinanceRepository({
    this.overview,
    this.transactions = const [],
  });

  final FinanceOverview? overview;
  final List<FinanceTransaction> transactions;

  @override
  Future<int> importTransactions(List<FinanceTransaction> transactions) async =>
      transactions.length;

  @override
  Future<FinanceOverview> loadOverview({DateTime? now, DateTime? month}) async {
    if (overview case final value?) return value;
    final selectedMonth = month ?? now ?? DateTime.now();
    final monthlyTransactions = transactions.where(
      (transaction) =>
          transaction.occurredAt.year == selectedMonth.year &&
          transaction.occurredAt.month == selectedMonth.month,
    );
    var income = 0.0;
    var expenses = 0.0;
    for (final transaction in monthlyTransactions) {
      if (transaction.type == FinanceTransactionType.income) {
        income += transaction.amount;
      } else {
        expenses += transaction.amount;
      }
    }
    return FinanceOverview(
      balance: income - expenses,
      monthlyIncome: income,
      monthlyExpenses: expenses,
    );
  }

  @override
  Future<List<FinanceTransaction>> loadRecentTransactions({
    int limit = 10,
  }) async => transactions.take(limit).toList();

  @override
  Future<List<FinanceTransaction>> loadExpensesForMonth(DateTime month) async {
    return transactions
        .where(
          (transaction) =>
              transaction.type == FinanceTransactionType.expense &&
              transaction.occurredAt.year == month.year &&
              transaction.occurredAt.month == month.month,
        )
        .toList();
  }
}

FinanceTransaction _transaction({
  required String description,
  required double amount,
  required DateTime date,
  required String importKey,
  FinanceTransactionType type = FinanceTransactionType.expense,
}) {
  return FinanceTransaction(
    description: description,
    amount: amount,
    type: type,
    occurredAt: date,
    importKey: importKey,
    category: type == FinanceTransactionType.income ? 'Entrada' : 'Despesa',
  );
}
