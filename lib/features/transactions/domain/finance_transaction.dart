enum FinanceTransactionType {
  income,
  expense;

  String get databaseValue => name;
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.description,
    required this.amount,
    required this.type,
    required this.occurredAt,
    required this.importKey,
    required this.category,
  });

  final String description;
  final double amount;
  final FinanceTransactionType type;
  final DateTime occurredAt;
  final String importKey;
  final String category;

  factory FinanceTransaction.fromMap(Map<String, Object?> map) {
    return FinanceTransaction(
      description: map['description']! as String,
      amount: (map['amount']! as num).toDouble(),
      type: FinanceTransactionType.values.byName(map['type']! as String),
      occurredAt: DateTime.parse(map['occurred_at']! as String),
      importKey: map['import_key'] as String? ?? '',
      category: map['category']! as String,
    );
  }
}

class FinanceOverview {
  const FinanceOverview({
    required this.balance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
  });

  final double balance;
  final double monthlyIncome;
  final double monthlyExpenses;
}
