import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendwise_ai/main.dart';
import 'package:spendwise_ai/providers/app_providers.dart';
import 'package:spendwise_ai/services/local_prefs.dart';

/// App smoke tests (local demo mode, no Firebase needed).
void main() {
  testWidgets('SpendWise AI boots to splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefs.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          firebaseAvailableProvider.overrideWithValue(false),
        ],
        child: const SpendWiseApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Splash branding is visible.
    expect(find.text('SpendWise AI'), findsWidgets);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);

    // Let the splash navigation timer complete so the test ends cleanly.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('Splash routes to onboarding on fresh install', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefs.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          firebaseAvailableProvider.overrideWithValue(false),
        ],
        child: const SpendWiseApp(),
      ),
    );
    // Advance past the splash delay so it navigates.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Track your money'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
