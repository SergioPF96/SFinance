import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/recurring_templates.dart';

part 'template_dao.g.dart';

@DriftAccessor(tables: [RecurringTemplates])
class TemplateDao extends DatabaseAccessor<AppDatabase>
    with _$TemplateDaoMixin {
  TemplateDao(super.db);

  Future<int> insert(RecurringTemplatesCompanion entry) =>
      into(recurringTemplates).insert(entry);

  /// All non-deleted templates.
  Stream<List<RecurringTemplateRow>> watchActive() {
    return (select(recurringTemplates)
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  /// Soft-deletes a template by setting isDeleted=true. Past generated
  /// transactions are unaffected.
  Future<void> softDelete(int id) async {
    await (update(recurringTemplates)..where((t) => t.id.equals(id))).write(
      const RecurringTemplatesCompanion(isDeleted: Value(true)),
    );
  }

  /// Advances the high-water mark after generating entries for a period.
  Future<void> updateLastGeneratedPeriod(int id, String periodKey) async {
    await (update(recurringTemplates)..where((t) => t.id.equals(id))).write(
      RecurringTemplatesCompanion(lastGeneratedPeriod: Value(periodKey)),
    );
  }
}
