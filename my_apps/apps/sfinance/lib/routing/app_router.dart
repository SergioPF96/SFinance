import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_services/shared_services.dart';
import '../providers/auth_provider.dart';
import '../ui/auth/bootstrap_screen.dart';
import '../ui/auth/fatal_error_screen.dart';
import '../ui/auth/lockout_screen.dart';
import '../ui/auth/pin_entry_screen.dart';
import '../ui/auth/pin_setup_screen.dart';
import '../ui/shell/app_shell.dart';
import '../ui/resumen/resumen_view.dart';
import '../ui/analisis/analisis_view.dart';
import '../ui/entradas/entradas_view.dart';
import '../ui/forms/expense_form.dart';
import '../ui/forms/income_form.dart';

// T024: routerProvider with redirect over all 7 AuthState variants.
final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthChangeNotifier();
  ref.listen<AuthState>(authProvider, (_, __) => listenable.notify());
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/auth/bootstrap',
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      return switch (auth) {
        AuthStateBootstrapping() =>
          loc == '/auth/bootstrap' ? null : '/auth/bootstrap',
        AuthStateNeedsSetup() =>
          loc == '/auth/setup' ? null : '/auth/setup',
        AuthStateNeedsAuth() =>
          loc == '/auth/unlock' ? null : '/auth/unlock',
        AuthStateVerifying() => null,
        AuthStateLockedOut() =>
          loc == '/auth/lockout' ? null : '/auth/lockout',
        AuthStateFatalError() =>
          loc == '/auth/fatal' ? null : '/auth/fatal',
        AuthStateAuthenticated() =>
          loc.startsWith('/auth/') ? '/resumen' : null,
      };
    },
    routes: [
      GoRoute(
          path: '/auth/bootstrap', builder: (_, __) => const BootstrapScreen()),
      GoRoute(path: '/auth/setup', builder: (_, __) => const PinSetupScreen()),
      GoRoute(
          path: '/auth/unlock', builder: (_, __) => const PinEntryScreen()),
      GoRoute(
          path: '/auth/lockout', builder: (_, __) => const LockoutScreen()),
      GoRoute(
          path: '/auth/fatal', builder: (_, __) => const FatalErrorScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
              path: '/resumen', builder: (_, __) => const ResumenView()),
          GoRoute(
              path: '/analisis', builder: (_, __) => const AnalisisView()),
          GoRoute(
              path: '/entradas', builder: (_, __) => const EntradasView()),
        ],
      ),
      GoRoute(
        path: '/forms/gasto',
        pageBuilder: (_, __) =>
            DialogPage(builder: (_) => const ExpenseForm()),
      ),
      GoRoute(
        path: '/forms/ingreso',
        pageBuilder: (_, __) =>
            DialogPage(builder: (_) => const IncomeForm()),
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

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
