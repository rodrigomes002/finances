import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../../transactions/data/finance_repository.dart';
import '../../data/itau_statement_parser.dart';

class StatementImportViewModel extends ChangeNotifier {
  StatementImportViewModel({
    FinanceRepository? repository,
    ItauStatementParser? parser,
  }) : _repository = repository ?? SqliteFinanceRepository(),
       _parser = parser ?? ItauStatementParser();

  final FinanceRepository _repository;
  final ItauStatementParser _parser;
  bool _isImporting = false;

  bool get isImporting => _isImporting;

  Future<StatementImportResult> importPdf(Uint8List bytes) async {
    _isImporting = true;
    notifyListeners();

    try {
      final document = PdfDocument(inputBytes: bytes);
      late final String text;
      try {
        text = PdfTextExtractor(document).extractText();
      } finally {
        document.dispose();
      }

      final transactions = _parser.parse(text);
      if (transactions.isEmpty) {
        throw const FormatException(
          'Nenhum lançamento reconhecido. Verifique se o PDF é um extrato Itaú com texto selecionável.',
        );
      }

      final importedCount = await _repository.importTransactions(transactions);
      return StatementImportResult(
        importedCount: importedCount,
        duplicateCount: transactions.length - importedCount,
      );
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }
}

class StatementImportResult {
  const StatementImportResult({
    required this.importedCount,
    required this.duplicateCount,
  });

  final int importedCount;
  final int duplicateCount;
}
