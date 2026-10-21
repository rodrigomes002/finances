import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/finances_logo.dart';
import '../../../transactions/data/finance_repository.dart';
import '../../../transactions/domain/finance_transaction.dart';
import '../viewmodel/dashboard_view_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.repository, this.onMenuPressed});

  final FinanceRepository? repository;
  final VoidCallback? onMenuPressed;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(repository: widget.repository);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
        title: Row(
          children: [
            const FinancesLogo(size: 30),
            const SizedBox(width: 10),
            const Text('Finanças'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'Visão geral',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Acompanhe como está o seu dinheiro.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _MonthSelector(
                formattedMonth: _formatMonth(_viewModel.selectedExpenseMonth),
                onPrevious: () {
                  final month = _viewModel.selectedExpenseMonth;
                  _viewModel.selectExpenseMonth(
                    DateTime(month.year, month.month - 1),
                  );
                },
                onNext: () {
                  final month = _viewModel.selectedExpenseMonth;
                  _viewModel.selectExpenseMonth(
                    DateTime(month.year, month.month + 1),
                  );
                },
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Saldo do mês',
                value: _formatCurrency(_viewModel.balance),
                icon: Icons.account_balance_wallet_outlined,
                variant: _SummaryVariant.balance,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Entradas do mês',
                      value: _formatCurrency(_viewModel.monthlyIncome),
                      icon: Icons.south_west_rounded,
                      variant: _SummaryVariant.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Despesas do mês',
                      value: _formatCurrency(_viewModel.monthlyExpenses),
                      icon: Icons.north_east_rounded,
                      variant: _SummaryVariant.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gastos do mês',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_viewModel.errorMessage case final message?)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(message),
                  ),
                )
              else if (_viewModel.expensesForSelectedMonth.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nenhum gasto encontrado neste mês.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Text(
                                'Total: ${_formatCurrency(_viewModel.selectedMonthExpenses)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ..._viewModel.expensesForSelectedMonth.indexed.map(
                          (entry) => _TransactionTile(
                            transaction: entry.$2,
                            formattedAmount: _formatCurrency(entry.$2.amount),
                            showDivider:
                                entry.$1 <
                                _viewModel.expensesForSelectedMonth.length - 1,
                            onEdit: () => _editExpenseAmount(entry.$2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    return 'R\$ $formatted';
  }

  String _formatMonth(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${months[date.month - 1]} de ${date.year}';
  }

  Future<void> _editExpenseAmount(FinanceTransaction transaction) async {
    final formKey = GlobalKey<FormState>();
    var amountInput = transaction.amount
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar valor'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: amountInput,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => amountInput = value,
            validator: (value) {
              final parsed = _parseAmount(value ?? '');
              if (parsed == null || !parsed.isFinite || parsed <= 0) {
                return 'Informe um valor maior que zero.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, _parseAmount(amountInput));
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (amount == null || !mounted) return;

    final saved = await _viewModel.updateExpenseAmount(transaction, amount);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Valor do gasto atualizado.'
              : 'Não foi possível atualizar o valor do gasto.',
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
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.formattedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final String formattedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              formattedMonth,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

enum _SummaryVariant { balance, income, expense }

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.variant,
  });

  final String title;
  final String value;
  final IconData icon;
  final _SummaryVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isBalance = variant == _SummaryVariant.balance;
    final accent = switch (variant) {
      _SummaryVariant.balance => Colors.white,
      _SummaryVariant.income => const Color(0xFF16845F),
      _SummaryVariant.expense => colors.error,
    };

    return Card(
      color: isBalance ? colors.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isBalance ? colors.primary : const Color(0xFFE7EEEB),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isBalance ? 20 : 14),
        child: isBalance
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 30,
                                  letterSpacing: -0.7,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: accent, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: accent,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.formattedAmount,
    required this.showDivider,
    required this.onEdit,
  });

  final FinanceTransaction transaction;
  final String formattedAmount;
  final bool showDivider;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFD65A57);
    final date =
        '${transaction.occurredAt.day.toString().padLeft(2, '0')}/'
        '${transaction.occurredAt.month.toString().padLeft(2, '0')}/'
        '${transaction.occurredAt.year}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      transaction.isFixed ? 'Despesa fixa' : date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '-$formattedAmount',
                style: const TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                tooltip: 'Editar valor de ${transaction.description}',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 52),
      ],
    );
  }
}
