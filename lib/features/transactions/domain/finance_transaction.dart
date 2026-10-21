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
    this.id,
    this.isFixed = false,
  });

  final int? id;
  final String description;
  final double amount;
  final FinanceTransactionType type;
  final DateTime occurredAt;
  final String importKey;
  final String category;
  final bool isFixed;

  factory FinanceTransaction.fromMap(Map<String, Object?> map) {
    return FinanceTransaction(
      id: map['id'] as int?,
      description: map['description']! as String,
      amount: (map['amount']! as num).toDouble(),
      type: FinanceTransactionType.values.byName(map['type']! as String),
      occurredAt: DateTime.parse(map['occurred_at']! as String),
      importKey: map['import_key'] as String? ?? '',
      category: map['category']! as String,
      isFixed: (map['is_fixed'] as int? ?? 0) == 1,
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
