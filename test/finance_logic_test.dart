import 'package:flutter_test/flutter_test.dart';
import 'package:spendwise_ai/core/utils/validators.dart';
import 'package:spendwise_ai/models/budget_model.dart';
import 'package:spendwise_ai/models/transaction_model.dart';

TransactionModel tx(
  TransactionType type,
  double amount,
  String category,
  DateTime date,
) =>
    TransactionModel(
      id: 't1',
      type: type,
      amount: amount,
      category: category,
      date: date,
    );

void main() {
  group('TransactionStats', () {
    final march = [
      tx(TransactionType.income, 50000, 'Salary', DateTime(2026, 3, 5)),
      tx(TransactionType.income, 5000, 'Freelance', DateTime(2026, 3, 12)),
      tx(TransactionType.expense, 3000, 'Food', DateTime(2026, 3, 6)),
      tx(TransactionType.expense, 1500, 'Food', DateTime(2026, 3, 20)),
      tx(TransactionType.expense, 2000, 'Bills', DateTime(2026, 3, 8)),
      tx(TransactionType.expense, 9000, 'Travel', DateTime(2026, 2, 10)),
    ];

    test('inMonth filters correctly', () {
      final stats = TransactionStats(march);
      expect(stats.inMonth('2026-03').length, 5);
      expect(stats.inMonth('2026-02').length, 1);
    });

    test('totals income and expense for a month', () {
      final stats = TransactionStats(march);
      final m = stats.inMonth('2026-03');
      expect(stats.totalIncome(m), 55000);
      expect(stats.totalExpense(m), 6500);
    });

    test('expenseByCategory is sorted descending', () {
      final stats = TransactionStats(march);
      final byCat = stats.expenseByCategory(stats.inMonth('2026-03'));
      expect(byCat.keys.first, 'Food');
      expect(byCat['Food'], 4500);
      expect(byCat['Bills'], 2000);
    });

    test('empty list gives zero totals', () {
      const stats = TransactionStats([]);
      expect(stats.totalIncome(), 0);
      expect(stats.totalExpense(), 0);
      expect(stats.expenseByCategory(), isEmpty);
    });
  });

  group('Budget math', () {
    test('progress is clamped 0..1', () {
      expect(FinanceMath.budgetProgress(500, 1000), 0.5);
      expect(FinanceMath.budgetProgress(1500, 1000), 1.0);
      expect(FinanceMath.budgetProgress(0, 0), 0);
    });

    test('BudgetProgress flags over and near-limit', () {
      const b = BudgetModel(
          id: '1', category: 'Food', amount: 1000, month: '2026-03');
      expect(
          const BudgetProgress(budget: b, spent: 1200).isOver, isTrue);
      expect(
          const BudgetProgress(budget: b, spent: 850).isNearLimit,
          isTrue);
      expect(
          const BudgetProgress(budget: b, spent: 500).isNearLimit,
          isFalse);
    });
  });

  group('Validators', () {
    test('email validation', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('bad'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('amount validation', () {
      expect(Validators.amount('100'), isNull);
      expect(Validators.amount('1,250.50'), isNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount(''), isNotNull);
    });

    test('parseAmount handles commas', () {
      expect(FinanceMath.parseAmount('1,250.50'), 1250.50);
      expect(FinanceMath.parseAmount('abc'), isNull);
    });

    test('password and name validation', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('123'), isNotNull);
      expect(Validators.name('Shre'), isNull);
      expect(Validators.name(''), isNotNull);
    });
  });
}
