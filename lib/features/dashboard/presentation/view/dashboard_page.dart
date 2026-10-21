import 'package:flutter/material.dart';

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
        title: const Text('Finanças'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Visão geral',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Mês anterior',
                    onPressed: () {
                      final month = _viewModel.selectedExpenseMonth;
                      _viewModel.selectExpenseMonth(
                        DateTime(month.year, month.month - 1),
                      );
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    _formatMonth(_viewModel.selectedExpenseMonth),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    onPressed: () {
                      final month = _viewModel.selectedExpenseMonth;
                      _viewModel.selectExpenseMonth(
                        DateTime(month.year, month.month + 1),
                      );
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SummaryCard(
                title: 'Saldo do mês',
                value: _formatCurrency(_viewModel.balance),
                valueStyle: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Entradas do mês',
                value: _formatCurrency(_viewModel.monthlyIncome),
                valueStyle: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Despesas do mês',
                value: _formatCurrency(_viewModel.monthlyExpenses),
                valueStyle: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Text(
                'Gastos do mês',
                style: Theme.of(context).textTheme.titleLarge,
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
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhum gasto encontrado neste mês.'),
                  ),
                )
              else ...[
                Text(
                  'Total: ${_formatCurrency(_viewModel.selectedMonthExpenses)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ..._viewModel.expensesForSelectedMonth.map(
                  (transaction) => _TransactionTile(
                    transaction: transaction,
                    formattedAmount: _formatCurrency(transaction.amount),
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.valueStyle,
  });

  final String title;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(value, style: valueStyle),
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
  });

  final FinanceTransaction transaction;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == FinanceTransactionType.income;
    final color = isIncome ? Colors.green : Theme.of(context).colorScheme.error;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
        color: color,
      ),
      title: Text(transaction.description),
      subtitle: Text(
        '${transaction.occurredAt.day.toString().padLeft(2, '0')}/'
        '${transaction.occurredAt.month.toString().padLeft(2, '0')}/'
        '${transaction.occurredAt.year}',
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}$formattedAmount',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
