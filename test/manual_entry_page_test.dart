import 'package:finances/features/manual_entry/presentation/view/manual_entry_page.dart';
import 'package:finances/features/transactions/data/finance_repository.dart';
import 'package:finances/features/transactions/domain/finance_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saves a manual income transaction', (tester) async {
    final repository = _FakeFinanceRepository();

    await tester.pumpWidget(
      MaterialApp(home: ManualEntryPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renda'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Salário mensal');
    await tester.enterText(find.byType(TextFormField).at(1), '1250,50');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salário').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar lançamento'));
    await tester.tap(find.text('Salvar lançamento'));
    await tester.pumpAndSettle();

    expect(repository.addedTransaction, isNotNull);
    expect(repository.addedTransaction!.description, 'Salário mensal');
    expect(repository.addedTransaction!.amount, 1250.5);
    expect(repository.addedTransaction!.type, FinanceTransactionType.income);
    expect(repository.addedTransaction!.category, 'Salário');
    expect(find.text('Lançamento salvo com sucesso.'), findsOneWidget);
  });

  testWidgets('saves a fixed expense', (tester) async {
    final repository = _FakeFinanceRepository();

    await tester.pumpWidget(
      MaterialApp(home: ManualEntryPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Aluguel');
    await tester.enterText(find.byType(TextFormField).at(1), '1500,00');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moradia').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Despesa fixa'));
    await tester.ensureVisible(find.text('Salvar lançamento'));
    await tester.tap(find.text('Salvar lançamento'));
    await tester.pumpAndSettle();

    expect(repository.addedTransaction, isNotNull);
    expect(repository.addedTransaction!.description, 'Aluguel');
    expect(repository.addedTransaction!.isFixed, isTrue);
  });

  testWidgets('saves a fixed income', (tester) async {
    final repository = _FakeFinanceRepository();

    await tester.pumpWidget(
      MaterialApp(home: ManualEntryPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renda'));
    await tester.pumpAndSettle();
    expect(find.text('Entrada fixa'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Salário');
    await tester.enterText(find.byType(TextFormField).at(1), '3000,00');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salário').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrada fixa'));
    await tester.ensureVisible(find.text('Salvar lançamento'));
    await tester.tap(find.text('Salvar lançamento'));
    await tester.pumpAndSettle();

    expect(repository.addedTransaction, isNotNull);
    expect(repository.addedTransaction!.type, FinanceTransactionType.income);
    expect(repository.addedTransaction!.isFixed, isTrue);
  });
}

class _FakeFinanceRepository extends ChangeNotifier
    implements FinanceRepository {
  FinanceTransaction? addedTransaction;

  @override
  Future<void> addTransaction(FinanceTransaction transaction) async {
    addedTransaction = transaction;
  }

  @override
  Future<void> updateTransactionAmount({
    required FinanceTransaction transaction,
    required double amount,
    required DateTime month,
  }) async {}

  @override
  Future<void> deleteTransaction(FinanceTransaction transaction) async {}

  @override
  Future<int> importTransactions(List<FinanceTransaction> transactions) async =>
      transactions.length;

  @override
  Future<List<FinanceTransaction>> loadExpensesForMonth(DateTime month) async =>
      [];

  @override
  Future<List<FinanceTransaction>> loadIncomesForMonth(DateTime month) async =>
      [];

  @override
  Future<FinanceOverview> loadOverview({
    DateTime? now,
    DateTime? month,
  }) async =>
      const FinanceOverview(balance: 0, monthlyIncome: 0, monthlyExpenses: 0);

  @override
  Future<List<FinanceTransaction>> loadRecentTransactions({
    int limit = 10,
  }) async => [];
}
