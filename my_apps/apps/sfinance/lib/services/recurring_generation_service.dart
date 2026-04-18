import 'package:drift/drift.dart' show Value;
import 'package:shared_services/shared_services.dart';

/// Generates recurring transaction entries for all active templates.
///
/// Called once on app startup (before first frame). For each non-deleted
/// template, computes due period keys and inserts one Transaction per key,
/// updating `lastGeneratedPeriod` atomically after each insertion.
class RecurringGenerationService {
  RecurringGenerationService._();

  /// Runs the generation cycle for all active (non-deleted) templates.
  ///
  /// [today] is injectable for testing; defaults to [DateTime.now()].
  static Future<void> run(AppDatabase db, {DateTime? today}) async {
    final now = today ?? DateTime.now();

    final templates = await db.select(db.recurringTemplates).get();
    final activeTemplates = templates.where((t) => !t.isDeleted).toList();

    for (final template in activeTemplates) {
      await generateForTemplate(db, template, today: now);
    }
  }

  /// Generates all due transaction entries for a single [template].
  ///
  /// Computes due period keys via [PeriodGenerator] (which applies both
  /// month-level and day-level filtering), then inserts one Transaction per
  /// due key, advancing `lastGeneratedPeriod` after each insertion
  /// (crash-safe: any unprocessed keys are retried on next launch).
  ///
  /// [today] is injectable for testing; defaults to [DateTime.now()].
  static Future<void> generateForTemplate(
    AppDatabase db,
    RecurringTemplateRow template, {
    DateTime? today,
  }) async {
    final now = today ?? DateTime.now();
    final extraMonths = _extraMonthsFor(template);

    final dueKeys = PeriodGenerator.computeDueKeys(
      startDate: template.startDate,
      endDate: template.endDate,
      periodicity: template.periodicity,
      lastGeneratedPeriod: template.lastGeneratedPeriod,
      extraPayMonths: extraMonths,
      paymentDay: template.paymentDay ?? 1,
      today: now,
    );

    for (final periodKey in dueKeys) {
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              name: template.name,
              amountCents: template.amountCents,
              transactionType: template.transactionType,
              category: template.category,
              date: PeriodGenerator.dateForKey(
                periodKey,
                template.paymentDay ?? 1,
                // annualMonth: endDate month (null-safe; annual templates always
                // have an endDate — open-ended is only for Suscripción/mensual).
                annualMonth: template.endDate?.month,
              ),
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

  static List<int> _extraMonthsFor(RecurringTemplateRow template) {
    final months = <int>[];
    if (template.extraPayMonth1 != null) months.add(template.extraPayMonth1!);
    if (template.extraPayMonth2 != null) months.add(template.extraPayMonth2!);
    return months;
  }
}
