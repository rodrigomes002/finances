import 'package:finances/app/app.dart';
import 'package:finances/core/widgets/finances_logo.dart';
import 'package:finances/features/transactions/data/finance_repository.dart';
import 'package:finances/features/transactions/domain/finance_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigates between dashboard and upload', (tester) async {
    await tester.pumpWidget(FinancesApp(repository: _FakeFinanceRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first))
          .scaffoldBackgroundColor,
      Colors.white,
    );
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Abrir menu'), findsOneWidget);
    expect(find.byType(FinancesLogo), findsOneWidget);
    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Envie seu extrato bancário em PDF'), findsNothing);

    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    expect(find.byType(FinancesLogo), findsAtLeastNWidgets(2));
    await tester.tap(find.text('Lançamento manual'));
    await tester.pumpAndSettle();

    expect(find.text('Registre sua renda ou seus gastos'), findsOneWidget);

    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    expect(find.text('Envie seu extrato bancário em PDF'), findsOneWidget);
    expect(find.text('Visão geral'), findsNothing);

    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Envie seu extrato bancário em PDF'), findsNothing);
  });
}

class _FakeFinanceRepository extends ChangeNotifier
    implements FinanceRepository {
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
  }) async {}

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

  @override
  Future<List<FinanceTransaction>> loadExpensesForMonth(DateTime month) async =>
      [];

  @override
  Future<List<FinanceTransaction>> loadIncomesForMonth(DateTime month) async =>
      [];
}
