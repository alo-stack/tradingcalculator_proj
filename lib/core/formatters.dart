import 'package:intl/intl.dart';

/// Number formatting utilities for QuickPips
class AppFormatters {
  /// Format as currency (e.g., $1,234.56)
  static String currency(double value, {String symbol = '\$', int decimalDigits = 2}) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(value);
  }

  /// Format as percentage (e.g., 12.34%)
  static String percentage(double value, {int decimalDigits = 2}) {
    return NumberFormat.percentPattern().format(value / 100);
  }

  /// Format large numbers compactly (e.g., 1.2M, 34K)
  static String compact(double value) {
    return NumberFormat.compact().format(value);
  }

  /// Format with thousands separator (e.g., 1,234.56)
  static String decimal(double value, {int decimalDigits = 2}) {
    return NumberFormat('#,##0.${'0' * decimalDigits}').format(value);
  }

  /// Format with custom precision
  static String precision(double value, int decimalDigits) {
    return NumberFormat('#,##0.${'0' * decimalDigits}').format(value);
  }

  /// Format currency with symbol
  static String currencyWithSymbol(double value, String symbol, {int decimalDigits = 2}) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(value);
  }
}
