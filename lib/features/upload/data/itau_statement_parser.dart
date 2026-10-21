import '../../transactions/domain/finance_transaction.dart';

class ItauStatementParser {
  static final RegExp _datePattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
  static final RegExp _amountPattern = RegExp(
    r'^([+-])?\s*(?:R\$\s*)?([+-])?\s*((?:\d{1,3}(?:\.\d{3})+)|\d+),(\d{2})$',
  );

  List<FinanceTransaction> parse(String text) {
    DateTime? transactionDate;
    final descriptionParts = <String>[];
    final occurrences = <String, int>{};
    final transactions = <FinanceTransaction>[];

    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final normalizedLine = _normalize(line);
      if (normalizedLine.contains('SALDO DO DIA') ||
          normalizedLine.startsWith('SALDO ')) {
        transactionDate = null;
        descriptionParts.clear();
        continue;
      }

      if (_datePattern.hasMatch(line)) {
        transactionDate = _parseDate(line);
        descriptionParts.clear();
        continue;
      }

      if (transactionDate == null) continue;

      final amountMatch = _amountPattern.firstMatch(line);
      if (amountMatch == null) {
        descriptionParts.add(line);
        continue;
      }

      final description = _normalize(descriptionParts.join(' '));
      final amountText =
          '${amountMatch.group(3)!.replaceAll('.', '')}.${amountMatch.group(4)}';
      final absoluteAmount = double.parse(amountText);
      final sign = amountMatch.group(1) ?? amountMatch.group(2);

      if (description.isNotEmpty && absoluteAmount > 0) {
        final type = sign == '-'
            ? FinanceTransactionType.expense
            : FinanceTransactionType.income;
        final keyBase =
            '${transactionDate.toIso8601String().substring(0, 10)}|'
            '${type.databaseValue}|${absoluteAmount.toStringAsFixed(2)}|$description';
        final occurrence = occurrences.update(
          keyBase,
          (count) => count + 1,
          ifAbsent: () => 1,
        );

        transactions.add(
          FinanceTransaction(
            description: descriptionParts.join(' ').trim(),
            amount: absoluteAmount,
            type: type,
            occurredAt: transactionDate,
            importKey: '$keyBase|$occurrence',
            category: type == FinanceTransactionType.income
                ? 'Entrada'
                : 'Despesa',
          ),
        );
      }

      transactionDate = null;
      descriptionParts.clear();
    }

    return transactions;
  }

  DateTime _parseDate(String value) {
    final parts = value.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  String _normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
}
