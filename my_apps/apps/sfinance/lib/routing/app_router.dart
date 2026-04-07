import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/shell/app_shell.dart';
import '../ui/resumen/resumen_view.dart';
import '../ui/analisis/analisis_view.dart';
import '../ui/entradas/entradas_view.dart';
import '../ui/forms/expense_form.dart';
import '../ui/forms/income_form.dart';

final appRouter = GoRouter(
  initialLocation: '/resumen',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/resumen',
          builder: (context, state) => const ResumenView(),
        ),
        GoRoute(
          path: '/analisis',
          builder: (context, state) => const AnalisisView(),
        ),
        GoRoute(
          path: '/entradas',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'] ?? 'transacciones';
            return EntradasView(initialTab: tab);
          },
        ),
      ],
    ),
    // Modal overlay routes for forms — displayed as dialogs
    GoRoute(
      path: '/forms/gasto',
      pageBuilder: (context, state) => DialogPage(
        builder: (_) => const ExpenseForm(),
      ),
    ),
    GoRoute(
      path: '/forms/ingreso',
      pageBuilder: (context, state) => DialogPage(
        builder: (_) => const IncomeForm(),
      ),
    ),
  ],
);

/// A [Page] that presents its content as a [Dialog].
class DialogPage<T> extends Page<T> {
  const DialogPage({required this.builder, super.key});

  final WidgetBuilder builder;

  @override
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      context: context,
      settings: this,
      builder: builder,
    );
  }
}
