import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

// Canonical fixture companion (no image).
const _cafe = QuickExpensesCompanion(
  name: Value('Café'),
  amountCents: Value(150),
  category: Value('producto'),
);

void main() {
  group('QuickExpenseDao', () {
    late AppDatabase db;
    late QuickExpenseDao dao;

    setUp(() {
      db = _makeDb();
      dao = db.quickExpenseDao;
    });

    tearDown(() => db.close());

    // --- insert ---

    test('insert returns a positive generated id', () async {
      final id = await dao.insert(_cafe);
      expect(id, greaterThan(0));
    });

    test('inserted row appears in watchAll stream', () async {
      await dao.insert(_cafe);
      final rows = await dao.watchAll().first;
      expect(rows.length, 1);
      expect(rows.first.name, 'Café');
      expect(rows.first.amountCents, 150);
      expect(rows.first.category, 'producto');
      expect(rows.first.imagePath, isNull);
    });

    // --- findById ---

    test('findById returns the row for a known id', () async {
      final id = await dao.insert(_cafe);
      final row = await dao.findById(id);
      expect(row, isNotNull);
      expect(row!.name, 'Café');
    });

    test('findById returns null for an unknown id', () async {
      final row = await dao.findById(999);
      expect(row, isNull);
    });

    // --- update ---

    test('update changes all provided fields', () async {
      final id = await dao.insert(_cafe);
      await dao.updateById(
        id,
        QuickExpensesCompanion(
          name: const Value('Café Doble'),
          amountCents: const Value(300),
          category: const Value('servicio'),
          imagePath: const Value('/images/1_abc.jpg'),
        ),
      );
      final row = await dao.findById(id);
      expect(row!.name, 'Café Doble');
      expect(row.amountCents, 300);
      expect(row.category, 'servicio');
      expect(row.imagePath, '/images/1_abc.jpg');
    });

    test('update with imagePath Value(null) clears the image', () async {
      final id = await dao.insert(
        const QuickExpensesCompanion(
          name: Value('Spotify'),
          amountCents: Value(999),
          category: Value('suscripcion'),
          imagePath: Value('/images/2_abc.png'),
        ),
      );

      await dao.updateById(id, const QuickExpensesCompanion(imagePath: Value(null)));
      final row = await dao.findById(id);
      expect(row!.imagePath, isNull);
    });

    // --- deleteById ---

    test('deleteById removes the row from the next stream emit', () async {
      final id = await dao.insert(_cafe);
      await dao.deleteById(id);
      final rows = await dao.watchAll().first;
      expect(rows, isEmpty);
    });

    test('deleteById returns 1 for an existing row', () async {
      final id = await dao.insert(_cafe);
      final affected = await dao.deleteById(id);
      expect(affected, 1);
    });

    test('deleteById returns 0 for a non-existent id', () async {
      final affected = await dao.deleteById(999);
      expect(affected, 0);
    });

    // --- watchAll ordering ---

    test('watchAll returns rows in createdAt ASC order', () async {
      await dao.insert(const QuickExpensesCompanion(
        name: Value('First'),
        amountCents: Value(100),
        category: Value('producto'),
      ));
      // Small delay to ensure different timestamps
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await dao.insert(const QuickExpensesCompanion(
        name: Value('Second'),
        amountCents: Value(200),
        category: Value('servicio'),
      ));

      final rows = await dao.watchAll().first;
      expect(rows.length, 2);
      expect(rows[0].name, 'First');
      expect(rows[1].name, 'Second');
      expect(
        rows[0].createdAt.isBefore(rows[1].createdAt) ||
            rows[0].createdAt.isAtSameMomentAs(rows[1].createdAt),
        isTrue,
      );
    });

    test('watchAll re-emits after an insert', () async {
      final stream = dao.watchAll();

      await dao.insert(_cafe);
      await dao.insert(const QuickExpensesCompanion(
        name: Value('Spotify'),
        amountCents: Value(999),
        category: Value('suscripcion'),
      ));

      final rows = await stream.first;
      expect(rows.length, 2);
    });
  });
}
