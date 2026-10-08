# A Skill Development Course Project Report on
# SPENDWISE AI – PERSONAL FINANCE MANAGEMENT APP USING FLUTTER AND FIREBASE

> Adapted from Flappy Bird reference structure, rewritten to match what was actually built in this workspace (`spendwise_ai`).

---

## TITLE PAGE

A
Skill Development Course Project Report on
**SPENDWISE AI – PERSONAL FINANCE MANAGEMENT APP USING FLUTTER AND FIREBASE**

Submitted
In Partial Fulfilment of the Requirements for the Award of Degree
**BACHELOR OF TECHNOLOGY**
**IN**
**COMPUTER SCIENCE AND ENGINEERING**

Submitted By
P.SRI TEJASWI 247Z1A05O1
P.MEENA 247Z1A05N8
S.PRANITHA 247Z1A05Q0
S.SURAIYA 247Z1A05Q1

SCHOOL OF ENGINEERING
Department of Computer Science and Engineering
NALLA NARASIMHA REDDY
EDUCATION SOCIETY'S GROUP OF INSTITUTIONS
(AN AUTONOMOUS INSTITUTION)
(Approved by AICTE, New Delhi, Affiliated to JNTU-Hyderabad)
Chowdariguda (Vill) Korremula 'x' Roads, Via Narapally, Ghatkesar (Mandal)
Medchal (Dist), Telangana-500088
2025-2026

---

## CERTIFICATE

SCHOOL OF ENGINEERING
DEPARTMENT OF COMPUTER SCIENCE AND ENGINEERING

**CERTIFICATE**

This is to certify that the skill development course project report titled **SPENDWISE AI – PERSONAL FINANCE MANAGEMENT APP USING FLUTTER AND FIREBASE** is being submitted by P.Sri Tejaswi (247Z1A05O1), P.Meena (247Z1A05N8), S.Pranitha (247Z1A05Q0), S.Suraiya (247Z1A05Q1) in partial fulfilment for the award of Bachelor of Technology in Computer Science and Engineering is a record of bonafide work carried out by her. The results embodied in this report have not been submitted to any other university for the award of any degree.

Internal Guide: ( G.Hari om )
Head of the Department: (Dr. K. Rameshwaraiah)

Submission Date :

---

## DECLARATION

**DECLARATION**

We, P.SRI TEJASWI, P.MEENA, S.PRANITHA, S.SURAIYA, students of Bachelor of Technology in Computer Science and Engineering, Nalla Narasimha Reddy Education Society's Group of Institutions, Hyderabad, Telangana, now declare that the work presented in this project work entitled "SpendWise AI – Personal Finance Management App Using Flutter and Firebase" is the outcome of our bonafide work and is correct to the best of my knowledge. This work has been undertaken taking care of engineering ethics. It contains no material previously published or written by another person nor material which has been accepted for the award of any other degree or diploma of the university or other institute of higher learning.

P.SRI TEJASWI 247Z1A05O1
P.MEENA 247Z1A05N8
S.PRANITHA 247Z1A05Q0
S.SURAIYA 247Z1A05Q1

Date: Signature

---

## ACKNOWLEDGEMENT

**ACKNOWLEDGEMENT**

I want to express my profound gratitude to our skilled development course project coordinator, G.Hari om, Professor, Department of Computer Science and Engineering, NNRESGI, for her support and guidance in completing my project, and for giving me this opportunity to present the research project work.

I profoundly express thanks to Dr.K.Rameshwaraiah, Professor & Head, Department of Computer Science and Engineering, NNRESGI, for his cooperation and encouragement in completing the project successfully.

I wish to express my sincere thanks to Dr.G.Janardhana Raju, Dean School of Engineering, NNRESGI, for providing the facilities for the completion of the project.

I wish to express my sincere thanks to Dr.C.V.Krishna Reddy, Director, NNRESGI, for providing the facilities for the completion of the project.

Finally, I would like to thank the project coordinator, all the faculty members and supporting staff, Department of Computer Science and Engineering, NNRESGI, for extending their help in all circumstances.

By
P.SRI TEJASWI 247Z1A05O1
P.MEENA 247Z1A05N8
S.PRANITHA 247Z1A05Q0
S.SURAIYA 247Z1A05Q1

---

## ABSTRACT — p. i

**ABSTRACT**

This project, titled "SpendWise AI – Personal Finance Management App Using Flutter and Firebase", focuses on the design and development of a clean, fast and cross-platform personal finance application using the Flutter framework, Riverpod state management, Firebase Auth / Cloud Firestore backend, and fl_chart visualisations. The user can register and log in, add income and expense transactions with category, date, note and payment method, set overall monthly and per-category budgets, visualise 6-month income-vs-expense bars, category pie and weekly trend, and receive AI-powered spending insights.

The app is built with a feature-based architecture. `lib/main.dart` bootstraps Firebase gracefully (local demo mode if unconfigured) and Material 3 theming. `lib/core/` holds theme, constants, validators and reusable widgets. `lib/models/` defines AppUser, TransactionModel and BudgetModel plus stats/math helpers. `lib/services/` provides auth_service, repositories (Firestore + local fallback), ai_insights (provider abstraction + rule engine + remote stub), local_prefs and demo data. `lib/providers/` exposes Riverpod services, auth stream, settings and data streams. `lib/features/` contains splash, onboarding, auth, dashboard, transactions, analytics, budgets, insights and profile screens. `lib/routes/` provides MainShell bottom navigation.

Features such as dashboard balance/income/expense/budget-remaining cards, transaction search/filter/sort, budget progress bars with near-limit/exceeded states, on-device rule-based AI insights (highest category, month-over-month change, unusual spending, savings tips, budget warnings) with a swappable provider for a future LLM, light/dark mode, INR default currency, onboarding + splash with auth routing, and offline-friendly demo mode make the app complete and usable. The app is written in Dart, runs on Android, iOS, web and desktop from the same codebase, and needs no binary asset uploads.

The project is developed in Visual Studio Code and is run and managed from Git Bash, using Flutter commands (`flutter pub get`, `flutter analyze`, `flutter test`, `flutter run`, `flutter build apk`) and Git commands to track and publish the source code to GitHub. The project shows how UI development, state management, cloud backend, charts, local persistence and version control can be learned together through a small but complete application.

**Key Words:** Flutter, Dart, Firebase Auth, Cloud Firestore, Riverpod, fl_chart, Personal Finance, Budget Tracking, AI Insights, Git Bash, GitHub, Cross-Platform.

---

## CONTENTS — p. ii

CONTENTS – Page no.
Abstract … i
List of Figures … iii
List of Abbreviations … iv
1. Introduction … 1
  1.1 Problem Definition … 1
  1.2 Objective of Project … 1
  1.3 Limitation of Project … 2
2. System Analysis … 3
  2.1 Existing System … 3
    2.1.1 Disadvantages … 3
    2.1.2 Proposed System … 3
    2.1.3 Advantages … 3
  2.2 Software Requirements … 3
    2.2.1 Functional and Non-Functional Requirements … 4
    2.2.2 Hardware Requirements … 4
  2.3 Content Diagram of the Project … 5
3. Implementation … 6
  3.1 Method of Implementation … 6
  3.2 Technologies Used … 6
  3.3 Algorithmic Approach … 6
  3.4 Explanation of Key Functions/Modules … 7
  3.5 Running the Project Using Git Bash … 8
  3.6 Version Control Using Git and GitHub … 9
  3.7 Source Code … 9
4. Output Screenshots … 15
  4.1 Splash + Onboarding … 15
  4.2 Dashboard … 15
  4.3 Transactions … 15
  4.4 Analytics (Charts) … 16
  4.5 Budgets … 16
  4.6 AI Insights … 16
  4.7 Running the Project in Git Bash … 17
  4.8 GitHub Repository … 17
5. Conclusion and Future Enhancement … 18
  5.1 Project Conclusion … 18
  5.2 Future Enhancement … 18
6. References … 19
  6.1 Paper References … 19
  6.2 Web References … 19

---

## LIST OF FIGURES — p. iii

| S.no | Figure no | Name of the Figure | Page no. |
|---|---|---|---|
| 1 | 2.3 | Content Diagram / App Flow of Project | 5 |
| 2 | 4.1 | Splash + Onboarding Screens | 15 |
| 3 | 4.2 | Dashboard Screen | 15 |
| 4 | 4.3 | Transactions Screen | 15 |
| 5 | 4.4 | Analytics Screen | 16 |
| 6 | 4.5 | Budgets Screen | 16 |
| 7 | 4.6 | AI Insights Screen | 16 |
| 8 | 4.7 | Running the Project in Git Bash | 17 |
| 9 | 4.8 | GitHub Repository | 17 |

## LIST OF ABBREVIATIONS — p. iv

| S.no | Abbreviation | Definition |
|---|---|---|
| 1 | API | Application Programming Interface |
| 2 | CPU | Central Processing Unit |
| 3 | GB | Gigabyte |
| 4 | IDE | Integrated Development Environment |
| 5 | RAM | Random Access Memory |
| 6 | SDK | Software Development Kit |
| 7 | UI | User Interface |
| 8 | VCS | Version Control System |
| 9 | URL | Uniform Resource Locator |
| 10 | LLM | Large Language Model |
| 11 | UPI | Unified Payments Interface |
| 12 | INR | Indian Rupee |

---

## 1. INTRODUCTION — p. 1

Personal finance apps are one of the best ways to learn app development because they combine UI, state management, cloud database, charts and user authentication in a single project. Among student projects, an expense tracker is a popular example. Its rules are easy to understand, yet building it well requires important software-engineering ideas such as data modelling, CRUD operations, aggregation, budget progress maths, navigation, theming and offline handling.

This project implements SpendWise AI using Flutter, Google's UI toolkit, Firebase Auth + Cloud Firestore for backend, Riverpod for state management, and fl_chart for analytics. Riverpod provides reactive data streams, so the UI rebuilds automatically when transactions or budgets change. Because Flutter code can be compiled for Android, iOS, web and desktop, the same app runs on a phone and in a browser without change.

The project is developed in Visual Studio Code. The app is run from Git Bash with Flutter commands, and the source code is tracked with Git and published to a GitHub repository. In this way the project demonstrates both app development and modern version-control practice.

### 1.1 Problem Definition

Beginners who want to learn full-stack app development often find it difficult because most tutorials cover only UI, with no real login, database or charts. Spreadsheets and notebook expense tracking are manual, error-prone and give no visual summary or warnings. In addition, many learners hard-code API keys, skip validation, and do not use version control, so their work is hard to track, share and recover. Therefore, there is a need for a small, complete and easy-to-understand finance app project that shows CRUD, authentication, budgets, charts and AI-style insights using a modern cross-platform framework and that is managed with Git and GitHub.

### 1.2 Objective of Project

The main objective is to design and develop a responsive, cross-platform personal finance app using Flutter, Firebase and Riverpod. The specific objectives are:

- To implement authentication – login, register (name/email/password), forgot password, logout via Firebase Auth with local demo fallback.
- To implement transaction CRUD with validation, search, filter by type + category, newest/oldest sort and delete confirmation.
- To implement overall monthly + per-category budgets with progress bars, near-limit warnings and exceeded state.
- To visualise spending – 6-month income-vs-expense bars, category pie, weekly trend, month picker using fl_chart.
- To provide AI insights – on-device rule analysis (highest category, month-over-month change, unusual spending, savings tips, budget warnings) with a swappable provider abstraction for a future LLM, honestly labelled as demo.
- To support light/dark mode, INR default currency, onboarding + splash with auth routing, and graceful local demo mode.
- To run the project from Git Bash and manage source code with Git and GitHub.

### 1.3 Limitation of Project — p. 2

- Without Firebase configuration the app runs in local demo mode; cloud sync and password-reset email require Firebase setup.
- The default AI is on-device rule analysis, not a real LLM; remote LLM requires endpoint + key via `--dart-define`.
- No Firebase Storage is used; no receipt image uploads.
- Single-user personal data model; no shared/family budgets or online leaderboard.
- Currency is display-only formatting (default INR); no live multi-currency conversion.
- The Flutter SDK, Git and an internet connection are required to set up and publish the project.

---

## 2. SYSTEM ANALYSIS — p. 3

### 2.1 Existing System

In the existing approach, expense tracking is done in spreadsheets, notes apps, or native bank apps that do not allow custom budgets and insights. Tutorial-grade tracker projects often lack login, use setState only, store data in memory, and have no charts or tests, so data is lost on restart and code is hard to extend.

#### 2.1.1 Disadvantages
- Manual tracking – no validation, aggregation or reminders.
- No backend – data lost on reinstall; no cross-device sync.
- No visual analytics – hard to see category or monthly trends.
- No budget warnings – overspending detected too late.
- Many student projects are not managed with version control or tests.

#### 2.1.2 Proposed System
The proposed system is SpendWise AI built with Flutter + Firebase + Riverpod. Auth, Firestore repositories with local fallback, fl_chart analytics, budget maths helpers, and an `AiInsightService` facade (RuleBased provider + Remote stub) provide a complete app in a clean feature-based folder structure. The same code runs on mobile, web and desktop. The project is run from Git Bash and versioned with Git and hosted on GitHub.

#### 2.1.3 Advantages
- Small, clean feature-based code that is easy to read, test and extend.
- Cross-platform: same Dart code runs on Android, iOS, web and desktop.
- Real backend when configured, graceful offline demo mode otherwise.
- Hot reload makes it fast to change and test UI.
- `flutter test` covers aggregation, budget flags and validators.
- Git and GitHub give complete history and easy sharing.

### 2.2 Software Requirements
Software requirements describe the programs that must be installed to develop and run the app:

- Flutter SDK (Flutter 3, Dart ^3.13.5) – framework to build UI and run the app.
- Dart – programming language for all app logic.
- Firebase project – Auth (Email/Password) + Cloud Firestore; `firestore.rules` in repo.
- Visual Studio Code – code editor with Flutter and Dart extensions.
- Git and Git Bash – terminal to run Flutter and Git commands.
- Android Studio / Chrome / Edge – to run and test (emulator or `flutter run -d chrome`).
- GitHub – online service to store and share source code.
- Operating System – Windows 10 or Windows 11.

#### 2.2.1 Functional and Non-Functional Requirements — p. 4

Functional requirements:
- App shows splash, then 3-slide onboarding (stored locally), then login/register.
- User can add/edit/delete income/expense with amount, category, date, note, payment method; validation blocks bad input.
- Transactions list supports search, type + category filter, newest/oldest sort.
- User can set Overall monthly + per-category budgets; progress bar shows remaining/near-limit/exceeded.
- Dashboard shows balance, month income/expense, budget remaining, quick add, recent transactions, spending summary, AI insight card.
- Analytics shows 6-month bars, category pie, weekly trend with month picker.
- AI Insights screen lists cards with tone (good/warn/danger/info) and honest source label.
- Profile allows currency, theme (system/light/dark), notifications toggle, demo-data loader, clear-data, logout.

Non-functional requirements:
- Performance – smooth scrolling, fast stream rebuilds, charts render without jank.
- Usability – Material 3, simple labels, friendly error messages instead of raw exceptions.
- Portability – same code runs on mobile, web and desktop.
- Maintainability – feature folders, Riverpod providers, repository abstraction.
- Reliability – no crash on repeated CRUD, logout/login, empty states handled.
- Security – per-user Firestore rules, no hard-coded keys, passwords only in Firebase Auth.

#### 2.2.2 Hardware Requirements
- Processor – Intel i3 or above
- RAM – Minimum 4 GB (8 GB recommended)
- Storage – At least 10 GB free for Flutter SDK and project
- System – Desktop or Laptop
- Input Devices – Keyboard and Mouse; Android device/emulator optional

### 2.3 Content Diagram of the Project — p. 5

The content diagram is an extension of UML notation. Its purpose is to represent the structure of the project and relations between its parts. The diagram below shows the flow from launch to auth to main features to logout.

```
Start
 ↓
Open project in Git Bash (flutter pub get / flutter run)
 ↓
Splash (auth routing + Firebase bootstrap / demo mode)
 ↓
Onboarding shown? No → Auth (Login/Register/Forgot) → MainShell
                  Yes → show 3 slides → Auth → MainShell
 ↓
MainShell (bottom nav):
 Dashboard ↔ Transactions ↔ Analytics ↔ Budgets ↔ Insights ↔ Profile
 ↓                                    ↓
Firestore (users/{uid}/transactions, budgets) OR local JSON (demo)
 ↓
Logout → back to Login. Quit (q in terminal / close app) → End
```

Fig 2.3: Content Diagram of Project

---

## 3. IMPLEMENTATION — p. 6

### 3.1 Method of Implementation
The project is implemented step by step. First, the environment is prepared by installing VS Code, Flutter SDK, Git and Chrome. A Flutter project named `spendwise_ai` is created and packages (`flutter_riverpod, firebase_core, firebase_auth, cloud_firestore, fl_chart, shared_preferences, intl, uuid, http`) are added to `pubspec.yaml`. The app is then designed with models, services, providers, features and routes. After each feature (auth → dashboard → transactions → budgets → analytics → insights → profile) the app is run with `flutter run` and tested. `flutter analyze` and `flutter test` are run for quality. Finally the project is committed with Git and pushed to GitHub.

### 3.2 Technologies Used
- Flutter (Material 3) – builds UI and compiles for mobile/web/desktop.
- Dart – all app logic.
- flutter_riverpod ^2.6.1 – state management consistently throughout.
- Firebase Auth ^5.7.0 + Cloud Firestore ^5.6.12 + firebase_core – login and per-user cloud data.
- fl_chart ^0.69.0 – bar, pie and trend charts.
- shared_preferences ^2.5.3 – onboarding, theme, currency, local-mode data.
- intl ^0.20.2 – currency/date formatting; uuid ^4.5.1 – IDs; http ^1.2.2 – future remote AI only.
- Visual Studio Code, Git Bash, Git + GitHub, Chrome/Android emulator.

### 3.3 Algorithmic Approach
1. Start.
2. Open project folder in Git Bash; run `flutter pub get`.
3. Run `flutter run` (or `-d chrome`); Splash bootstraps LocalPrefs + Firebase (or demo mode).
4. If onboarding not seen, show 3 slides and persist flag.
5. Auth routing: if logged in → MainShell else Login/Register.
6. Dashboard aggregates current-month transactions: income, expense, balance, budget remaining.
7. Add transaction: validate (email/amount/password/name), write to Firestore or local store.
8. Budgets: for each budget compute spent, progress = spent/amount, flags near-limit/over.
9. Analytics: bucket last 6 months income vs expense, category totals, weekly sums.
10. AI Insights: RuleBasedInsightProvider analyses month + previous month, emits cards.
11. Profile changes persist theme/currency; demo-data loader inserts sample tx/budgets; logout clears session.
12. Press q to quit; End.

### 3.4 Explanation of Key Functions/Modules — p. 7

App states: Splash (loading/routing), Onboarding (first-run), Authenticated vs Guest, MainShell tabs, plus loading/empty/error states per screen.

- `main.dart` – `_tryInitFirebase()` tries `Firebase.initializeApp()` and returns bool; `main()` loads LocalPrefs, overrides providers, runs `SpendWiseApp` (ConsumerWidget watching settings for themeMode, route table).
- `models/transaction_model.dart` – TransactionModel (id, type income/expense, amount, category, date, note, paymentMethod) + `TransactionStats` helpers (inMonth, totalIncome/Expense, expenseByCategory).
- `models/budget_model.dart` – BudgetModel (category, amount, month yyyy-MM, isOverall) + `BudgetProgress` (progress, remaining, isNearLimit, isOver with clamping).
- `services/auth_service.dart` – Firebase Auth wrapper with local demo fallback.
- `services/repositories.dart` – repository abstraction: Firestore when configured else local JSON persistence.
- `services/ai_insights.dart` – `AiInsight`, `InsightResult`, `AiInsightProvider`, `RuleBasedInsightProvider.analyze()`, `RemoteAiInsightProvider` (dart-define key/endpoint stub), `AiInsightService.getInsights()`, `DemoDataService.sample()`.
- `providers/app_providers.dart` – localPrefsProvider, firebaseAvailableProvider, settingsProvider, auth stream, transaction/budget streams.
- `features/*` – splash, onboarding, auth_screens, dashboard_screen, transactions_screen + add_edit_transaction, analytics_screen, budgets_screen, insights_screen, profile_screen.
- `core/` – AppTheme.light/dark, validators (email/amount/password/name), Format.money/date/monthLabel, common_widgets.
- `routes/main_shell.dart` – bottom nav + `buildRoutes()`.

Table 3.1: Key Data Parameters

| Parameter | Value / Format | Purpose |
|---|---|---|
| Transaction amount | double, > 0 validated | Income/expense value |
| Transaction type | income \| expense | Aggregation split |
| Budget month | yyyy-MM | Monthly scoping |
| Overall budget category | "Overall" | Monthly total limit |
| Progress | spent / amount, clamped | Progress bar |
| Near-limit | e.g. >= 80% | Warning state |
| Over-budget | spent > amount | Exceeded state |
| Currency default | INR ₹ | Formatting |
| Demo AI label | On-device analysis (demo) | Honest sourcing |
| Remote AI keys | SPENDWISE_AI_KEY / ENDPOINT via dart-define | Never hard-coded |

### 3.5 Running the Project Using Git Bash — p. 8

1. Open Git Bash and go to project folder:
```
cd /c/Users/Shre0/OneDrive/Desktop/flutter
pwd
ls
```
2. Check Flutter (optional):
```
flutter doctor
flutter devices
```
3. Get packages:
```
flutter pub get
```
4. Quality gates:
```
flutter analyze
flutter test
```
5. Run (default device, or Chrome):
```
flutter run
flutter run -d chrome
```
6. While running: `r` hot reload, `R` hot restart, `q` quit.
7. Build APK:
```
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

Firebase one-time setup: create project at console.firebase.google.com, add Android app `com.spendwise.spendwise_ai` with google-services.json → `android/app/`, enable Email/Password auth, create Firestore and deploy `firestore.rules`, optionally run `flutterfire configure` (generates git-ignored `lib/firebase_options.dart`).

### 3.6 Version Control Using Git and GitHub — p. 9

One-time config:
```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```
First publish (inside project folder):
```
git init
git add .
git commit -m "Initial commit: SpendWise AI"
git branch -M main
git remote add origin https://github.com/<user>/spendwise_ai.git
git push -u origin main
```
Later changes:
```
git status
git add .
git commit -m "Describe the change"
git push
```
`git status` shows changes; `git log --oneline` shows history. `.gitignore` excludes build folders, Firebase options and secrets.

### 3.7 Source Code — pp. 9-14 (abridged; full code in repo)

pubspec.yaml (actual):
```yaml
name: spendwise_ai
description: "SpendWise AI — personal finance, budgeting and AI-powered spending insights."
publish_to: 'none'
version: 1.0.0+1
environment:
  sdk: ^3.13.5
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.6.1
  firebase_core: ^3.15.2
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.6.12
  fl_chart: ^0.69.0
  shared_preferences: ^2.5.3
  intl: ^0.20.2
  uuid: ^4.5.1
  http: ^1.2.2
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
flutter:
  uses-material-design: true
```

lib/main.dart – see actual file (82 lines, Firebase graceful bootstrap + ProviderScope overrides + MaterialApp routes). Include verbatim in final Word/PDF.

Key excerpt – services/ai_insights.dart facade:
```dart
class AiInsightService {
  final RemoteAiInsightProvider _remote = RemoteAiInsightProvider();
  final AiInsightProvider _local = RuleBasedInsightProvider();
  bool get usesRemote => _remote.isConfigured;
  Future<InsightResult> getInsights({required transactions, required budgets,
    required currencyCode, String? monthKey}) { ... }
}
```

Firestore data model (also in README):
```
users/{uid} : name, email, currency, createdAt
  transactions/{txId} : type, amount, category, date, note, paymentMethod, createdAt, updatedAt
  budgets/{budgetId} : category ("Overall" = total), amount, month "yyyy-MM", createdAt, updatedAt
```
See `firestore.rules` for per-user isolation. Full feature files under `lib/features/*`, `lib/models/*`, `lib/providers/*`, `lib/core/*` are part of submission – paste or link from GitHub in appendix to keep page count.

---

## 4. OUTPUT SCREENSHOTS — pp. 15-17

### 4.1 Splash + Onboarding
Animated splash with auth routing; 3-slide onboarding stored locally.
Fig 4.1: Splash + Onboarding (capture `splash.png`, `onboarding.png`)

### 4.2 Dashboard
Balance, month income/expense, budget remaining, quick add, recent transactions, spending summary, AI insight card.
Fig 4.2: Dashboard Screen

### 4.3 Transactions
History with search, type + category filter, newest/oldest sort, add/edit/delete with validation and delete confirmation.
Fig 4.3: Transactions Screen

### 4.4 Analytics
6-month income-vs-expense bars, category pie, weekly trend, month picker (fl_chart).
Fig 4.4: Analytics Screen

### 4.5 Budgets
Overall monthly + per-category budgets, progress bars, near-limit warnings, exceeded state.
Fig 4.5: Budgets Screen

### 4.6 AI Insights
Cards: highest category, MoM change, unusual spending, savings tips, budget warnings; header label "Demo insights · On-device analysis (demo)".
Fig 4.6: AI Insights Screen

### 4.7 Running the Project in Git Bash
`flutter pub get` → `flutter test` → `flutter run -d chrome`, device list, hot reload keys.
Fig 4.7: Running the Project in Git Bash (paste terminal screenshot)

### 4.8 GitHub Repository
File list (`lib/`, `firestore.rules`, `pubspec.yaml`), commits, README rendered.
Fig 4.8: GitHub Repository

---

## 5. CONCLUSION AND FUTURE ENHANCEMENT — p. 18

### 5.1 Project Conclusion
SpendWise AI successfully provides a complete, clean and easy-to-use personal finance app. It demonstrates auth, CRUD, budgets, charts, AI-style insights and theming through a maintainable feature-based Riverpod design. The app runs from the same code on mobile, web and desktop, works immediately in local demo mode, and syncs via Firebase when configured. The project also shows a practical workflow – run from Git Bash, quality-checked with analyze/test, tracked with Git/GitHub. Overall it shows how a small finance app teaches UI, state, backend and version control together.

### 5.2 Future Enhancement
Real LLM provider (Gemini/OpenAI) with streaming + caching via Cloud Functions; push notifications for bill/budget alerts; recurring transactions, CSV export, savings goals; biometric lock, multi-currency conversion, widgets/i18n; automated widget/golden tests and GitHub Pages/web deployment from a link; Play Store appbundle release.

---

## 6. REFERENCES — p. 19

### 6.1 Paper References
[1] Roger S. Pressman, Software Engineering: A Practitioner's Approach, McGraw-Hill Education.
[2] Ian Sommerville, Software Engineering, Pearson Education.
[3] Eric Windmill, Flutter in Action, Manning Publications.
[4] Scott Chacon and Ben Straub, Pro Git, Apress.
[5] Chris Buckett, Dart in Action, Manning Publications.

### 6.2 Web References
1. https://docs.flutter.dev
2. https://dart.dev
3. https://firebase.google.com/docs
4. https://riverpod.dev
5. https://pub.dev/packages/fl_chart
6. https://git-scm.com/doc
7. https://docs.github.com
8. https://code.visualstudio.com/docs

---

## HOW TO USE THIS FILE
1. Copy sections into Word using your college template (Times New Roman, justified, page numbers i,ii,iii,iv,1-19 as in reference).
2. Replace Fig 2.3 / 4.1-4.8 placeholders with actual screenshots: run app, press PrintScreen on each screen + Git Bash + GitHub page.
3. For §3.7 paste full `lib/main.dart` + `pubspec.yaml` verbatim (already above); attach remaining files as appendix or GitHub link to keep page count ~19-25.
4. Update GitHub URL from placeholder to your actual repo URL before printing.
