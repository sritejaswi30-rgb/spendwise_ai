import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_providers.dart';

/// Analytics: monthly income vs expense, category pie, spending trend.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    _monthKey = Format.currentMonthKey();
  }

  void _shiftMonth(int delta) {
    final parts = _monthKey.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]) + delta, 1);
    setState(() => _monthKey = Format.monthKey(dt));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(settingsProvider).currency;
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            tooltip: 'AI insights',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/insights'),
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const LoadingView(message: 'Crunching numbers…'),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(transactionsProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No data to analyse',
              subtitle: 'Add transactions and charts will appear here.',
            );
          }
          final stats = TransactionStats(all);
          final month = stats.inMonth(_monthKey);
          final income = stats.totalIncome(month);
          final expense = stats.totalExpense(month);
          final byCat = stats.expenseByCategory(month);
          final top = byCat.entries.take(5).toList();

          // Last 6 months income vs expense.
          final parts = _monthKey.split('-');
          final base = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
          final months = List.generate(
              6, (i) => DateTime(base.year, base.month - 5 + i, 1));
          final monthlyIncome = months
              .map((m) => stats.totalIncome(
                  stats.inMonth(Format.monthKey(m))))
              .toList();
          final monthlyExpense = months
              .map((m) => stats.totalExpense(
                  stats.inMonth(Format.monthKey(m))))
              .toList();

          // Weekly trend for selected month (4-5 buckets).
          final weeks = _weeklyExpense(month);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MonthPicker(
                label: Format.monthLabel(_monthKey),
                onPrev: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Income vs expense',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        'In ${Format.money(income, currency)} · Out ${Format.money(expense, currency)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= months.length) {
                                    return const SizedBox.shrink();
                                  }
                                  const names = [
                                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                  ];
                                  return Text(names[months[i].month - 1],
                                      style: theme.textTheme.labelSmall);
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(months.length, (i) {
                            final maxV = [
                              ...monthlyIncome,
                              ...monthlyExpense,
                              1.0
                            ].reduce((a, b) => a > b ? a : b);
                            double norm(double v) =>
                                maxV == 0 ? 0 : (v / maxV * 10);
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                    toY: norm(monthlyIncome[i]),
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                    color: theme.colorScheme.primary),
                                BarChartRodData(
                                    toY: norm(monthlyExpense[i]),
                                    width: 8,
                                    borderRadius: BorderRadius.circular(4),
                                    color: theme.colorScheme.error),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Legend(
                            color: theme.colorScheme.primary,
                            label: 'Income'),
                        const SizedBox(width: 16),
                        _Legend(
                            color: theme.colorScheme.error,
                            label: 'Expense'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Where money goes',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (byCat.isEmpty)
                      const Text('No expenses this month.')
                    else
                      SizedBox(
                        height: 190,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 44,
                            sectionsSpace: 2,
                            sections: top.map((e) {
                              final total = byCat.values
                                  .fold(0.0, (a, b) => a + b);
                              final pct = total == 0
                                  ? 0.0
                                  : e.value / total * 100;
                              final idx = top.indexOf(e);
                              final color = Colors.primaries[
                                  idx % Colors.primaries.length];
                              return PieChartSectionData(
                                value: e.value,
                                title: '${pct.toStringAsFixed(0)}%',
                                radius: 56,
                                color: color,
                                titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    for (final e in top)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text(e.key)),
                            Text(Format.money(e.value, currency),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly spending trend',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Text(
                                    'W${v.toInt() + 1}',
                                    style: theme.textTheme.labelSmall),
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(weeks.length,
                                  (i) => FlSpot(i.toDouble(), weeks[i])),
                              isCurved: true,
                              barWidth: 3,
                              color: theme.colorScheme.primary,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  /// Buckets the month's expense into week-of-month sums.
  List<double> _weeklyExpense(List<TransactionModel> month) {
    final weeks = [0.0, 0.0, 0.0, 0.0, 0.0];
    for (final t in month.where((t) => t.isExpense)) {
      final idx = ((t.date.day - 1) ~/ 7).clamp(0, 4);
      weeks[idx] += t.amount;
    }
    // Normalise for chart readability (log-ish scale guard).
    final maxV = weeks.fold(0.0, (a, b) => a > b ? a : b);
    if (maxV == 0) return weeks;
    return weeks.map((w) => w / maxV * 5).toList();
  }
}

class _MonthPicker extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthPicker(
      {required this.label, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
            onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded)),
        Expanded(
          child: Center(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        IconButton(
            onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
