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

  /// Derives a representative [DateTime] for a period key.
  ///
  /// - Monthly "YYYY-MM" → first day of that month
  /// - Monthly "YYYY-MM-extra" → first day of that month (same day as regular)
  /// - Annual "YYYY" → January 1 of that year
  static DateTime _dateForPeriod(
      String periodKey, RecurringTemplateRow template) {
    if (periodKey.endsWith('-extra')) {
      final base = periodKey.replaceAll('-extra', '');
      final parts = base.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    }
    final parts = periodKey.split('-');
    if (parts.length == 1) {
      // Annual
      return DateTime(int.parse(parts[0]), 1, 1);
    }
    // Monthly
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }
}
