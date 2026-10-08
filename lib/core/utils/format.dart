import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Currency + date formatting helpers.
class Format {
  static String symbolFor(String code) =>
      AppConstants.currencies[code] ?? code;

  static String money(double value, String currencyCode) {
    final symbol = symbolFor(currencyCode);
    final fmt = NumberFormat.currency(
      symbol: '$symbol ',
      decimalDigits: value % 1 == 0 ? 0 : 2,
    );
    return fmt.format(value);
  }

  static String date(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  static String dateTime(DateTime d) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(d);

  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static String monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    if (m < 1 || m > 12) return key;
    return '${months[m]} ${parts[0]}';
  }

  static String currentMonthKey() => monthKey(DateTime.now());

  static String previousMonthKey(DateTime from) {
    final prev = DateTime(from.year, from.month - 1, 1);
    return monthKey(prev);
  }
}
