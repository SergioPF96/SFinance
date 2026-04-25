import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/kpi_provider.dart';
import '../../providers/transaction_providers.dart';
import 'monthly_bar_chart.dart';
import 'initial_capital_dialog.dart';
import '../../providers/initial_capital_provider.dart';

/// Resumen dashboard view — KPI strip, monthly bar chart, recent transactions.
///
/// When no transactions exist and initial capital is active, the Balance KPI
/// card shows an inline amount editor.
class ResumenView extends ConsumerWidget {
  const ResumenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KpiStrip(),
          SizedBox(height: 24),
          MonthlyBarChart(),
          SizedBox(height: 32),
          _RecentTransactions(),
        ],
      ),
    );
  }
}

class _KpiStrip extends ConsumerWidget {
  const _KpiStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(kpiProvider);
    final capitalAsync = ref.watch(initialCapitalProvider);

    return kpiAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) =>
          Text('Error: $e', style: const TextStyle(color: AppColors.expense)),
      data: (kpi) {
        final capitalNotSet = capitalAsync.valueOrNull?.isActive != true;
        if (!kpi.hasTransactions && capitalNotSet) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const InitialCapitalDialog(),
              );
            }
          });
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KpiCard(
                label: 'Ingresos',
                amountCents: kpi.ingresosCents,
                color: AppColors.income,
                isIncome: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Gastos',
                amountCents: kpi.gastosCents,
                color: AppColors.expense,
                isIncome: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                label: 'Balance',
                amountCents: kpi.balanceCents.abs(),
                color: kpi.balanceCents >= 0
                    ? AppColors.balance
                    : AppColors.expense,
                isIncome: kpi.balanceCents >= 0,
                showSign: kpi.balanceCents != 0,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transacciones Recientes',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        recentAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: AppColors.expense)),
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Sin transacciones. Usa "+ Gasto" o "+ Ingreso" para empezar.',
                    style: TextStyle(color: AppColors.onBackgroundMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.surfaceVariant, height: 1),
              itemBuilder: (_, i) {
                final tx = transactions[i];
                // Resumen = read-only; no delete affordance.
                return TransactionRow(
                  name: tx.name,
                  categoryLabel: tx.categoryLabel,
                  date: tx.date,
                  amountCents: tx.amountCents,
                  transactionType: tx.transactionType,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
