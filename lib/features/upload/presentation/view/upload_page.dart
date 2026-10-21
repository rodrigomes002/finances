import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../transactions/data/finance_repository.dart';
import '../viewmodel/statement_import_view_model.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key, this.repository, this.onMenuPressed});

  final FinanceRepository? repository;
  final VoidCallback? onMenuPressed;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  late final StatementImportViewModel _viewModel;
  String? _message;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _viewModel = StatementImportViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selectAndImportPdf() async {
    setState(() {
      _message = null;
      _hasError = false;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      final importResult = await _viewModel.importPdf(bytes);
      if (!mounted) return;
      setState(() {
        _message = importResult.importedCount == 0
            ? 'Este extrato já foi importado. Nenhum lançamento duplicado foi salvo.'
            : '${importResult.importedCount} lançamento(s) importado(s).'
                  '${importResult.duplicateCount > 0 ? ' ${importResult.duplicateCount} duplicado(s) ignorado(s).' : ''}';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error is FormatException
            ? error.message
            : 'Não foi possível importar o PDF: $error';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onMenuPressed == null
            ? null
            : IconButton(
                tooltip: 'Abrir menu',
                onPressed: widget.onMenuPressed,
                icon: const Icon(Icons.menu),
              ),
        title: const Text('Importar extrato'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, child) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text('Envie seu extrato bancário em PDF'),
                  const SizedBox(height: 8),
                  const Text(
                    'As entradas e despesas serão salvas no dispositivo. '
                    'Linhas “SALDO DO DIA” não são importadas.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _viewModel.isImporting
                        ? null
                        : _selectAndImportPdf,
                    icon: _viewModel.isImporting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: const Text('Selecionar PDF'),
                  ),
                  if (_message case final message?) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _hasError
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
