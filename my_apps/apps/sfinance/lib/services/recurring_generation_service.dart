import 'package:drift/drift.dart' show Value;
import 'package:shared_services/shared_services.dart';

/// Generates recurring transaction entries for all active templates.
///
/// Called once on app startup (before first frame). For each non-deleted
/// template, computes due period keys and inserts one Transaction per key,
/// updating `lastGeneratedPeriod` atomically after each insertion.
class RecurringGenerationService {
  RecurringGenerationService._();

  /// Runs the generation cycle.
  ///
  /// [today] is injectable for testing; defaults to [DateTime.now()].
  static Future<void> run(AppDatabase db, {DateTime? today}) async {
    final now = today ?? DateTime.now();

    final templates = await db.select(db.recurringTemplates).get();
    final activeTemplates =
        templates.where((t) => !t.isDeleted).toList();

    for (final template in activeTemplates) {
      final extraMonths = _extraMonthsFor(template);

      final dueKeys = PeriodGenerator.computeDueKeys(
        startDate: template.startDate,
        endDate: template.endDate,
        periodicity: template.periodicity,
        lastGeneratedPeriod: template.lastGeneratedPeriod,
        extraPayMonths: extraMonths,
        today: now,
      );

      for (final periodKey in dueKeys) {
        await db.into(db.transactions).insert(
              TransactionsCompanion.insert(
                name: template.name,
                amountCents: template.amountCents,
                transactionType: template.transactionType,
                category: template.category,
                date: _dateForPeriod(periodKey, template),
                templateId: Value(template.id),
              ),
            );

        // Advance high-water mark immediately (crash-safe: retry on next launch)
        await (db.update(db.recurringTemplates)
              ..where((t) => t.id.equals(template.id)))
            .write(
          RecurringTemplatesCompanion(
            lastGeneratedPeriod: Value(periodKey),
          ),
        );
      }
    }
  }

  static List<int> _extraMonthsFor(RecurringTemplateRow template) {
    final months = <int>[];
    if (template.extraPayMonth1 != null) months.add(template.extraPayMonth1!);
    if (template.extraPayMonth2 != null) months.add(template.extraPayMonth2!);
    return months;
  }

  /// Number of days in a given [month] of [year].
  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Derives a [DateTime] for a period key, using [template.paymentDay] for
  /// the day within the month.
  ///
  /// - Monthly "YYYY-MM" → paymentDay of that month (clamped to month length)
  /// - Monthly "YYYY-MM-extra" → same day as the regular monthly occurrence
  /// - Annual "YYYY" → paymentDay of template.endDate.month in that year
  static DateTime _dateForPeriod(
      String periodKey, RecurringTemplateRow template) {
    final paymentDay = template.paymentDay ?? 1;

    if (periodKey.endsWith('-extra')) {
      final base = periodKey.replaceAll('-extra', '');
      final parts = base.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = paymentDay.clamp(1, _daysInMonth(year, month));
      return DateTime(year, month, day);
    }

    final parts = periodKey.split('-');
    if (parts.length == 1) {
      // Annual — use template.endDate.month for the month
      final year = int.parse(parts[0]);
      final month = template.endDate.month;
      final day = paymentDay.clamp(1, _daysInMonth(year, month));
      return DateTime(year, month, day);
    }

    // Monthly
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = paymentDay.clamp(1, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }
}
