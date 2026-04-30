import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import 'dao_providers.dart';

class KpiState {
  const KpiState({
    required this.ingresosCents,
    required this.gastosCents,
    required this.balanceCents,
    required this.hasTransactions,
    required this.initialCapitalActive,
  });

  /// Current calendar-month total income in cents.
  final int ingresosCents;

  /// Current calendar-month total expenses in cents.
  final int gastosCents;

  /// All-time balance: income − expenses + initial capital (if active).
  final int balanceCents;

  /// True once at least one transaction exists.
  final bool hasTransactions;

  /// True while initial capital row exists and isActive=true.
  final bool initialCapitalActive;

  static const zero = KpiState(
    ingresosCents: 0,
    gastosCents: 0,
    balanceCents: 0,
    hasTransactions: false,
    initialCapitalActive: false,
  );
}

class _KpiNotifier extends AsyncNotifier<KpiState> {
  @override
  Future<KpiState> build() async {
    // Watching these stream providers triggers a rebuild on every DB change.
    final transactions = await ref.watch(allTransactionsStreamProvider.future);
    final capitalRow = await ref.watch(initialCapitalStreamProvider.future);

    return _compute(transactions, capitalRow);
  }

  KpiState _compute(
    List<TransactionRow> transactions,
    InitialCapitalRow? capitalRow,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    int allTimeIncome = 0;
    int allTimeExpense = 0;
    int monthlyIncome = 0;
    int monthlyExpense = 0;

    for (final tx in transactions) {
      final isIncome = tx.transactionType == 'income';
      final amount = tx.amountCents;

      if (isIncome) {
        allTimeIncome += amount;
      } else {
        allTimeExpense += amount;
      }

      final inThisMonth =
          !tx.date.isBefore(monthStart) && tx.date.isBefore(nextMonthStart);
      if (inThisMonth) {
        if (isIncome) {
          monthlyIncome += amount;
        } else {
          monthlyExpense += amount;
        }
      }
    }

    final capitalActive = capitalRow?.isActive == true;
    final capitalCents = capitalActive ? (capitalRow?.amountCents ?? 0) : 0;
    final balance = allTimeIncome - allTimeExpense + capitalCents;

    return KpiState(
      ingresosCents: monthlyIncome,
      gastosCents: monthlyExpense,
      balanceCents: balance,
      hasTransactions: transactions.isNotEmpty,
      initialCapitalActive: capitalActive,
    );
  }
}

final kpiProvider =
    AsyncNotifierProvider<_KpiNotifier, KpiState>(_KpiNotifier.new);
