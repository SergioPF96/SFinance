import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'transacciones_tab.dart';
import 'recurrentes_tab.dart';

/// Entradas view with two tabs: Transacciones and Recurrentes.
///
/// [initialTab]: 'transacciones' (default) or 'recurrentes'.
class EntradasView extends StatefulWidget {
  const EntradasView({super.key, this.initialTab = 'transacciones'});

  final String initialTab;

  @override
  State<EntradasView> createState() => _EntradasViewState();
}

class _EntradasViewState extends State<EntradasView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'recurrentes' ? 1 : 0,
    );
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
          dividerColor: AppColors.surfaceVariant,
          tabs: const [
            Tab(text: 'Transacciones'),
            Tab(text: 'Recurrentes'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              TransaccionesTab(),
              RecurrentesTab(),
            ],
          ),
        ),
      ],
    );
  }
}
