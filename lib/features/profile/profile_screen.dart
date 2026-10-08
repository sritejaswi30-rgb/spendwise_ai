import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/app_providers.dart';
import '../../services/ai_insights.dart';

/// Profile + settings: currency, theme, notifications, demo data, logout, about.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _loadDemo(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser();
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Load demo data?'),
        content: Text(
            'Clearly-labeled sample transactions and budgets will be added so you can explore charts and insights immediately.'),
        actions: [
          _DialogActions(),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final txRepo = ref.read(transactionRepoProvider);
      final bRepo = ref.read(budgetRepoProvider);
      for (final t in DemoDataService.sample(user.uid)) {
        await txRepo.add(user.uid, t);
      }
      for (final b in DemoDataService.sampleBudgets()) {
        await bRepo.upsert(user.uid, b);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data loaded')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))));
    }
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser();
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove all data?'),
        content: const Text(
            'All transactions and budgets for this account will be deleted. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete all')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(transactionRepoProvider).clearAll(user.uid);
      await ref.read(budgetRepoProvider).clearAll(user.uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data removed')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final user = ref.watch(authStateProvider).valueOrNull ??
        ref.read(authServiceProvider).currentUser();
    final demoMode = !ref.watch(firebaseAvailableProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (user?.name.isNotEmpty == true
                            ? user!.name[0]
                            : '?')
                        .toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '—',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(user?.email ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      if (demoMode)
                        Text('Local demo mode',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Preferences'),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_outlined),
                  title: const Text('Currency'),
                  trailing: DropdownButton<String>(
                    value: AppConstants.currencies
                            .containsKey(settings.currency)
                        ? settings.currency
                        : AppConstants.defaultCurrency,
                    underline: const SizedBox.shrink(),
                    items: AppConstants.currencies.entries
                        .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text('${e.key} (${e.value})')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) settingsCtrl.setCurrency(v);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Theme'),
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'system', label: Text('Auto')),
                      ButtonSegment(
                          value: 'light', label: Text('Light')),
                      ButtonSegment(
                          value: 'dark', label: Text('Dark')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) =>
                        settingsCtrl.setTheme(s.first),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary:
                      const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Budget alerts & insights'),
                  value: settings.notifications,
                  onChanged: settingsCtrl.setNotifications,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Data'),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: const Text('Load demo data'),
                  subtitle: const Text(
                      'Sample transactions to explore the app'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _loadDemo(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_sweep_outlined,
                      color: theme.colorScheme.error),
                  title: const Text('Remove all my data'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _clearData(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About SpendWise AI',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Track income and expenses, set monthly budgets, visualise spending and get AI-powered insights. '
                  'Data is stored per-user in Cloud Firestore when Firebase is configured, '
                  'otherwise locally on this device (demo mode).',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                    'Month key example: ${Format.currentMonthKey()} · v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Load')),
      ],
    );
  }
}
