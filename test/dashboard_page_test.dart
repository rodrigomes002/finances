import 'dart:ui' show Size;

import 'package:finances/features/dashboard/presentation/view/dashboard_page.dart';
import 'package:finances/features/transactions/data/finance_repository.dart';
import 'package:finances/features/transactions/domain/finance_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the initial personal finance overview', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: _FakeFinanceRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Saldo do mês'), findsOneWidget);
    expect(find.text('Entradas do mês'), findsAtLeastNWidgets(1));
    expect(find.text('Despesas do mês'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNWidgets(3));
    expect(find.text('Gastos e entradas recentes'), findsNothing);
    expect(find.text('Gastos do mês'), findsOneWidget);
    expect(find.text('Gastos por categoria'), findsOneWidget);
    expect(
      find.text('Adicione gastos para visualizar as categorias.'),
      findsOneWidget,
    );
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

    expect(find.text('R\$ 250,00'), findsAtLeastNWidgets(1));
    expect(find.text('R\$ 1000,00'), findsOneWidget);
    expect(find.text('R\$ 750,00'), findsAtLeastNWidgets(1));
    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('+R\$ 1000,00'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('-R\$ 750,00'), findsOneWidget);
    expect(find.text('Despesa'), findsAtLeastNWidgets(1));
    expect(find.text('100,0%'), findsOneWidget);
  });

  testWidgets('groups monthly expenses by category in the pie chart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeFinanceRepository(
      transactions: [
        FinanceTransaction(
          description: 'Almoço',
          amount: 100,
          type: FinanceTransactionType.expense,
          occurredAt: DateTime.now(),
          importKey: 'lunch',
          category: 'Alimentação',
        ),
        FinanceTransaction(
          description: 'Jantar',
          amount: 50,
          type: FinanceTransactionType.expense,
          occurredAt: DateTime.now(),
          importKey: 'dinner',
          category: 'Alimentação',
        ),
        FinanceTransaction(
          description: 'Ônibus',
          amount: 50,
          type: FinanceTransactionType.expense,
          occurredAt: DateTime.now(),
          importKey: 'bus',
          category: 'Transporte',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gastos por categoria'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('R\$ 150,00'), findsOneWidget);
    expect(find.text('R\$ 50,00'), findsOneWidget);
    expect(find.text('75,0%'), findsOneWidget);
    expect(find.text('25,0%'), findsOneWidget);
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
    expect(find.text('R\$ 250,00'), findsAtLeastNWidgets(1));
    expect(find.text('-R\$ 250,00'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Mês anterior'));
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();

    expect(find.text('R\$ 400,00'), findsOneWidget);
    expect(find.text('R\$ 500,00'), findsOneWidget);
    expect(find.text('R\$ 100,00'), findsWidgets);
    expect(find.text('Gasto do mês anterior'), findsWidgets);
    expect(find.text('Gasto do mês atual'), findsNothing);
    expect(find.text('Entrada do mês anterior'), findsOneWidget);
    expect(find.text('Total: R\$ 100,00'), findsOneWidget);
  });

  testWidgets('edits the selected month expense amount', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final expense = _transaction(
      description: 'Conta de luz',
      amount: 120,
      date: DateTime.now(),
      importKey: 'electricity',
    );
    final repository = _FakeFinanceRepository(transactions: [expense]);

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações de Conta de luz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '180,50');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repository.updatedAmount, 180.5);
    expect(repository.updatedMonth?.month, DateTime.now().month);
    expect(find.text('Valor do gasto atualizado.'), findsOneWidget);
  });

  testWidgets('confirms and deletes an expense from the selected month', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final expense = _transaction(
      description: 'Conta de luz',
      amount: 120,
      date: DateTime.now(),
      importKey: 'electricity',
    );
    final repository = _FakeFinanceRepository(transactions: [expense]);

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações de Conta de luz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir gasto?'), findsOneWidget);
    expect(
      find.text('O gasto "Conta de luz" será removido permanentemente.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(repository.deletedTransaction, same(expense));
    expect(find.text('Conta de luz'), findsNothing);
    expect(find.text('Nenhum gasto encontrado neste mês.'), findsOneWidget);
    expect(find.text('Gasto excluído.'), findsOneWidget);
  });

  testWidgets('confirms and deletes an income from the selected month', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final income = _transaction(
      description: 'Renda extra',
      amount: 450,
      date: DateTime.now(),
      importKey: 'extra-income',
      type: FinanceTransactionType.income,
    );
    final repository = _FakeFinanceRepository(transactions: [income]);

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações de Renda extra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir entrada?'), findsOneWidget);
    expect(
      find.text('A entrada "Renda extra" será removida permanentemente.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(repository.deletedTransaction, same(income));
    expect(find.text('Renda extra'), findsNothing);
    expect(find.text('Nenhuma entrada encontrada neste mês.'), findsOneWidget);
    expect(find.text('Entrada excluída.'), findsOneWidget);
  });

  testWidgets('shows and edits a fixed income for the selected month', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixedIncome = FinanceTransaction(
      description: 'Salário mensal',
      amount: 3200,
      type: FinanceTransactionType.income,
      occurredAt: DateTime.now(),
      importKey: '',
      category: 'Salário',
      isFixed: true,
      id: 1,
    );
    final repository = _FakeFinanceRepository(incomes: [fixedIncome]);

    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entradas do mês'), findsAtLeastNWidgets(2));
    expect(find.text('Entrada fixa'), findsOneWidget);
    expect(find.text('+R\$ 3200,00'), findsOneWidget);

    await tester.tap(find.byTooltip('Configurações de Salário mensal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '3500,00');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repository.updatedTransaction, same(fixedIncome));
    expect(repository.updatedAmount, 3500);
    expect(find.text('Valor da entrada atualizado.'), findsOneWidget);
  });
}

class _FakeFinanceRepository extends ChangeNotifier
    implements FinanceRepository {
  _FakeFinanceRepository({
    this.overview,
    List<FinanceTransaction> transactions = const [],
    this.incomes = const [],
  }) : transactions = List.of(transactions);

  final FinanceOverview? overview;
  final List<FinanceTransaction> transactions;
  final List<FinanceTransaction> incomes;
  FinanceTransaction? updatedTransaction;
  double? updatedAmount;
  DateTime? updatedMonth;
  FinanceTransaction? deletedTransaction;

  @override
  Future<int> importTransactions(List<FinanceTransaction> transactions) async =>
      transactions.length;

  @override
  Future<void> addTransaction(FinanceTransaction transaction) async {}

  @override
  Future<void> updateTransactionAmount({
    required FinanceTransaction transaction,
    required double amount,
    required DateTime month,
  }) async {
    updatedTransaction = transaction;
    updatedAmount = amount;
    updatedMonth = month;
  }

  @override
  Future<void> deleteTransaction(FinanceTransaction transaction) async {
    deletedTransaction = transaction;
    transactions.remove(transaction);
    notifyListeners();
  }

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

  @override
  Future<List<FinanceTransaction>> loadIncomesForMonth(DateTime month) async {
    return [
      ...transactions.where(
        (transaction) =>
            transaction.type == FinanceTransactionType.income &&
            transaction.occurredAt.year == month.year &&
            transaction.occurredAt.month == month.month,
      ),
      ...incomes.where(
        (transaction) =>
            transaction.occurredAt.year == month.year &&
            transaction.occurredAt.month == month.month,
      ),
    ];
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
