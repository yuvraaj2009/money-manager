import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String currencyFromPaise(int paise, {bool compactSign = false}) {
    final value = paise / 100;
    final formatted = _currency.format(value.abs());
    if (!compactSign) {
      return paise < 0 ? '-$formatted' : formatted;
    }
    if (paise > 0) {
      return '+$formatted';
    }
    if (paise < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  static String shortDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  static String detailDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy - hh:mm a').format(date);
  }

  static String monthLabel(int month) {
    return DateFormat('MMM').format(DateTime(2000, month));
  }

  static Color colorFromHex(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = normalized.length == 6 ? 'FF$normalized' : normalized;
    return Color(int.parse(value, radix: 16));
  }
}

