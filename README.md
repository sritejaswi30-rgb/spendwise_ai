# SpendWise AI

A modern personal finance and expense management app built with Flutter + Firebase.
Track income and expenses, set monthly budgets, visualise spending, and get
AI-powered insights — wrapped in a clean Material 3 UI with light and dark mode.

## Features

- **Authentication** — login, register (name/email/password), forgot password, logout via Firebase Auth
- **Dashboard** — balance, month income/expense, budget remaining, quick add, recent transactions, spending summary, AI insight card
- **Transactions** — add/edit/delete with validation, search, filter by type + category, newest/oldest sort, delete confirmation
- **Analytics** — 6-month income-vs-expense bars, category pie, weekly trend, month picker (fl_chart)
- **Budgets** — overall monthly + per-category budgets, progress bars, near-limit warnings, exceeded state
- **AI Insights** — on-device rule analysis (highest category, month-over-month change, unusual spending, savings tips, budget warnings) with a swappable provider abstraction for a future LLM
- **Profile/Settings** — currency (default INR ₹), theme (system/light/dark), notifications toggle, demo-data loader, clear-data, about, logout
- **Onboarding + Splash** — 3-slide onboarding stored locally, animated splash with auth routing
- **Offline-friendly** — graceful loading/empty/error states everywhere; friendly messages instead of raw exceptions

## Screenshots

> Add screenshots here (e.g. `docs/screenshots/`):
>
> - `dashboard.png` — main dashboard
> - `transactions.png` — history + filters
> - `analytics.png` — charts
> - `budgets.png` — budget progress
> - `insights.png` — AI insights

## Tech Stack

| Layer | Choice |
|---|---|
| UI | Flutter 3, Dart 3, Material 3 |
| State | flutter_riverpod (consistent throughout) |
| Backend | Firebase Auth, Cloud Firestore |
| Charts | fl_chart |
| Local prefs | shared_preferences (onboarding, theme, currency, local-mode data only) |
| Formatting | intl |
| IDs | uuid |

No Firebase Storage is used (no binary uploads needed). Networking for a future
remote AI provider uses `package:http` only when configured.

## Architecture

Feature-based, understandable for students:

```
lib/
  core/        theme, constants, utils (validators, formatting), reusable widgets
  models/      app_user, transaction_model, budget_model (+ stats/math helpers)
  services/    auth_service, repositories (Firestore + local fallback),
               ai_insights (provider abstraction + rule engine + remote stub),
               local_prefs, demo data
  providers/   Riverpod: services, auth stream, settings, data streams
  features/    splash, onboarding, auth, dashboard, transactions,
               analytics, budgets, insights, profile
  routes/      MainShell (bottom nav) + route table
  main.dart    Firebase bootstrap (graceful local demo mode) + MaterialApp
```

**Data flow:** UI → Riverpod providers → repository abstraction → Firestore
(when configured) or local JSON persistence (demo mode). AI screen consumes the
same transaction/budget streams via `AiInsightService`.

## Firebase Setup

1. Create a project at <https://console.firebase.google.com>
2. **Android:** add app with package `com.spendwise.spendwise_ai`, download
   `google-services.json` → `android/app/`
3. **Auth:** enable *Email/Password* under Authentication → Sign-in method
4. **Firestore:** create database, then deploy `firestore.rules`:
   ```bash
   firebase deploy --only firestore:rules
   ```
5. (Optional, recommended) install FlutterFire and run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` (git-ignored). Then pass it to
   `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.

> Without these steps the app runs in **local demo mode** (clearly labeled in
> the UI): auth + data are stored on-device so `flutter run` works immediately.
> Password-reset email requires Firebase.

## AI Configuration

- Default: **on-device rule analysis** — labeled *“Demo insights · On-device
  analysis (demo)”*. No API keys, works offline.
- Future LLM: implement/swap `AiInsightProvider`, or configure the provided
  `RemoteAiInsightProvider` stub:
  ```bash
  flutter run --dart-define=SPENDWISE_AI_KEY=YOUR_KEY \
              --dart-define=SPENDWISE_AI_ENDPOINT=https://your-endpoint
  ```
- Never commit keys. Keys come only from `--dart-define` / CI secrets.

## How to Run

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## How to Build APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

For Play Store: `flutter build appbundle --release`.

## Firestore Data Model

```
users/{uid}
  name: string
  email: string
  currency: string (e.g. "INR")
  createdAt: timestamp

  transactions/{txId}
    type: "income" | "expense"
    amount: number
    category: string
    date: timestamp
    note: string
    paymentMethod: string
    createdAt, updatedAt: timestamp

  budgets/{budgetId}
    category: string ("Overall" = monthly total)
    amount: number
    month: "yyyy-MM"
    createdAt, updatedAt: timestamp
```

See `firestore.rules` for per-user isolation.

## Security Considerations

- Firestore rules deny cross-user access; unauthenticated reads/writes denied.
- No private credentials, API keys or tokens are hard-coded (see `.gitignore`).
- Passwords handled only by Firebase Auth; never stored in Firestore.
- Remote AI (when enabled) should receive anonymised aggregates, never raw PII.

## Testing

```bash
flutter test
```

Covers: monthly aggregation, income/expense totals, category ranking,
budget progress/clamping, near-limit + over-budget flags, validators
(email/amount/password/name), amount parsing.

## Future Improvements

- `flutterfire configure` generated options + push via Cloud Functions
- Real LLM provider (Gemini/OpenAI) with streaming + caching
- Recurring transactions, CSV export, savings goals
- Biometric lock, multi-currency conversion, widgets/i18n
