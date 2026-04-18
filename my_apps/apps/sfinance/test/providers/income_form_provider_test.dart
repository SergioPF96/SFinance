import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/database_provider.dart';
import 'package:sfinance/providers/form_providers.dart';

ProviderContainer makeContainer() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}

void main() {
  // ---------------------------------------------------------------------------
  // FR-006 — Salario is exempt because its endDate is a system-set far-future
  // value (today + 50 years), never user-specified. The first occurrence can
  // never exceed a 50-year endDate, so the FR-006 check must not fire for Salario.
  // T024 — these tests FAIL until T028 (FR-006 in IncomeFormNotifier) confirms
  // that Salario saves successfully even when paymentDay has already passed.
  // ---------------------------------------------------------------------------

  group('IncomeFormNotifier — FR-006 not triggered for Salario', () {
    Future<String?> submitSalario(
      ProviderContainer container, {
      required int paymentDay,
      PayFrequency numeroPagas = PayFrequency.docepagas,
    }) async {
      final notifier = container.read(incomeFormProvider.notifier);
      notifier.setNombre('Salario test');
      notifier.setMonto('2500');
      notifier.setCategoria(IncomeCategory.salario);
      notifier.setNumeroPagas(numeroPagas);
      notifier.setPaymentDay(paymentDay);
      return notifier.submit();
    }

    test('Salario with paymentDay already past this month → saves successfully',
        () async {
      final container = makeContainer();
      final today = DateTime.now();
      final pastDay = today.day > 1 ? today.day - 1 : 28;

      final error = await submitSalario(container, paymentDay: pastDay);

      expect(error, isNull,
          reason:
              'Salario uses a system-set far-future endDate — FR-006 must never reject it');

      final db = container.read(databaseProvider);
      final templates = await db.select(db.recurringTemplates).get();
      expect(templates, hasLength(1),
          reason: 'One Salario template must be persisted');
    });

    test(
        'Salario 14 pagas with paymentDay already past this month → saves successfully',
        () async {
      final container = makeContainer();
      final today = DateTime.now();
      final pastDay = today.day > 1 ? today.day - 1 : 28;

      final notifier = container.read(incomeFormProvider.notifier);
      notifier.setNombre('Salario 14p');
      notifier.setMonto('3000');
      notifier.setCategoria(IncomeCategory.salario);
      notifier.setNumeroPagas(PayFrequency.catorcepagas);
      notifier.setPrimeraPagaExtra(6); // June
      notifier.setSegundaPagaExtra(12); // December
      notifier.setPaymentDay(pastDay);

      final error = await notifier.submit();
      expect(error, isNull,
          reason: 'Salario 14p must not trigger FR-006');
    });
  });

  // ---------------------------------------------------------------------------
  // IncomeFormNotifier — basic validation
  // ---------------------------------------------------------------------------

  group('IncomeFormNotifier — basic validation', () {
    test('nombre is required', () async {
      final container = makeContainer();
      final notifier = container.read(incomeFormProvider.notifier);
      notifier.setMonto('500');
      notifier.setCategoria(IncomeCategory.salario);
      final error = await notifier.submit();
      expect(error, isNotNull);
      expect(error, contains('nombre'));
    });

    test('monto must be positive', () async {
      final container = makeContainer();
      final notifier = container.read(incomeFormProvider.notifier);
      notifier.setNombre('Test');
      notifier.setMonto('0');
      notifier.setCategoria(IncomeCategory.salario);
      final error = await notifier.submit();
      expect(error, isNotNull);
    });

    test('salario requires paymentDay', () async {
      final container = makeContainer();
      final notifier = container.read(incomeFormProvider.notifier);
      notifier.setNombre('Test');
      notifier.setMonto('2000');
      notifier.setCategoria(IncomeCategory.salario);
      notifier.setNumeroPagas(PayFrequency.docepagas);
      // paymentDay not set
      final error = await notifier.submit();
      expect(error, isNotNull);
      expect(error, contains('día'));
    });
  });
}
