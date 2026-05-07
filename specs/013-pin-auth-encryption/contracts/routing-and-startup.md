# Contract: Routing & App Startup

**Feature**: 013-pin-auth-encryption
**Package**: `apps/sfinance`
**Last revised**: 2026-05-04 (D5 simplified, D6 collapsed, D9 changed to fatal error)

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
  final container = ProviderContainer();
  await container.read(authProvider.notifier).bootstrap();

  runApp(UncontrolledProviderScope(container: container, child: const SFinanceApp()));
}
```

**Key changes**:
- Database is no longer opened in `main()`. It is opened lazily by
  `databaseProvider`, which depends on `masterKeyProvider`, which is only
  populated after auth.
- `RecurringGenerationService.run` moves into `AuthNotifier`'s success
  path (see section 3 below). It runs explicitly on every successful
  unlock before transitioning to `authenticated`.
- `main()` no longer touches the database file. The pre-existing
  unencrypted DB check happens during `AuthService.bootstrap()`
  (research.md Decision 9): if the envelope is absent but the file
  exists, `bootstrap()` returns `AuthState.fatalError` and the user
  sees a screen instructing them to delete the file manually.

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
   master key. `AuthNotifier` then:
   - Stores the master key in its state object.
   - Reads `databaseProvider` (which now resolves) and runs
     `RecurringGenerationService.run(db)` once.
   - Transitions to `AuthState.authenticated`.
3. Router's redirect now matches `/resumen`.
4. The home screen's existing "no initial capital" detection runs and
   shows the initial balance dialog (unchanged code path).

**No changes to `initial_capital_dialog.dart` are required**. The
sequence "PIN setup → initial balance" is enforced by ordering, not by
explicit coupling.

## 4. AuthNotifier success path (post-auth side effect)

```dart
class AuthNotifier extends AsyncNotifier<AuthState> implements Listenable {
  Future<void> submitPin(String pin) async {
    state = const AsyncData(AuthStateVerifying());
    try {
      final masterKey = await ref.read(authServiceProvider).verifyPin(pin);
      // Make the master key available to databaseProvider via the new state
      state = AsyncData(AuthStateAuthenticated(masterKey));
      // Run post-auth side effects exactly once per session
      final db = ref.read(databaseProvider);
      await RecurringGenerationService.run(db);
    } on WrongPinException catch (e) {
      state = AsyncData(AuthStateNeedsAuth(error: e));
    } on LockedOutException catch (e) {
      state = AsyncData(AuthStateLockedOut(e.expiresAt));
    }
  }

  // Equivalent flow for setupPin(pin) on first launch.
}
```

This replaces the earlier "one-shot listener provider" pattern. The
side effect lives at its obvious trigger point (the success branch of
`submitPin`/`setupPin`) — easier to read, no additional indirection.

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
- Reads `LockoutState.expiresAt` via the auth notifier.
- Renders countdown updated by a `Timer.periodic(Duration(seconds: 1))`.
- When countdown reaches zero, calls
  `ref.read(authProvider.notifier).clearLockout()` — transitions back to
  `needsAuth`.

### FatalErrorScreen
- Reads the error reason from `AuthStateFatalError(reason)`.
- Renders the reason verbatim. For the "pre-existing unencrypted DB"
  case, the reason includes the absolute path of the offending file and
  instructions to delete it manually.
- No retry/dismiss — the screen stays until the user resolves the
  underlying condition and relaunches the app.

### PinInputWidget
- Single, straightforward implementation: a `TextField` with
  - `keyboardType: TextInputType.number`
  - `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`
  - `maxLength: 4`
  - `obscureText: true`
  - `textInputAction: TextInputAction.done`
  - autofocus by default
  - calls `onPinComplete(pin)` when 4 digits typed; also accepts Enter.
- Public API: `PinInputWidget({ required ValueChanged<String> onPinComplete,
  bool autofocus = true, bool enabled = true })`.
- Inline `// TODO(android-keypad): when adding the Android phase,
  isolate the input mechanism behind a backend interface.` comment marks
  the future refactor point. **No strategy pattern is built today.**
