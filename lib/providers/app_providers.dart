import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/ai_insights.dart';
import '../services/auth_service.dart';
import '../services/local_prefs.dart';
import '../services/repositories.dart';

// ---- bootstrap (overridden in main) ----
final localPrefsProvider = Provider<LocalPrefs>((ref) {
  throw UnimplementedError('localPrefsProvider must be overridden');
});

final firebaseAvailableProvider = Provider<bool>((ref) => false);

// ---- services ----
final authServiceProvider = Provider<AuthService>((ref) {
  final available = ref.watch(firebaseAvailableProvider);
  return AuthService(
    firebaseAvailable: available,
    prefs: ref.watch(localPrefsProvider),
    auth: available ? FirebaseAuth.instance : null,
    db: available ? FirebaseFirestore.instance : null,
  );
});

final transactionRepoProvider = Provider<TransactionRepository>((ref) {
  if (ref.watch(firebaseAvailableProvider)) {
    return FirestoreTransactionRepository(FirebaseFirestore.instance);
  }
  return LocalTransactionRepository(ref.watch(localPrefsProvider));
});

final budgetRepoProvider = Provider<BudgetRepository>((ref) {
  if (ref.watch(firebaseAvailableProvider)) {
    return FirestoreBudgetRepository(FirebaseFirestore.instance);
  }
  return LocalBudgetRepository(ref.watch(localPrefsProvider));
});

final aiServiceProvider = Provider<AiInsightService>((ref) => AiInsightService());

// ---- auth state ----
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authState();
});

// ---- settings (theme / currency / notifications) ----
class SettingsState {
  final String themeMode; // system | light | dark
  final String currency;
  final bool notifications;
  const SettingsState({
    this.themeMode = 'system',
    this.currency = 'INR',
    this.notifications = true,
  });

  SettingsState copyWith({String? themeMode, String? currency, bool? notifications}) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        currency: currency ?? this.currency,
        notifications: notifications ?? this.notifications,
      );

  ThemeMode get theme =>
      themeMode == 'light' ? ThemeMode.light : themeMode == 'dark' ? ThemeMode.dark : ThemeMode.system;
}

class SettingsController extends StateNotifier<SettingsState> {
  final LocalPrefs prefs;
  SettingsController(this.prefs)
      : super(SettingsState(
          themeMode: prefs.themeMode,
          currency: prefs.currency,
          notifications: prefs.notificationsEnabled,
        ));

  Future<void> setTheme(String v) async {
    await prefs.setThemeMode(v);
    state = state.copyWith(themeMode: v);
  }

  Future<void> setCurrency(String v) async {
    await prefs.setCurrency(v);
    state = state.copyWith(currency: v);
  }

  Future<void> setNotifications(bool v) async {
    await prefs.setNotificationsEnabled(v);
    state = state.copyWith(notifications: v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref.watch(localPrefsProvider));
});

// ---- data streams ----
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(transactionRepoProvider).watch(user.uid);
});

final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(budgetRepoProvider).watch(user.uid);
});
