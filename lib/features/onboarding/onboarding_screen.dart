import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Slide(this.icon, this.title, this.subtitle);
}

const _slides = [
  _Slide(Icons.receipt_long_rounded, 'Track your money',
      'Log income and expenses in seconds with smart categories.'),
  _Slide(Icons.donut_large_rounded, 'Understand your spending',
      'Beautiful charts reveal exactly where your money goes.'),
  _Slide(Icons.auto_awesome_rounded, 'Make smarter decisions',
      'Budgets and AI-powered insights keep you on track every month.'),
];

/// 3-slide onboarding with Skip / Next / Get Started. Stored locally.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _ctrl = PageController();
  int _index = 0;

  Future<void> _finish() async {
    await ref.read(localPrefsProvider).setOnboardingDone(true);
    if (!mounted) return;
    final user = ref.read(authServiceProvider).currentUser();
    Navigator.of(context)
        .pushReplacementNamed(user == null ? '/login' : '/home');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon,
                              size: 72,
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 32),
                        Text(s.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(s.subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _index == i
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_index == _slides.length - 1) {
                      _finish();
                    } else {
                      _ctrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Text(
                      _index == _slides.length - 1 ? 'Get Started' : 'Next'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
