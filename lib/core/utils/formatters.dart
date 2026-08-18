import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  static bool isRTL(BuildContext context) {
    // هذه الطريقة أكثر أماناً وتجنبنا مشاكل التعارض في الإصدارات
    final languageCode = Localizations.localeOf(context).languageCode;
    return Bidi.isRtlLanguage(languageCode);
  }

  static String formatCurrency(num amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  static String formatNumber(num number) {
    final formatter = NumberFormat('#,###.#', 'en_US');
    return formatter.format(number);
  }
}
