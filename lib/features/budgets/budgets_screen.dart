import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/format.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_providers.dart';

/// Monthly + category budgets with progress, warnings and over-budget state.
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    _monthKey = Format.currentMonthKey();
  }

  Future<void> _openEditor({BudgetModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BudgetEditor(
        monthKey: _monthKey,
        existing: existing,
      ),
    );
  }

  Future<void> _delete(String uid, BudgetModel b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text(
            'Remove the ${b.isOverall ? 'monthly' : b.category} budget for ${Format.monthLabel(b.month)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(budgetRepoProvider).remove(uid, b.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(settingsProvider).currency;
    final budgetsAsync = ref.watch(budgetsProvider);
    final txAsync = ref.watch(transactionsProvider);
    final user = ref.watch(authServiceProvider).currentUser();

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New budget'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    final p = _monthKey.split('-');
                    final d = DateTime(
                        int.parse(p[0]), int.parse(p[1]) - 1, 1);
                    setState(() => _monthKey = Format.monthKey(d));
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(Format.monthLabel(_monthKey),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    final p = _monthKey.split('-');
                    final d = DateTime(
                        int.parse(p[0]), int.parse(p[1]) + 1, 1);
                    setState(() => _monthKey = Format.monthKey(d));
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: budgetsAsync.when(
              loading: () => const LoadingView(message: 'Loading budgets…'),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(budgetsProvider),
              ),
              data: (all) {
                final monthBudgets =
                    all.where((b) => b.month == _monthKey).toList();
                final txs = txAsync.valueOrNull ?? [];
                final stats = TransactionStats(txs);
                final monthTx = stats.inMonth(_monthKey);
                final monthExpense = stats.totalExpense(monthTx);

                double spentFor(BudgetModel b) {
                  if (b.isOverall) return monthExpense;
                  return monthTx
                      .where((t) =>
                          t.isExpense &&
                          t.category.toLowerCase() ==
                              b.category.toLowerCase())
                      .fold(0.0, (s, t) => s + t.amount);
                }

                if (monthBudgets.isEmpty) {
                  return EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'No budgets for ${Format.monthLabel(_monthKey)}',
                    subtitle:
                        'Create a monthly budget or per-category limits to stay on track.',
                    actionLabel: 'Create budget',
                    onAction: () => _openEditor(),
                  );
                }
                // Overall first.
                monthBudgets.sort((a, b) {
                  if (a.isOverall && !b.isOverall) return -1;
                  if (!a.isOverall && b.isOverall) return 1;
                  return a.category.compareTo(b.category);
                });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: monthBudgets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final b = monthBudgets[i];
                    final spent = spentFor(b);
                    final p =
                        BudgetProgress(budget: b, spent: spent);
                    final color = p.isOver
                        ? theme.colorScheme.error
                        : p.isNearLimit
                            ? Colors.orange
                            : theme.colorScheme.primary;
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.isOverall
                                      ? 'Overall monthly budget'
                                      : b.category,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (p.isOver)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Exceeded',
                                      style: TextStyle(
                                          color: theme
                                              .colorScheme.onErrorContainer,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                )
                              else if (p.isNearLimit)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Near limit',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') {
                                    _openEditor(existing: b);
                                  } else if (v == 'delete' &&
                                      user != null) {
                                    _delete(user.uid, b);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: p.progress,
                              minHeight: 10,
                              backgroundColor: theme
                                  .colorScheme.surfaceContainerHighest,
                              valueColor:
                                  AlwaysStoppedAnimation(color),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${Format.money(spent, currency)} of ${Format.money(b.amount, currency)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                p.isOver
                                    ? '${Format.money(-p.remaining, currency)} over'
                                    : '${Format.money(p.remaining, currency)} left',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: p.isOver
                                        ? theme.colorScheme.error
                                        : theme
                                            .colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetEditor extends ConsumerStatefulWidget {
  final String monthKey;
  final BudgetModel? existing;
  const _BudgetEditor({required this.monthKey, this.existing});

  @override
  ConsumerState<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends ConsumerState<_BudgetEditor> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late String _category;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? 'Overall';
    if (widget.existing != null) {
      final a = widget.existing!.amount;
      _amount.text = a % 1 == 0 ? a.toInt().toString() : a.toString();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(authServiceProvider).currentUser();
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final amount = FinanceMath.parseAmount(_amount.text)!;
      await ref.read(budgetRepoProvider).upsert(
            user.uid,
            BudgetModel(
              id: widget.existing?.id ?? '',
              category: _category,
              amount: amount,
              month: widget.monthKey,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = ['Overall', ...AppConstants.expenseCategories];
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  widget.existing == null
                      ? 'New budget · ${Format.monthLabel(widget.monthKey)}'
                      : 'Edit budget',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: options.contains(_category) ? _category : 'Overall',
                decoration: const InputDecoration(
                    labelText: 'Category',
                    helperText:
                        '“Overall” is the total monthly budget.'),
                items: options
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'Overall'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Budget amount',
                    prefixIcon: Icon(Icons.savings_outlined)),
                validator: Validators.budgetAmount,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
