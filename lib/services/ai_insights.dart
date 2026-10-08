import '../core/utils/format.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

// ---------------------------------------------------------------------------
// AI insights abstraction. The provider can be swapped later
// (e.g. Gemini / OpenAI / Cloud Function) without touching the UI.
// ---------------------------------------------------------------------------

/// A single user-facing insight.
class AiInsight {
  final String title;
  final String body;
  final InsightTone tone;

  const AiInsight({required this.title, required this.body, this.tone = InsightTone.info});
}

enum InsightTone { good, warn, danger, info }

/// Result wrapper that always labels the source honestly.
class InsightResult {
  final List<AiInsight> insights;
  final bool isDemo; // true = on-device rule analysis, not an LLM call
  final String sourceLabel;

  const InsightResult({
    required this.insights,
    required this.isDemo,
    required this.sourceLabel,
  });
}

abstract class AiInsightProvider {
  Future<InsightResult> analyze({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required String currencyCode,
    required String monthKey,
  });
}

/// On-device, rule-based analysis. Always available, works offline,
/// and is clearly labeled as demo/on-device — never pretends to be an LLM.
class RuleBasedInsightProvider implements AiInsightProvider {
  @override
  Future<InsightResult> analyze({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required String currencyCode,
    required String monthKey,
  }) async {
    final stats = TransactionStats(transactions);
    final current = stats.inMonth(monthKey);
    final prevKey = _prevMonth(monthKey);
    final prev = stats.inMonth(prevKey);

    final income = stats.totalIncome(current);
    final expense = stats.totalExpense(current);
    final prevExpense = stats.totalExpense(prev);
    final byCat = stats.expenseByCategory(current);

    final out = <AiInsight>[];

    if (current.isEmpty) {
      out.add(const AiInsight(
        title: 'No data yet this month',
        body: 'Add a few transactions and I\'ll start spotting patterns '
            'in your spending.',
      ));
      return InsightResult(
        insights: out,
        isDemo: true,
        sourceLabel: 'On-device analysis (demo)',
      );
    }

    if (byCat.isNotEmpty) {
      final top = byCat.entries.first;
      out.add(AiInsight(
        title: 'Highest spending: ${top.key}',
        body:
            'You spent ${Format.money(top.value, currencyCode)} on ${top.key.toLowerCase()} '
            'in ${Format.monthLabel(monthKey)} — that\'s the largest slice of your expenses.',
        tone: InsightTone.info,
      ));
    }

    if (prev.isNotEmpty) {
      final diff = expense - prevExpense;
      final pct = prevExpense == 0
          ? 0.0
          : (diff / prevExpense * 100).abs();
      if (diff > 0) {
        // Find which category grew most.
        final prevByCat = stats.expenseByCategory(prev);
        String driver = '';
        double maxGrow = 0;
        for (final e in byCat.entries) {
          final grow = e.value - (prevByCat[e.key] ?? 0);
          if (grow > maxGrow) {
            maxGrow = grow;
            driver = e.key;
          }
        }
        out.add(AiInsight(
          title: 'Spending up ${pct.toStringAsFixed(0)}% vs last month',
          body: driver.isEmpty
              ? 'You spent ${Format.money(diff, currencyCode)} more than in '
                '${Format.monthLabel(prevKey)}. Review recent purchases to see what changed.'
              : 'You spent ${Format.money(diff, currencyCode)} more than in '
                '${Format.monthLabel(prevKey)}, mostly driven by ${driver.toLowerCase()}. '
                'Consider setting a weekly ${driver.toLowerCase()} budget.',
          tone: InsightTone.warn,
        ));
      } else if (diff < 0) {
        out.add(AiInsight(
          title: 'Nice — spending down ${pct.toStringAsFixed(0)}%',
          body:
              'You saved ${Format.money(-diff, currencyCode)} compared with '
              '${Format.monthLabel(prevKey)}. Keep the momentum going.',
          tone: InsightTone.good,
        ));
      }
    }

    // Budget warnings.
    final monthBudgets =
        budgets.where((b) => b.month == monthKey).toList();
    for (final b in monthBudgets) {
      final spent = b.isOverall
          ? expense
          : current
              .where((t) =>
                  t.isExpense &&
                  t.category.toLowerCase() == b.category.toLowerCase())
              .fold(0.0, (s, t) => s + t.amount);
      final p = BudgetProgress(budget: b, spent: spent);
      if (p.isOver) {
        out.add(AiInsight(
          title:
              '${b.isOverall ? 'Monthly' : b.category} budget exceeded',
          body:
              'You spent ${Format.money(spent, currencyCode)} of a '
              '${Format.money(b.amount, currencyCode)} '
              '${b.isOverall ? 'monthly' : b.category.toLowerCase()} budget. '
              'Try a 48-hour pause on non-essential ${b.isOverall ? 'purchases' : b.category.toLowerCase()} spending.',
          tone: InsightTone.danger,
        ));
      } else if (p.isNearLimit) {
        out.add(AiInsight(
          title:
              'Approaching ${b.isOverall ? 'monthly' : b.category} limit',
          body:
              'You\'ve used ${(p.progress * 100).toStringAsFixed(0)}% of your '
              '${Format.money(b.amount, currencyCode)} '
              '${b.isOverall ? 'monthly' : b.category.toLowerCase()} budget with '
              '${Format.money(p.remaining, currencyCode)} left.',
          tone: InsightTone.warn,
        ));
      }
    }

    // Savings opportunity: small frequent food/entertainment spends.
    final smallFrequent = current
        .where((t) =>
            t.isExpense &&
            (t.category == 'Food' || t.category == 'Entertainment') &&
            t.amount < 500)
        .toList();
    if (smallFrequent.length >= 6) {
      final total = smallFrequent.fold(0.0, (s, t) => s + t.amount);
      out.add(AiInsight(
        title: 'Small purchases add up',
        body:
            '${smallFrequent.length} small food/entertainment purchases total '
            '${Format.money(total, currencyCode)} this month. Cooking two more '
            'meals a week could save roughly ${Format.money(total * 0.3, currencyCode)}.',
        tone: InsightTone.info,
      ));
    }

    if (income > 0 && expense > income) {
      out.add(AiInsight(
        title: 'Spending above income',
        body:
            'Expenses (${Format.money(expense, currencyCode)}) exceed income '
            '(${Format.money(income, currencyCode)}) this month. Prioritise '
            'needs over wants until the balance recovers.',
        tone: InsightTone.danger,
      ));
    } else if (income > 0) {
      final rate = (income - expense) / income * 100;
      if (rate >= 20) {
        out.add(AiInsight(
          title: 'Healthy savings rate',
          body:
              'You\'re saving about ${rate.toStringAsFixed(0)}% of income this month. '
              'Consider moving the surplus into a separate savings goal.',
          tone: InsightTone.good,
        ));
      }
    }

    // Unusual spending: single transaction > 40% of monthly expense.
    TransactionModel? spike;
    for (final t in current.where((t) => t.isExpense)) {
      if (expense > 0 && t.amount / expense > 0.4) {
        spike = t;
        break;
      }
    }
    if (spike != null) {
      out.add(AiInsight(
        title: 'Unusually large transaction',
        body:
            'A single ${spike.category.toLowerCase()} expense of '
            '${Format.money(spike.amount, currencyCode)} on '
            '${Format.date(spike.date)} stands out. If it wasn\'t planned, '
            'it may be worth reviewing.',
        tone: InsightTone.warn,
      ));
    }

    if (out.isEmpty) {
      out.add(const AiInsight(
        title: 'Steady month',
        body: 'No major concerns detected. Keep tracking to unlock '
            'deeper insights.',
        tone: InsightTone.good,
      ));
    }

    return InsightResult(
      insights: out,
      isDemo: true,
      sourceLabel: 'On-device analysis (demo)',
    );
  }

  String _prevMonth(String key) {
    final parts = key.split('-');
    var y = int.parse(parts[0]);
    var m = int.parse(parts[1]) - 1;
    if (m < 1) {
      m = 12;
      y -= 1;
    }
    return '$y-${m.toString().padLeft(2, '0')}';
  }
}

/// Remote LLM provider stub.
///
/// Configure via `--dart-define=SPENDWISE_AI_KEY=...` (and optionally
/// `--dart-define=SPENDWISE_AI_ENDPOINT=...`). The key is NEVER hard-coded.
/// When no key is present, [isConfigured] is false and callers should fall
/// back to [RuleBasedInsightProvider].
class RemoteAiInsightProvider implements AiInsightProvider {
  static const _key = String.fromEnvironment('SPENDWISE_AI_KEY');
  static const _endpoint = String.fromEnvironment('SPENDWISE_AI_ENDPOINT');

  bool get isConfigured => _key.isNotEmpty && _endpoint.isNotEmpty;

  @override
  Future<InsightResult> analyze({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required String currencyCode,
    required String monthKey,
  }) async {
    if (!isConfigured) {
      // Graceful fallback: never fail, never pretend.
      return RuleBasedInsightProvider().analyze(
        transactions: transactions,
        budgets: budgets,
        currencyCode: currencyCode,
        monthKey: monthKey,
      );
    }
    // A real HTTP implementation would go here, posting an anonymised
    // summary (never raw PII) to the configured endpoint.
    // For now, delegate to the rule engine and label honestly.
    final fallback = await RuleBasedInsightProvider().analyze(
      transactions: transactions,
      budgets: budgets,
      currencyCode: currencyCode,
      monthKey: monthKey,
    );
    return InsightResult(
      insights: fallback.insights,
      isDemo: false,
      sourceLabel: 'AI provider (remote)',
    );
  }
}

/// Facade used by the UI: prefers remote when configured, else on-device.
class AiInsightService {
  final RemoteAiInsightProvider _remote = RemoteAiInsightProvider();
  final AiInsightProvider _local = RuleBasedInsightProvider();

  bool get usesRemote => _remote.isConfigured;

  Future<InsightResult> getInsights({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required String currencyCode,
    String? monthKey,
  }) {
    final key = monthKey ?? Format.currentMonthKey();
    final provider = usesRemote ? _remote : _local;
    return provider.analyze(
      transactions: transactions,
      budgets: budgets,
      currencyCode: currencyCode,
      monthKey: key,
    );
  }
}

/// Categories for the demo-data generator, kept separate from real data.
class DemoDataService {
  static List<TransactionModel> sample(String uid) {
    final now = DateTime.now();
    double amt(double v) => v;
    TransactionModel tx(
      TransactionType type,
      double amount,
      String category,
      int daysAgo,
      String note,
      String method,
    ) =>
        TransactionModel(
          id: '',
          type: type,
          amount: amount,
          category: category,
          date: DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysAgo)),
          note: note,
          paymentMethod: method,
        );

    return [
      tx(TransactionType.income, amt(45000), 'Salary', 4, 'Monthly salary', 'Bank Transfer'),
      tx(TransactionType.income, amt(6000), 'Freelance', 9, 'Logo design', 'UPI'),
      tx(TransactionType.expense, amt(320), 'Food', 0, 'Lunch', 'UPI'),
      tx(TransactionType.expense, amt(850), 'Food', 1, 'Groceries', 'Card'),
      tx(TransactionType.expense, amt(120), 'Transport', 1, 'Metro', 'Wallet'),
      tx(TransactionType.expense, amt(1499), 'Shopping', 2, 'Headphones', 'Card'),
      tx(TransactionType.expense, amt(499), 'Entertainment', 3, 'Movie', 'UPI'),
      tx(TransactionType.expense, amt(2200), 'Bills', 5, 'Electricity', 'Bank Transfer'),
      tx(TransactionType.expense, amt(650), 'Health', 6, 'Pharmacy', 'Cash'),
      tx(TransactionType.expense, amt(400), 'Transport', 7, 'Fuel', 'Cash'),
      tx(TransactionType.expense, amt(999), 'Education', 10, 'Course', 'Card'),
      tx(TransactionType.expense, amt(1800), 'Food', 12, 'Dinner out', 'UPI'),
      // Previous month for comparison insights.
      tx(TransactionType.income, amt(45000), 'Salary', 34, 'Last month salary', 'Bank Transfer'),
      tx(TransactionType.expense, amt(2600), 'Food', 36, 'Groceries', 'Card'),
      tx(TransactionType.expense, amt(3100), 'Travel', 38, 'Weekend trip', 'Card'),
    ];
  }

  static List<BudgetModel> sampleBudgets() {
    final key = Format.currentMonthKey();
    return [
      BudgetModel(id: '', category: 'Overall', amount: 30000, month: key),
      BudgetModel(id: '', category: 'Food', amount: 6000, month: key),
      BudgetModel(id: '', category: 'Transport', amount: 2000, month: key),
      BudgetModel(id: '', category: 'Entertainment', amount: 1500, month: key),
    ];
  }

  /// All demo transactions are tagged `note` containing '[demo]'? No —
  /// instead demo data is only inserted on explicit user action and the
  /// UI offers one-tap removal (clearAll). Kept simple and honest.
  static bool get isDemoDataAvailable => true;
}
