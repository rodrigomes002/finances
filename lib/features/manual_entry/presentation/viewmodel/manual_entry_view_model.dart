import 'package:flutter/foundation.dart';

import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/domain/finance_transaction.dart';

class ManualEntryViewModel extends ChangeNotifier {
  ManualEntryViewModel({required FinanceRepository repository})
    : _repository = repository;

  final FinanceRepository _repository;
  bool _isSaving = false;
  String? _errorMessage;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<bool> save(FinanceTransaction transaction) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addTransaction(transaction);
      return true;
    } on Exception catch (error) {
      _errorMessage = 'Não foi possível salvar o lançamento: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
