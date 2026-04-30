import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../domain/category_filter.dart';
import '../../providers/transaction_providers.dart';
import 'tabs/transacciones_tab.dart';
import 'tabs/recurrentes_tab.dart';
import 'tabs/frecuentes_tab.dart';

/// Entradas view with three tabs: Transacciones, Recurrentes, Frecuentes.
///
/// The category filter resets to "Todas" each time this view is entered
/// (FR-008 — filter resets when leaving the view).
class EntradasView extends ConsumerStatefulWidget {
  const EntradasView({super.key});

  @override
  ConsumerState<EntradasView> createState() => _EntradasViewState();
}

class _EntradasViewState extends ConsumerState<EntradasView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(selectedCategoryFilterProvider.notifier).state =
            CategoryFilter.all;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.balance,
          unselectedLabelColor: AppColors.onBackgroundMuted,
          indicatorColor: AppColors.balance,
          tabs: const [
            Tab(text: 'Transacciones'),
            Tab(text: 'Recurrentes'),
            Tab(text: 'Frecuentes'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              TransaccionesTab(),
              RecurrentesTab(),
              FrecuentesTab(),
            ],
          ),
        ),
      ],
    );
  }
}
