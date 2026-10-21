import 'package:flutter/foundation.dart';

import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/domain/finance_transaction.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({FinanceRepository? repository})
    : _repository = repository ?? SqliteFinanceRepository() {
    _selectedExpenseMonth = DateTime.now();
    _repository.addListener(_onTransactionsChanged);
    load();
  }

  final FinanceRepository _repository;
  double _balance = 0;
  double _monthlyIncome = 0;
  double _monthlyExpenses = 0;
  List<FinanceTransaction> _recentTransactions = const [];
  List<FinanceTransaction> _expensesForSelectedMonth = const [];
  late DateTime _selectedExpenseMonth;
  int _monthRequestId = 0;
  String? _errorMessage;

  double get balance => _balance;
  double get monthlyIncome => _monthlyIncome;
  double get monthlyExpenses => _monthlyExpenses;
  List<FinanceTransaction> get recentTransactions => _recentTransactions;
  DateTime get selectedExpenseMonth => _selectedExpenseMonth;
  List<FinanceTransaction> get expensesForSelectedMonth =>
      _expensesForSelectedMonth;
  double get selectedMonthExpenses => _expensesForSelectedMonth.fold(
    0,
    (total, transaction) => total + transaction.amount,
  );
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    final monthRequestId = ++_monthRequestId;
    final selectedMonth = _selectedExpenseMonth;
    try {
      final overview = await _repository.loadOverview(month: selectedMonth);
      final transactions = await _repository.loadRecentTransactions();
      final expenses = await _repository.loadExpensesForMonth(
        selectedMonth,
      );
      _recentTransactions = transactions;
      if (monthRequestId == _monthRequestId) {
        _balance = overview.balance;
        _monthlyIncome = overview.monthlyIncome;
        _monthlyExpenses = overview.monthlyExpenses;
        _expensesForSelectedMonth = expenses;
        _errorMessage = null;
      }
    } on Exception {
      if (monthRequestId == _monthRequestId) {
        _errorMessage = 'Não foi possível carregar os lançamentos.';
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> selectExpenseMonth(DateTime month) async {
    final selectedMonth = DateTime(month.year, month.month);
    _selectedExpenseMonth = selectedMonth;
    final monthRequestId = ++_monthRequestId;
    notifyListeners();

    try {
      final overview = await _repository.loadOverview(month: selectedMonth);
      final expenses = await _repository.loadExpensesForMonth(selectedMonth);
      if (monthRequestId == _monthRequestId) {
        _balance = overview.balance;
        _monthlyIncome = overview.monthlyIncome;
        _monthlyExpenses = overview.monthlyExpenses;
        _expensesForSelectedMonth = expenses;
        _errorMessage = null;
      }
    } on Exception {
      if (monthRequestId == _monthRequestId) {
        _errorMessage = 'Não foi possível carregar os lançamentos.';
      }
    } finally {
      if (monthRequestId == _monthRequestId) {
        notifyListeners();
      }
    }
  }

  void _onTransactionsChanged() {
    load();
  }

  @override
  void dispose() {
    _repository.removeListener(_onTransactionsChanged);
    super.dispose();
  }
}
