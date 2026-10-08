import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/format.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_providers.dart';

/// Bottom-sheet form for creating or editing a transaction.
class AddEditTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  final TransactionType initialType;
  const AddEditTransactionSheet({
    super.key,
    this.existing,
    this.initialType = TransactionType.expense,
  });

  @override
  ConsumerState<AddEditTransactionSheet> createState() =>
      _AddEditTransactionSheetState();
}

class _AddEditTransactionSheetState
    extends ConsumerState<AddEditTransactionSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late TransactionType _type;
  late String _category;
  late String _method;
  late DateTime _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.initialType;
    _category = e?.category ??
        (widget.initialType == TransactionType.expense
            ? AppConstants.expenseCategories.first
            : AppConstants.incomeCategories.first);
    _method = e?.paymentMethod.isNotEmpty == true
        ? e!.paymentMethod
        : AppConstants.paymentMethods.first;
    _date = e?.date ?? DateTime.now();
    if (e != null) {
      _amount.text = e.amount % 1 == 0
          ? e.amount.toInt().toString()
          : e.amount.toString();
      _note.text = e.note;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<String> get _categories => _type == TransactionType.expense
      ? AppConstants.expenseCategories
      : AppConstants.incomeCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(authServiceProvider).currentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final amount = FinanceMath.parseAmount(_amount.text)!;
      final repo = ref.read(transactionRepoProvider);
      if (widget.existing == null) {
        await repo.add(
          user.uid,
          TransactionModel(
            id: const Uuid().v4(),
            type: _type,
            amount: amount,
            category: _category,
            date: _date,
            note: _note.text.trim(),
            paymentMethod: _method,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        await repo.update(
            user.uid,
            widget.existing!.copyWith(
              type: _type,
              amount: amount,
              category: _category,
              date: _date,
              note: _note.text.trim(),
              paymentMethod: _method,
            ));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.existing == null
              ? 'Transaction added'
              : 'Transaction updated')));
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
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                  widget.existing == null
                      ? 'Add transaction'
                      : 'Edit transaction',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _category = _type == TransactionType.expense
                      ? AppConstants.expenseCategories.first
                      : AppConstants.incomeCategories.first;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee)),
                validator: Validators.amount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categories.contains(_category)
                    ? _category
                    : _categories.first,
                decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined)),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? _categories.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(Format.date(_date)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: AppConstants.paymentMethods.contains(_method)
                          ? _method
                          : AppConstants.paymentMethods.first,
                      decoration: const InputDecoration(
                          labelText: 'Payment',
                          prefixIcon: Icon(Icons.payment_outlined)),
                      items: AppConstants.paymentMethods
                          .map((m) => DropdownMenuItem(
                              value: m, child: Text(m, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() =>
                          _method = v ?? AppConstants.paymentMethods.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLength: 140,
                decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.note_outlined)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.existing == null
                        ? 'Add ${_type == TransactionType.expense ? 'Expense' : 'Income'}'
                        : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
