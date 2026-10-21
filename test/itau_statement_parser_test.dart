import 'package:finances/features/transactions/domain/finance_transaction.dart';
import 'package:finances/features/upload/data/itau_statement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ItauStatementParser();

  test('parses income and expense rows and skips daily balances', () {
    final transactions = parser.parse('''
01/07/2026
PIX recebido
1.234,56
02/07/2026
Compra no débito
-23,40
02/07/2026
SALDO DO DIA
1.211,16
''');

    expect(transactions, hasLength(2));
    expect(transactions[0].amount, 1234.56);
    expect(transactions[0].type, FinanceTransactionType.income);
    expect(transactions[1].amount, 23.4);
    expect(transactions[1].type, FinanceTransactionType.expense);
    expect(transactions[1].occurredAt, DateTime(2026, 7, 2));
    expect(transactions.map((item) => item.description), [
      'PIX recebido',
      'Compra no débito',
    ]);
  });

  test('ignores saldo rows even when they follow a date line', () {
    final transactions = parser.parse('''
03/07/2026
SALDO DO DIA
50,00
''');

    expect(transactions, isEmpty);
  });

  test(
    'keeps repeated identical transactions distinct but re-import stable',
    () {
      const statement = '''
04/07/2026
PIX recebido
10,00
04/07/2026
PIX recebido
10,00
''';

      final firstImport = parser.parse(statement);
      final secondImport = parser.parse(statement);

      expect(firstImport, hasLength(2));
      expect(firstImport[0].importKey, isNot(firstImport[1].importKey));
      expect(
        firstImport.map((item) => item.importKey),
        secondImport.map((item) => item.importKey),
      );
    },
  );
}
