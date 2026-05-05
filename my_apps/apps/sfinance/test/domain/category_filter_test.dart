import 'package:flutter_test/flutter_test.dart';
import 'package:sfinance/domain/category_filter.dart';

void main() {
  group('CategoryFilter.matches', () {
    test('all matches any category', () {
      expect(CategoryFilter.all.matches('suscripcion'), isTrue);
      expect(CategoryFilter.all.matches('producto'), isTrue);
      expect(CategoryFilter.all.matches('financiacion'), isTrue);
      expect(CategoryFilter.all.matches('salario'), isTrue);
      expect(CategoryFilter.all.matches(''), isTrue);
    });

    test('specific filter matches its own name', () {
      expect(CategoryFilter.suscripcion.matches('suscripcion'), isTrue);
      expect(CategoryFilter.producto.matches('producto'), isTrue);
      expect(CategoryFilter.financiacion.matches('financiacion'), isTrue);
      expect(CategoryFilter.salario.matches('salario'), isTrue);
      expect(CategoryFilter.servicio.matches('servicio'), isTrue);
      expect(CategoryFilter.suministroVariable.matches('suministroVariable'),
          isTrue);
      expect(CategoryFilter.venta.matches('venta'), isTrue);
    });

    test('specific filter does not match other categories', () {
      expect(CategoryFilter.suscripcion.matches('producto'), isFalse);
      expect(CategoryFilter.suscripcion.matches('financiacion'), isFalse);
      expect(CategoryFilter.producto.matches('suscripcion'), isFalse);
      expect(CategoryFilter.salario.matches('venta'), isFalse);
    });
  });

  group('CategoryFilter.label', () {
    test('all values have non-empty labels', () {
      for (final filter in CategoryFilter.values) {
        expect(filter.label, isNotEmpty,
            reason: '${filter.name} has empty label');
      }
    });

    test('all label is Todas', () {
      expect(CategoryFilter.all.label, 'Todas');
    });

    test('suscripcion label', () {
      expect(CategoryFilter.suscripcion.label, isNotEmpty);
    });
  });

  group('CategoryFilter values', () {
    test('has 8 values (all + 7 categories)', () {
      expect(CategoryFilter.values.length, 8);
    });
  });
}
