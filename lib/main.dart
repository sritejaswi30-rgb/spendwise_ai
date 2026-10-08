import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_screens.dart';
import 'features/insights/insights_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'providers/app_providers.dart';
import 'routes/main_shell.dart';
import 'services/local_prefs.dart';

/// Firebase configuration.
///
/// 1. Create a Firebase project at https://console.firebase.google.com
/// 2. Add an Android app (package: com.spendwise.spendwise_ai) and
///    download google-services.json into android/app/
/// 3. Enable Email/Password under Authentication → Sign-in method
/// 4. Create a Cloud Firestore database and deploy firestore.rules
/// 5. Run: flutterfire configure  (or wire DefaultFirebaseOptions manually)
///
/// The app starts WITHOUT Firebase too (local demo mode) so that
/// `flutter run` works immediately for review. Firebase features
/// (cloud sync, password-reset email) activate once configured.
Future<bool> _tryInitFirebase() async {
  try {
    // Will throw when no Firebase config files exist — that is expected
    // in local demo mode.
    await Firebase.initializeApp();
    // Touch instances so misconfiguration surfaces early.
    FirebaseAuth.instance;
    FirebaseFirestore.instance;
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await LocalPrefs.load();
  final firebaseAvailable = await _tryInitFirebase();

  runApp(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
        firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
      ],
      child: const SpendWiseApp(),
    ),
  );
}

class SpendWiseApp extends ConsumerWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'SpendWise AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot': (_) => const ForgotPasswordScreen(),
        '/insights': (_) => const InsightsScreen(),
        ...buildRoutes(),
      },
    );
  }
}
