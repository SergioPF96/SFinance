import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  group('QuickExpense model invariants', () {
    test('constructs with all required fields', () {
      final qe = QuickExpense(
        id: 1,
        name: 'Café',
        amountCents: 150,
        category: ExpenseCategory.producto,
        imagePath: null,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(qe.id, 1);
      expect(qe.name, 'Café');
      expect(qe.amountCents, 150);
      expect(qe.category, ExpenseCategory.producto);
      expect(qe.imagePath, isNull);
      expect(qe.createdAt, DateTime(2026, 1, 1));
    });

    test('accepts non-null imagePath', () {
      final qe = QuickExpense(
        id: 2,
        name: 'Spotify',
        amountCents: 999,
        category: ExpenseCategory.suscripcion,
        imagePath: '/data/quick_expense_images/2_1714400000000.png',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(qe.imagePath, isNotNull);
    });

    test('name is stored as provided (not trimmed by model)', () {
      final qe = QuickExpense(
        id: 3,
        name: '  Café  ',
        amountCents: 150,
        category: ExpenseCategory.producto,
        imagePath: null,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(qe.name, '  Café  ');
    });

    test('amountCents is stored as-is (positive)', () {
      final qe = QuickExpense(
        id: 4,
        name: 'Gym',
        amountCents: 3500,
        category: ExpenseCategory.servicio,
        imagePath: null,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(qe.amountCents, 3500);
      expect(qe.amountCents, greaterThan(0));
    });

    test('category can be any ExpenseCategory value', () {
      for (final cat in ExpenseCategory.values) {
        final qe = QuickExpense(
          id: 1,
          name: 'Test',
          amountCents: 100,
          category: cat,
          imagePath: null,
          createdAt: DateTime(2026, 1, 1),
        );
        expect(qe.category, cat);
      }
    });
  });
}
