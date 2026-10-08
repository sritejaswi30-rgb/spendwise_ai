/// App-wide constants: categories, currencies, prefs keys.
class AppConstants {
  static const appName = 'SpendWise AI';

  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Education',
    'Entertainment',
    'Bills',
    'Health',
    'Travel',
    'Other',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Allowance',
    'Scholarship',
    'Other',
  ];

  static const List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Bank Transfer',
    'Wallet',
    'Other',
  ];

  /// Currency code -> symbol.
  static const Map<String, String> currencies = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  static const defaultCurrency = 'INR';

  // SharedPreferences keys.
  static const keyOnboardingDone = 'onboarding_done';
  static const keyThemeMode = 'theme_mode'; // system | light | dark
  static const keyCurrency = 'currency_code';
  static const keyNotifications = 'notifications_enabled';
  static const keyDemoUserId = 'demo_user_id';
  static const keyDemoUserName = 'demo_user_name';
  static const keyDemoUserEmail = 'demo_user_email';
  static const keyLocalTxPrefix = 'local_tx_'; // + uid
  static const keyLocalBudgetPrefix = 'local_budgets_'; // + uid
}
