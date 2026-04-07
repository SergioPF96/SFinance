/// Computes ordered period keys due for generation for a recurring template.
///
/// Pure computation — no database calls. Takes template parameters and returns
/// the list of period keys that have not yet been generated.
class PeriodGenerator {
  /// Returns ordered list of period keys due between [startDate] and
  /// min([today], [endDate]), excluding keys already generated
  /// (i.e. keys <= [lastGeneratedPeriod]).
  ///
  /// [today] defaults to [DateTime.now()] if not provided (injectable for testing).
  ///
  /// Period key formats:
  /// - Monthly: "YYYY-MM"
  /// - Annual: "YYYY"
  /// - 14-paga extra: "YYYY-MM-extra"
  static List<String> computeDueKeys({
    required DateTime startDate,
    required DateTime endDate,
    required String periodicity,
    String? lastGeneratedPeriod,
    List<int>? extraPayMonths,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    // Cap the upper bound at min(today, endDate)
    final upperBound = endDate.isBefore(now) ? endDate : now;

    final allKeys = _generateAllKeys(
      startDate: startDate,
      upperBound: upperBound,
      periodicity: periodicity,
      extraPayMonths: extraPayMonths ?? [],
    );

    if (lastGeneratedPeriod == null) return allKeys;

    // Filter out keys that are <= lastGeneratedPeriod lexicographically.
    // Period key format ensures correct lexicographic ordering:
    //   "2026-07" < "2026-07-extra" < "2026-08" < "2026" (annual)
    return allKeys
        .where((key) => _compareKeys(key, lastGeneratedPeriod) > 0)
        .toList();
  }

  static List<String> _generateAllKeys({
    required DateTime startDate,
    required DateTime upperBound,
    required String periodicity,
    required List<int> extraPayMonths,
  }) {
    final keys = <String>[];

    if (periodicity == 'anual') {
      final startYear = startDate.year;
      final endYear = upperBound.year;
      for (var year = startYear; year <= endYear; year++) {
        keys.add('$year');
      }
    } else {
      // mensual
      var current = DateTime(startDate.year, startDate.month);
      final end = DateTime(upperBound.year, upperBound.month);

      while (!current.isAfter(end)) {
        final key = _monthKey(current);
        keys.add(key);

        if (extraPayMonths.contains(current.month)) {
          keys.add('$key-extra');
        }

        // Advance to next month
        current = DateTime(current.year, current.month + 1);
      }
    }

    return keys;
  }

  static String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  /// Compares two period keys. Returns negative if [a] < [b], 0 if equal,
  /// positive if [a] > [b].
  ///
  /// Monthly keys ("YYYY-MM") sort before the same-month extra ("YYYY-MM-extra"),
  /// which sorts before the next month. Annual keys ("YYYY") sort correctly
  /// by year. Mixed monthly/annual keys are not expected in the same template.
  static int _compareKeys(String a, String b) {
    // Normalize: "YYYY-MM-extra" > "YYYY-MM" for same YYYY-MM.
    // We can rely on simple string comparison because:
    //   "2026-07" < "2026-07-extra" (lexicographically true since '-' < 'e')
    //   "2026-07-extra" < "2026-08"  (lexicographically true)
    //   "2026" < "2026-01"           (lexicographically true)
    return a.compareTo(b);
  }
}
