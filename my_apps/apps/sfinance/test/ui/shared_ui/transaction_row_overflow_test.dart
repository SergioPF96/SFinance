import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES');
  });

  group('TransactionRow — overflow fix', () {
    testWidgets('recurring row with recurringDetail has no layout overflow',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionRow(
              name: 'Netflix',
              categoryLabel: 'Suscripcion',
              date: DateTime(2026, 4, 19),
              amountCents: 1000,
              transactionType: TransactionType.expense,
              isRecurring: true,
              recurringDetail: 'Día 15 de cada mes',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('recurringDetail appears in the subtitle text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionRow(
              name: 'Netflix',
              categoryLabel: 'Suscripcion',
              date: DateTime(2026, 4, 19),
              amountCents: 1000,
              transactionType: TransactionType.expense,
              isRecurring: true,
              recurringDetail: 'Día 15 de cada mes',
            ),
          ),
        ),
      );

      expect(find.textContaining('Día 15 de cada mes'), findsOneWidget);
    });

    testWidgets('non-recurring row renders without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionRow(
              name: 'Compra',
              categoryLabel: 'Producto',
              date: DateTime(2026, 4, 19),
              amountCents: 5000,
              transactionType: TransactionType.expense,
              isRecurring: false,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
