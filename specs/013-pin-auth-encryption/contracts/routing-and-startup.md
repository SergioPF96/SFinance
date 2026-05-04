# Contract: Routing & App Startup

**Feature**: 013-pin-auth-encryption
**Package**: `apps/sfinance`

This document describes how the existing app startup and routing change
to enforce that no financial data is rendered before authentication.

## 1. main.dart — Startup sequence

**Before**:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  final container = ProviderContainer();
  final db = container.read(databaseProvider);   // synchronous, opens DB
  await RecurringGenerationService.run(db);

  runApp(UncontrolledProviderScope(container: container, child: const SFinanceApp()));
}
```

**After**:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // No DB opened here. Auth must complete first.
  // Delete pre-existing unencrypted DB if no envelope exists (Decision 9).

  final container = ProviderContainer();
  await container.read(authProvider.notifier).bootstrap();

  runApp(UncontrolledProviderScope(container: container, child: const SFinanceApp()));
}
```

**Key changes**:
- Database is no longer opened in `main()`. It is opened lazily by
  `databaseProvider`, which depends on `masterKeyProvider`, which is only
  populated after auth.
- `RecurringGenerationService.run` moves to a one-shot effect listening
  for `AuthState.authenticated` (see section 3 below).
- `main()` performs the unencrypted-DB cleanup before bootstrapping auth
  (Decision 9 in research.md).

## 2. app_router.dart — Auth-aware redirect

**Before** (excerpt):

```dart
final appRouter = GoRouter(
  initialLocation: '/resumen',
  routes: [ /* ... */ ],
);
```

**After**:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/auth/unlock',
    refreshListenable: authNotifier,    // GoRouter rebuilds redirect on auth change
    redirect: (context, state) {
      final authState = ref.read(authProvider).valueOrNull;
      final loc = state.matchedLocation;

      // Bootstrap / fatal states are handled by the auth screens themselves
      switch (authState) {
        case AuthStateBootstrapping():
          return '/auth/bootstrap';
        case AuthStateNeedsSetup():
          return loc.startsWith('/auth/setup') ? null : '/auth/setup';
        case AuthStateNeedsAuth():
        case AuthStateVerifying():
          return loc.startsWith('/auth/unlock') ? null : '/auth/unlock';
        case AuthStateLockedOut():
          return loc.startsWith('/auth/lockout') ? null : '/auth/lockout';
        case AuthStateAuthenticated():
          // Don't bounce back to auth screens once unlocked
          return loc.startsWith('/auth/') ? '/resumen' : null;
        case AuthStateFatalError():
          return loc == '/auth/fatal' ? null : '/auth/fatal';
        case null:
          return null;
      }
    },
    routes: [
      GoRoute(path: '/auth/bootstrap', builder: (_, __) => const BootstrapScreen()),
      GoRoute(path: '/auth/setup',     builder: (_, __) => const PinSetupScreen()),
      GoRoute(path: '/auth/unlock',    builder: (_, __) => const PinEntryScreen()),
      GoRoute(path: '/auth/lockout',   builder: (_, __) => const LockoutScreen()),
      GoRoute(path: '/auth/fatal',     builder: (_, __) => const FatalErrorScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/resumen',  builder: (_, __) => const ResumenView()),
          GoRoute(path: '/analisis', builder: (_, __) => const AnalisisView()),
          GoRoute(path: '/entradas', builder: (_, __) => const EntradasView()),
        ],
      ),
      GoRoute(path: '/forms/gasto',   pageBuilder: (_, __) => DialogPage(builder: (_) => const ExpenseForm())),
      GoRoute(path: '/forms/ingreso', pageBuilder: (_, __) => DialogPage(builder: (_) => const IncomeForm())),
    ],
  );
});
```

`AuthNotifier` extends `Listenable` (or wraps a `ValueNotifier`) so that
GoRouter's `refreshListenable` triggers a redirect re-evaluation whenever
auth state changes.

## 3. Onboarding sequence (PIN setup → initial balance)

The existing initial balance dialog (`initial_capital_dialog.dart`) is
currently triggered the first time the home screen detects no balance is
set. With this feature, the trigger order becomes:

1. `AuthState.needsSetup` → router redirects to `/auth/setup`.
2. User completes PIN setup. `AuthService.setupPin(pin)` returns the
   master key. `AuthNotifier` transitions to `AuthState.authenticated`.
3. Router's redirect now matches `/resumen`.
4. The home screen's existing "no initial capital" detection runs and
   shows the initial balance dialog (unchanged code path).

**No changes to `initial_capital_dialog.dart` are required**. The
sequence "PIN setup → initial balance" is enforced by ordering, not by
explicit coupling.

## 4. Post-auth one-shot: RecurringGenerationService

```dart
final _recurringGenOnceProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<AuthState>>(authProvider, (prev, next) {
    final wasAuth = prev?.valueOrNull is AuthStateAuthenticated;
    final isAuth = next.valueOrNull is AuthStateAuthenticated;
    if (!wasAuth && isAuth) {
      // First entry into authenticated state — run once.
      final db = ref.read(databaseProvider);
      RecurringGenerationService.run(db);
    }
  });
});
```

`SFinanceApp` reads this provider once via `ref.watch(_recurringGenOnceProvider)`
to start the listener. The listener fires exactly once per session, on
the transition into `authenticated`.

## 5. databaseProvider — fail-fast guard

```dart
final masterKeyProvider = Provider<Uint8List>((ref) {
  final auth = ref.watch(authProvider).valueOrNull;
  if (auth is! AuthStateAuthenticated) {
    throw StateError(
      'masterKeyProvider read while not authenticated — this is a bug.',
    );
  }
  return auth.masterKey;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final key = ref.watch(masterKeyProvider);
  final db = AppDatabase(key);
  ref.onDispose(db.close);
  return db;
});
```

Any DAO accessed before authentication will trigger the `StateError`
above. This is a deliberate hard failure: it surfaces architectural bugs
(e.g., a widget reading data outside the protected route tree) at
development time rather than silently leaking access patterns.

## 6. UI widget contracts

### PinSetupScreen
- Two `PinInputWidget` instances (enter, confirm).
- Prominent irrecoverability warning above the inputs.
- Submit disabled until both are 4 digits.
- On submit: calls `ref.read(authProvider.notifier).completeSetup(pin)`.
- On mismatch: clears both, shows error message.

### PinEntryScreen
- One `PinInputWidget`.
- Calls `ref.read(authProvider.notifier).submitPin(pin)` on completion.
- Shows loading indicator while `AuthState.verifying`.
- Shows error and remaining-attempts count after wrong PIN.
- Auto-redirects (via router) when state transitions to
  `authenticated` or `lockedOut`.

### LockoutScreen
- Reads `LockoutState.lockoutExpiresAt` via the auth notifier.
- Renders countdown updated by a `Timer.periodic(Duration(seconds: 1))`.
- When countdown reaches zero, calls
  `ref.read(authProvider.notifier).clearLockout()` — transitions back to
  `needsAuth`.

### PinInputWidget (extensible)
- Internal `PinInputBackend` strategy:
  - `_DesktopKeyboardBackend`: `TextField` with numeric `inputFormatters`,
    `maxLength: 4`, `obscureText: true`, auto-submits on 4th digit, accepts
    Enter. Tab navigation works as standard.
  - `_AndroidKeypadBackend`: out of scope for this feature. Stub class with
    `assert(false, 'Not implemented')` placed for documentation only.
- Public API: `PinInputWidget({ required ValueChanged<String> onPinComplete,
  bool autofocus = true })`.
