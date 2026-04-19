import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart' hide TransactionRow;
import 'package:sfinance/domain/category_filter.dart';
import 'package:sfinance/domain/time_range.dart';
import 'package:sfinance/providers/transaction_providers.dart';
import 'package:sfinance/ui/entradas/entradas_view.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_ES');
  });

  TransactionDisplay makeEntry({
    required int id,
    required String name,
    required String rawCategory,
    bool isRecurring = false,
    String? recurringDetail,
  }) {
    return TransactionDisplay(
      id: id,
      name: name,
      categoryLabel: name,
      rawCategory: rawCategory,
      date: DateTime(2026, 4, 19),
      amountCents: 1000,
      transactionType: TransactionType.expense,
      iconColor: AppColors.expense,
      isRecurring: isRecurring,
      recurringDetail: recurringDetail,
    );
  }

  group('EntradasView — no delete affordance', () {
    testWidgets('no delete icon visible when entries exist', (tester) async {
      final fakeEntries = [
        makeEntry(id: 1, name: 'Netflix', rawCategory: 'suscripcion'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredEntriesProvider.overrideWith(
              (ref) => AsyncValue.data(fakeEntries),
            ),
            selectedTimeRangeProvider
                .overrideWith((ref) => TimeRange.ultimos7Dias),
            selectedCategoryFilterProvider
                .overrideWith((ref) => CategoryFilter.all),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EntradasView()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('no delete icon for recurring entries either', (tester) async {
      final fakeEntries = [
        makeEntry(
          id: 2,
          name: 'Netflix',
          rawCategory: 'suscripcion',
          isRecurring: true,
          recurringDetail: 'Día 15 de cada mes',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredEntriesProvider.overrideWith(
              (ref) => AsyncValue.data(fakeEntries),
            ),
            selectedTimeRangeProvider
                .overrideWith((ref) => TimeRange.ultimos7Dias),
            selectedCategoryFilterProvider
                .overrideWith((ref) => CategoryFilter.all),
          ],
          child: const MaterialApp(
            home: Scaffold(body: EntradasView()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });
}
