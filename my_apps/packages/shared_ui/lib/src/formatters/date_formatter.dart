import 'package:intl/intl.dart';

/// Formats [DateTime] values to unambiguous display strings.
///
/// Uses Spanish locale for month abbreviations.
/// Example: "6 abr. 2026"
class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('d MMM y', 'es_ES');

  /// Returns a human-readable, unambiguous date string.
  ///
  /// Example: "6 abr. 2026"
  static String format(DateTime date) => _displayFormat.format(date);
}
