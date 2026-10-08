import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../dashboard/dashboard_screen.dart' show categoryIcon;
import 'add_edit_transaction.dart';

enum TxFilter { all, income, expense }

/// Full transaction history with search, filters, sort, edit, delete.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _query = '';
  TxFilter _filter = TxFilter.all;
  String? _category; // null = all
  bool _newestFirst = true;

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddEditTransactionSheet(),
    );
  }

  Future<void> _confirmDelete(String uid, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This cannot be undone.'),
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
      await ref.read(transactionRepoProvider).remove(uid, id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(settingsProvider).currency;
    final txAsync = ref.watch(transactionsProvider);
    final user = ref.watch(authServiceProvider).currentUser();

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              hintText: 'Search note or category…',
              leading: const Icon(Icons.search),
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == TxFilter.all,
                  onSelected: (_) =>
                      setState(() => _filter = TxFilter.all),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: _filter == TxFilter.income,
                  onSelected: (_) =>
                      setState(() => _filter = TxFilter.income),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Expenses'),
                  selected: _filter == TxFilter.expense,
                  onSelected: (_) =>
                      setState(() => _filter = TxFilter.expense),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _category,
                  hint: const Text('Category'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All categories')),
                    ...{
                      ...AppConstants.expenseCategories,
                      ...AppConstants.incomeCategories
                    }.map((c) =>
                        DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _newestFirst ? 'Newest first' : 'Oldest first',
                  icon: Icon(_newestFirst
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded),
                  onPressed: () =>
                      setState(() => _newestFirst = !_newestFirst),
                ),
              ],
            ),
          ),
          Expanded(
            child: txAsync.when(
              loading: () =>
                  const LoadingView(message: 'Loading transactions…'),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(transactionsProvider),
              ),
              data: (all) {
                var list = all.where((t) {
                  if (_filter == TxFilter.income &&
                      t.type != TransactionType.income) {
                    return false;
                  }
                  if (_filter == TxFilter.expense &&
                      t.type != TransactionType.expense) {
                    return false;
                  }
                  if (_category != null && t.category != _category) {
                    return false;
                  }
                  if (_query.isNotEmpty) {
                    final hay =
                        '${t.category} ${t.note} ${t.amount}'.toLowerCase();
                    if (!hay.contains(_query)) return false;
                  }
                  return true;
                }).toList();
                list.sort((a, b) => _newestFirst
                    ? b.date.compareTo(a.date)
                    : a.date.compareTo(b.date));

                if (all.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    subtitle:
                        'Your income and expenses will appear here once you add them.',
                    actionLabel: 'Add transaction',
                    onAction: _openAdd,
                  );
                }
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No matches',
                    subtitle: 'Try a different search or filter.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final tx = list[i];
                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        if (user == null) return false;
                        await _confirmDelete(user.uid, tx.id);
                        return false; // stream rebuild handles removal
                      },
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(categoryIcon(tx.category), size: 20),
                          ),
                          title: Text(tx.category,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${Format.date(tx.date)}${tx.note.isNotEmpty ? ' · ${tx.note}' : ''}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${tx.isExpense ? '−' : '+'}${Format.money(tx.amount, currency)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: tx.isExpense
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary),
                              ),
                              if (tx.paymentMethod.isNotEmpty)
                                Text(tx.paymentMethod,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                            ],
                          ),
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) => AddEditTransactionSheet(
                                existing: tx),
                          ),
                        ),
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
