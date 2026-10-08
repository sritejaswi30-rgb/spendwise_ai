/// Field validators shared by auth + transaction forms.
class Validators {
  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password';
    if (v.length < minLength) return 'Minimum $minLength characters';
    return null;
  }

  static String? amount(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter an amount';
    final parsed = double.tryParse(v.replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Amount must be greater than 0';
    if (parsed > 1000000000) return 'Amount is unrealistically large';
    return null;
  }

  static String? required(String? value, String field) {
    if ((value?.trim() ?? '').isEmpty) return 'Please select $field';
    return null;
  }

  static String? budgetAmount(String? value) => amount(value);
}

/// Pure helpers used by validators/tests and budget math.
class FinanceMath {
  /// Parses user-entered amounts such as "1,250.50".
  static double? parseAmount(String input) {
    return double.tryParse(input.replaceAll(',', '').trim());
  }

  /// 0.0 - 1.0 progress of [spent] against [budget], clamped.
  /// Returns 0 when budget <= 0.
  static double budgetProgress(double spent, double budget) {
    if (budget <= 0) return 0;
    return (spent / budget).clamp(0.0, 1.0);
  }

  static bool isOverBudget(double spent, double budget) => spent > budget;

  static bool isNearLimit(double spent, double budget, {double threshold = 0.8}) {
    if (budget <= 0) return false;
    return spent >= budget * threshold && spent <= budget;
  }
}
