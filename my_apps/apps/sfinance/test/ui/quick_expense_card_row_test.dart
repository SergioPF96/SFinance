import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/ui/forms/quick_expense_card_row.dart';

QuickExpenseRow _makeRow({int id = 1, String name = 'Café'}) {
  return QuickExpenseRow(
    id: id,
    name: name,
    amountCents: 150,
    category: 'producto',
    imagePath: null,
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('QuickExpenseCardRow', () {
    testWidgets('renders nothing when items list is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        QuickExpenseCardRow(items: const [], onSelected: (_) {}),
      ));
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('shows bolt icon card for item without image', (tester) async {
      final row = _makeRow();
      await tester.pumpWidget(_wrap(
        QuickExpenseCardRow(items: [row], onSelected: (_) {}),
      ));
      await tester.pump();
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
    });

    testWidgets('tapping card calls onSelected with the correct row',
        (tester) async {
      final row = _makeRow(id: 42, name: 'Spotify');
      QuickExpenseRow? selected;
      await tester.pumpWidget(_wrap(
        QuickExpenseCardRow(items: [row], onSelected: (r) => selected = r),
      ));
      await tester.pump();
      await tester.tap(find.byType(InkWell));
      expect(selected, equals(row));
    });
  });
}
