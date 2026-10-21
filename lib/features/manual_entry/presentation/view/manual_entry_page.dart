import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/domain/finance_transaction.dart';
import '../viewmodel/manual_entry_view_model.dart';

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({
    super.key,
    required this.repository,
    this.onMenuPressed,
  });

  final FinanceRepository repository;
  final VoidCallback? onMenuPressed;

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late final ManualEntryViewModel _viewModel;
  FinanceTransactionType _type = FinanceTransactionType.expense;
  bool _isFixedTransaction = false;
  String? _category;
  DateTime _occurredAt = DateTime.now();

  static const _incomeCategories = [
    'Salário',
    'Freelance',
    'Investimentos',
    'Outros',
  ];
  static const _expenseCategories = [
    'Alimentação',
    'Moradia',
    'Transporte',
    'Saúde',
    'Lazer',
    'Compras',
    'Contas',
    'Educação',
    'Outros',
  ];

  List<String> get _categories => _type == FinanceTransactionType.income
      ? _incomeCategories
      : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _viewModel = ManualEntryViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Selecione a data do lançamento',
    );
    if (selectedDate != null) {
      setState(() => _occurredAt = selectedDate);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final transaction = FinanceTransaction(
      description: _descriptionController.text.trim(),
      amount: _parseAmount(_amountController.text)!,
      type: _type,
      occurredAt: _occurredAt,
      importKey: '',
      category: _category!,
      isFixed: _isFixedTransaction,
    );

    final saved = await _viewModel.save(transaction);
    if (!mounted) return;
    if (saved) {
      _formKey.currentState!.reset();
      _descriptionController.clear();
      _amountController.clear();
      setState(() {
        _category = null;
        _type = FinanceTransactionType.expense;
        _isFixedTransaction = false;
        _occurredAt = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lançamento salvo com sucesso.')),
      );
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
        title: const Text('Lançamento manual'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Registre sua renda ou seus gastos',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Os lançamentos serão salvos neste dispositivo.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          SegmentedButton<FinanceTransactionType>(
                            segments: const [
                              ButtonSegment(
                                value: FinanceTransactionType.expense,
                                label: Text('Gasto'),
                                icon: Icon(Icons.north_east_rounded),
                              ),
                              ButtonSegment(
                                value: FinanceTransactionType.income,
                                label: Text('Renda'),
                                icon: Icon(Icons.south_west_rounded),
                              ),
                            ],
                            selected: {_type},
                            onSelectionChanged: _viewModel.isSaving
                                ? null
                                : (selection) => setState(() {
                                    _type = selection.first;
                                    _category = null;
                                  }),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              hintText: 'Ex.: mercado, salário',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Informe uma descrição.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                              prefixText: 'R\$ ',
                              hintText: '0,00',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            validator: (value) {
                              final amount = _parseAmount(value ?? '');
                              if (amount == null || amount <= 0) {
                                return 'Informe um valor maior que zero.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: _viewModel.isSaving
                                ? null
                                : (value) => setState(() => _category = value),
                            validator: (value) => value == null
                                ? 'Selecione uma categoria.'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _isFixedTransaction,
                            title: Text(
                              _type == FinanceTransactionType.income
                                  ? 'Entrada fixa'
                                  : 'Despesa fixa',
                            ),
                            subtitle: Text(
                              _type == FinanceTransactionType.income
                                  ? 'Repetir esta entrada nos próximos meses'
                                  : 'Repetir este gasto nos próximos meses',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: _viewModel.isSaving
                                ? null
                                : (value) => setState(
                                    () => _isFixedTransaction = value ?? false,
                                  ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _viewModel.isSaving ? null : _selectDate,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text('Data: ${_formatDate(_occurredAt)}'),
                          ),
                          if (_viewModel.errorMessage case final message?) ...[
                            const SizedBox(height: 16),
                            Text(
                              message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _viewModel.isSaving ? null : _save,
                            icon: _viewModel.isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _viewModel.isSaving
                                  ? 'Salvando...'
                                  : 'Salvar lançamento',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double? _parseAmount(String value) {
    final normalized = value.trim().contains(',')
        ? value.trim().replaceAll('.', '').replaceAll(',', '.')
        : value.trim();
    return double.tryParse(normalized);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
