import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  double _balance = 0;
  double _monthlyExpenses = 0;

  double get balance => _balance;
  double get monthlyExpenses => _monthlyExpenses;

  void updateOverview({
    required double balance,
    required double monthlyExpenses,
  }) {
    _balance = balance;
    _monthlyExpenses = monthlyExpenses;
    notifyListeners();
  }
}
