import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../services/ai_insights.dart';
import '../transactions/add_edit_transaction.dart';

/// Category icon mapping shared across dashboard + transactions.
IconData categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food':
      return Icons.restaurant_outlined;
    case 'transport':
      return Icons.directions_bus_outlined;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'education':
      return Icons.school_outlined;
    case 'entertainment':
      return Icons.movie_outlined;
    case 'bills':
      return Icons.receipt_outlined;
    case 'health':
      return Icons.favorite_outline;
    case 'travel':
      return Icons.flight_outlined;
    case 'salary':
      return Icons.work_outline;
    case 'freelance':
      return Icons.laptop_outlined;
    case 'allowance':
      return Icons.wallet_outlined;
    case 'scholarship':
      return Icons.school_outlined;
    default:
      return Icons.category_outlined;
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _openAdd(BuildContext context, TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddEditTransactionSheet(initialType: type),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(settingsProvider).currency;
    final txAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final monthKey = Format.currentMonthKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SpendWise AI'),
        actions: [
          IconButton(
            tooltip: 'AI insights',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/insights'),
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const LoadingView(message: 'Loading your money…'),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(transactionsProvider),
        ),
        data: (all) {
          final stats = TransactionStats(all);
          final month = stats.inMonth(monthKey);
          final income = stats.totalIncome(month);
          final expense = stats.totalExpense(month);
          final balance = income - expense;
          final budgets = budgetsAsync.valueOrNull
                  ?.where((b) => b.month == monthKey)
                  .toList() ??
              [];
          final overall = budgets.where((b) => b.isOverall).toList();
          final totalBudget =
              overall.isEmpty ? 0.0 : overall.first.amount;
          final remaining = totalBudget - expense;
          final recent = List<TransactionModel>.from(month)
            ..sort((a, b) => b.date.compareTo(a.date));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionsProvider);
              ref.invalidate(budgetsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _BalanceCard(
                  balance: balance,
                  income: income,
                  expense: expense,
                  currency: currency,
                  monthLabel: Format.monthLabel(monthKey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            _openAdd(context, TransactionType.expense),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Add Expense'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openAdd(context, TransactionType.income),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Income'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (totalBudget > 0)
                  _BudgetProgressCard(
                    spent: expense,
                    budget: totalBudget,
                    remaining: remaining,
                    currency: currency,
                  ),
                const SizedBox(height: 16),
                _AiPreviewCard(transactions: all, currency: currency),
                const SizedBox(height: 16),
                SectionHeader(
                  title: 'Recent transactions',
                  actionLabel: null,
                  onAction: null,
                ),
                if (recent.isEmpty)
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    subtitle:
                        'Tap “Add Expense” to log your first transaction.',
                    actionLabel: 'Add expense',
                    onAction: () =>
                        _openAdd(context, TransactionType.expense),
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (var i = 0;
                            i < (recent.length > 5 ? 5 : recent.length);
                            i++)
                          _TxTile(
                              tx: recent[i],
                              currency: currency,
                              showDivider: i !=
                                  (recent.length > 5 ? 5 : recent.length) -
                                      1),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Spending summary'),
                const SizedBox(height: 8),
                _SpendingSummary(
                    transactions: month, currency: currency),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final String currency;
  final String monthLabel;
  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.currency,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total balance · $monthLabel',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.85))),
            const SizedBox(height: 4),
            Text(Format.money(balance, currency),
                style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Flow(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Income',
                      value: Format.money(income, currency)),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.onPrimary
                        .withValues(alpha: 0.3)),
                Expanded(
                  child: _Flow(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Expenses',
                      value: Format.money(expense, currency)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Flow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary
                          .withValues(alpha: 0.8))),
              Text(value,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final double spent;
  final double budget;
  final double remaining;
  final String currency;
  const _BudgetProgressCard({
    required this.spent,
    required this.budget,
    required this.remaining,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final over = spent > budget;
    return AppCard(
          onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Budget progress',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                  over ? theme.colorScheme.error : theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            over
                ? 'Over budget by ${Format.money(-remaining, currency)}'
                : '${Format.money(remaining, currency)} remaining of ${Format.money(budget, currency)}',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: over
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AiPreviewCard extends ConsumerWidget {
  final List<TransactionModel> transactions;
  final String currency;
  const _AiPreviewCard({required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: () => Navigator.of(context).pushNamed('/insights'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome,
                color: theme.colorScheme.onTertiaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI insight',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                FutureBuilder<InsightResult>(
                  future: ref.read(aiServiceProvider).getInsights(
                      transactions: transactions,
                      budgets: ref.read(budgetsProvider).valueOrNull ?? [],
                      currencyCode: currency),
                  builder: (context, snap) {
                    final text = snap.hasData && snap.data!.insights.isNotEmpty
                        ? snap.data!.insights.first.body
                        : 'Analysing your spending…';
                    return Text(text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant));
                  },
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  final String currency;
  final bool showDivider;
  const _TxTile(
      {required this.tx, required this.currency, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExp = tx.isExpense;
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: (isExp
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.primaryContainer)
                .withValues(alpha: 0.7),
            child: Icon(categoryIcon(tx.category), size: 20),
          ),
          title: Text(tx.category,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${Format.date(tx.date)}${tx.note.isNotEmpty ? ' · ${tx.note}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          trailing: Text(
            '${isExp ? '−' : '+'}${Format.money(tx.amount, currency)}',
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isExp
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 72),
      ],
    );
  }
}

class _SpendingSummary extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;
  const _SpendingSummary({required this.transactions, required this.currency});

  @override
  Widget build(BuildContext context) {
    final stats = TransactionStats(transactions);
    final byCat = stats.expenseByCategory();
    if (byCat.isEmpty) {
      return const AppCard(
          child: Text('No expenses this month yet.'));
    }
    final total = byCat.values.fold(0.0, (a, b) => a + b);
    final top = byCat.entries.take(4).toList();
    return AppCard(
      child: Column(
        children: [
          for (final e in top) ...[
            Row(
              children: [
                Icon(categoryIcon(e.key), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(e.key)),
                Text(Format.money(e.value, currency),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : (e.value / total).clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
