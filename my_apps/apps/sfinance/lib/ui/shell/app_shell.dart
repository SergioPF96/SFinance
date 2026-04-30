import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

/// Persistent app shell with top navigation bar and floating action buttons.
///
/// Navigation tabs: Resumen, Analisis, Entradas, Recurrentes.
/// Action buttons "+ Ingreso" (green) and "+ Gasto" (red) always visible
/// in the top-right corner regardless of the active tab.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/analisis')) return 1;
    if (location.startsWith('/entradas')) return 2;
    return 0; // /resumen (default)
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            _NavTab(
              label: 'Resumen',
              selected: currentIndex == 0,
              onTap: () => context.go('/resumen'),
            ),
            const SizedBox(width: 8),
            _NavTab(
              label: 'Analisis',
              selected: currentIndex == 1,
              onTap: () => context.go('/analisis'),
            ),
            const SizedBox(width: 8),
            _NavTab(
              label: 'Entradas',
              selected: currentIndex == 2,
              onTap: () => context.go('/entradas'),
            ),
          ],
        ),
        actions: [
          _ActionButton(
            label: '+ Ingreso',
            color: AppColors.income,
            onPressed: () => context.push('/forms/ingreso'),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: '+ Gasto',
            color: AppColors.expense,
            onPressed: () => context.push('/forms/gasto'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: child,
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor:
            selected ? AppColors.balance : AppColors.onBackgroundMuted,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
