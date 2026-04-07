import 'package:intl/intl.dart';

/// Formats integer cent values to locale-aware EUR currency strings.
///
/// Always produces explicit +/− sign and € symbol.
/// Spanish locale: comma decimal separator, period thousands separator.
class CurrencyFormatter {
  CurrencyFormatter._();

  // Format the number with Spanish separators (comma decimal, period thousands).
  // We prepend '€' manually so the symbol is always before the number,
  // regardless of what the CLDR locale data specifies for es_ES.
  static final NumberFormat _spanishFormat = NumberFormat('#,##0.00', 'es_ES');

  /// Formats [amountCents] with explicit sign.
  ///
  /// Income: "+€X,XX" (green in UI)
  /// Expense: "−€X,XX" (red in UI; uses proper minus sign U+2212)
  static String format(int amountCents, {required bool isIncome}) {
    final amount = amountCents / 100.0;
    final formatted = '€${_spanishFormat.format(amount.abs())}';
    return isIncome ? '+$formatted' : '\u2212$formatted';
  }

  /// Formats [amountCents] without a sign prefix.
  ///
  /// Used for neutral displays (e.g. Balance KPI card, initial capital editor).
  static String formatUnsigned(int amountCents) {
    final amount = amountCents / 100.0;
    return '€${_spanishFormat.format(amount.abs())}';
  }
}
