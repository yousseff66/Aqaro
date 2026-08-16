import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCurrency(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  static String formatNumber(num number) {
    final formatter = NumberFormat('#,###.#', 'en_US');
    return formatter.format(number);
  }
}
