# Tasks: PIN Authentication & Database Encryption

**Feature**: 013-pin-auth-encryption
**Input**: Design documents from `specs/013-pin-auth-encryption/`
**Branch**: `013-pin-auth-encryption`

## Format: `[ID] [P?] [Story?] Description with file path`

- **[P]**: Can run in parallel (different files, no outstanding dependencies)
- **[Story]**: User story this task belongs to (US1, US2, US3)
- All implementation tasks follow a test-first discipline (Constitution Principle IV)

## Path Conventions

- **Shared services**: `my_apps/packages/shared_services/lib/src/auth/`
- **Shared service tests**: `my_apps/packages/shared_services/test/auth/`
- **App providers**: `my_apps/apps/sfinance/lib/providers/`
- **App routing**: `my_apps/apps/sfinance/lib/routing/`
- **App auth UI**: `my_apps/apps/sfinance/lib/ui/auth/`
- **App widget tests**: `my_apps/apps/sfinance/test/ui/auth/`

---

## Phase 1: Setup

**Purpose**: Dependency and pubspec changes required by all subsequent work.

- [X] T001 Add sqlite3mc build hook to workspace pubspec: under `hooks.user_defines.sqlite3.source: sqlite3mc` in `my_apps/pubspec.yaml`
- [X] T002 Update `my_apps/packages/shared_services/pubspec.yaml`: bump `drift` to `^2.32.0` and `drift_dev` to `^2.32.0`, remove `sqlite3_flutter_libs`, add `sqlite3: ^3.0.0`, `flutter_secure_storage: ^9.0.0`, `cryptography: ^2.9.0`
- [X] T003 [P] Run `flutter pub get` inside `my_apps/packages/shared_services/` and fix any version conflicts
- [X] T004 [P] Find all call sites of the old `AppDatabase()` no-arg constructor (check `my_apps/apps/sfinance/test/` and any migration tests) and update them to `AppDatabase.forTesting(executor)` so they compile once T008 lands

**Checkpoint**: Deps resolved — shared_services builds with the new packages.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure infrastructure shared by ALL user stories. Nothing in Phase 3+ can start until this phase is complete.

**⚠️ CRITICAL**: Complete this phase before any user-story work.

- [X] T005 Create `SecureStorageService` abstract interface and `FlutterSecureStorageService` concrete implementation (wrapping `flutter_secure_storage`; `isAvailable()`, `read`, `write`, `delete`, `containsKey`) in `my_apps/packages/shared_services/lib/src/auth/secure_storage_service.dart`
- [X] T006 [P] Create `InMemorySecureStorageService` fake (Map-backed; all methods; delete of missing key is a no-op) in `my_apps/packages/shared_services/test/auth/fakes/in_memory_secure_storage.dart`
- [X] T007 [P] Create `AuthState` sealed class with all 7 states (`bootstrapping`, `needsSetup`, `needsAuth`, `verifying`, `authenticated(Uint8List masterKey)`, `lockedOut(DateTime expiresAt)`, `fatalError(String reason)`) in `my_apps/packages/shared_services/lib/src/auth/auth_state.dart`
- [X] T008 Modify `AppDatabase`: remove no-arg constructor; add `AppDatabase(Uint8List masterKey)` that passes `PRAGMA key = "x'<hexKey>'"` via `NativeDatabase.createInBackground` setup callback; add `AppDatabase.forTesting(QueryExecutor executor)` for tests in `my_apps/packages/shared_services/lib/src/database/app_database.dart`
- [X] T009 Write failing tests for `LockoutState` (JSON round-trip preserves both fields; `isLockedOut` returns false when `expiresAt` is null; `isLockedOut` returns true iff `now < expiresAt`; `currentBlock = floor(failedAttempts / 3)`; missing `failedAttempts` field → `FormatException`) in `my_apps/packages/shared_services/test/auth/lockout_state_test.dart`
- [X] T010 Implement `LockoutState` value type with `toJson`/`fromJson` codec; run T009 and confirm all tests pass in `my_apps/packages/shared_services/lib/src/auth/lockout_state.dart`
- [X] T011 Export all new `auth/` types (`AuthState`, `AuthEnvelope`, `LockoutState`, `LockoutPolicy`, `KeyDerivationService`, `EncryptionService`, `SecureStorageService`, `AuthService`) from `my_apps/packages/shared_services/lib/shared_services.dart`

**Checkpoint**: Foundation ready — user story implementation can now begin.

---

## Phase 3: User Story 1 — First-Launch PIN Setup (Priority: P1) 🎯 MVP

**Goal**: A fresh install shows only the PIN setup screen; user enters and confirms a 4-digit PIN with an irrecoverability warning; the master key is generated, wrapped, and persisted; the app transitions to the home screen (existing initial-balance dialog next).

**Independent Test**: Wipe all app data, launch, complete PIN setup with two matching entries, confirm the irrecoverability warning is present, and verify the router lands on `/resumen` after setup. See quickstart.md Validation 1.

### Tests for User Story 1 ⚠️ Write these FIRST — confirm they FAIL before implementing

- [X] T012 [P] [US1] Write failing tests for `KeyDerivationService` (same pin+salt → same 32-byte output; different salt + same pin → different output; output length is exactly 32 bytes) in `my_apps/packages/shared_services/test/auth/key_derivation_service_test.dart`
- [X] T013 [P] [US1] Write failing tests for `EncryptionService` (encrypt → decrypt round-trip yields original bytes; decrypt with wrong wrapping key → `WrongKeyException`; decrypt with tampered ciphertext → `WrongKeyException`; each `encryptMasterKey` call produces a distinct nonce) in `my_apps/packages/shared_services/test/auth/encryption_service_test.dart`
- [X] T014 [P] [US1] Write failing tests for `AuthEnvelope` (JSON round-trip: `fromJson(toJson())` is equal; any of the 4 fields missing → `FormatException`; wrong byte length on any field → `FormatException`; malformed base64/hex → `FormatException`) in `my_apps/packages/shared_services/test/auth/auth_envelope_test.dart`
- [X] T015 [US1] Write failing `AuthService` tests for scenarios 1 and 2: (1) fresh install — `bootstrap()` returns `needsSetup`, `setupPin('1234')` persists a 4-field JSON envelope under `auth.envelope` and returns a 32-byte key, subsequent `bootstrap()` on same storage returns `needsAuth`; (2) correct PIN — `verifyPin('1234')` (once implemented) returns the same 32-byte key as `setupPin` in `my_apps/packages/shared_services/test/auth/auth_service_test.dart`

### Implementation for User Story 1

- [X] T016 [P] [US1] Implement `Pbkdf2KeyDerivationService` using `cryptography ^2.9.0` (`Pbkdf2`, `Hmac.sha256()`, `iterations = 500000`, run via `compute()`); run T012 and confirm all pass in `my_apps/packages/shared_services/lib/src/auth/key_derivation_service.dart`
- [X] T017 [P] [US1] Implement `AesGcmEncryptionService` using `cryptography ^2.9.0` (`AesGcm.with256bits()`, fresh `SecretBox` nonce per call, `WrongKeyException` on tag mismatch); run T013 and confirm all pass in `my_apps/packages/shared_services/lib/src/auth/encryption_service.dart`
- [X] T018 [P] [US1] Implement `AuthEnvelope` value type with `toJson`/`fromJson` (fields: `salt` hex, `encryptedMasterKey` base64, `gcmNonce` base64, `gcmTag` base64; all `FormatException` paths); run T014 and confirm all pass in `my_apps/packages/shared_services/lib/src/auth/auth_envelope.dart`
- [X] T019 [US1] Implement `AuthService.bootstrap()` (checks `isAvailable`, reads `auth.envelope`, returns `needsSetup`/`needsAuth`/`lockedOut`/`fatalError` as appropriate) and `AuthService.setupPin(pin)` (generates master key + salt, derives wrapping key, wraps with AES-GCM, persists envelope, initializes clean `LockoutState`); run T015 scenarios 1 and 2 and confirm they pass in `my_apps/packages/shared_services/lib/src/auth/auth_service.dart`
- [X] T020 [US1] Create `authServiceProvider` (wiring `FlutterSecureStorageService`, `Pbkdf2KeyDerivationService`, `AesGcmEncryptionService`, and `preExistingDbExists` callback) and `AuthNotifier` with `bootstrap()` and `completeSetup(pin)` methods; `AuthNotifier` must extend/mix `Listenable` for GoRouter's `refreshListenable` in `my_apps/apps/sfinance/lib/providers/auth_provider.dart`
- [X] T021 [P] [US1] Create `masterKeyProvider` (`Provider<Uint8List>`) that reads `authProvider` and throws `StateError` if the state is not `AuthStateAuthenticated` in `my_apps/apps/sfinance/lib/providers/master_key_provider.dart`
- [X] T022 [US1] Update `databaseProvider` to `watch(masterKeyProvider)` and construct `AppDatabase(key)`; move `RecurringGenerationService.run(db)` call from main.dart into `AuthNotifier`'s auth-success path (both `completeSetup` and `submitPin`) in `my_apps/apps/sfinance/lib/providers/database_provider.dart`
- [X] T023 [US1] Modify `main.dart`: remove synchronous `databaseProvider` read and `RecurringGenerationService.run` call; add `await container.read(authProvider.notifier).bootstrap()` before `runApp` in `my_apps/apps/sfinance/lib/main.dart`
- [X] T024 [US1] Convert `app_router.dart` to `routerProvider` (`Provider<GoRouter>`): `refreshListenable: authNotifier`, `redirect` switch on all 7 `AuthState` variants, routes for `/auth/bootstrap`, `/auth/setup`, `/auth/unlock`, `/auth/lockout`, `/auth/fatal`, and the existing shell routes (`/resumen`, `/analisis`, `/entradas`) and form routes in `my_apps/apps/sfinance/lib/routing/app_router.dart`
- [X] T025 [P] [US1] Implement `PinInputWidget` (`TextField`, `FilteringTextInputFormatter.digitsOnly`, `maxLength: 4`, `obscureText: true`, `TextInputAction.done`, autofocus, `onPinComplete` callback fired on 4th digit and on Enter, `enabled` param; add `// TODO(android-keypad)` comment) in `my_apps/apps/sfinance/lib/ui/auth/widgets/pin_input_widget.dart`
- [X] T026 [P] [US1] Implement `BootstrapScreen` (centered spinner, no financial content, no navigation) in `my_apps/apps/sfinance/lib/ui/auth/bootstrap_screen.dart`
- [X] T027 [P] [US1] Implement `FatalErrorScreen` (renders `AuthStateFatalError.reason` verbatim; for the pre-existing DB case the reason includes the absolute file path; no dismiss button; stays until user relaunches) in `my_apps/apps/sfinance/lib/ui/auth/fatal_error_screen.dart`
- [X] T028 [US1] Implement `PinSetupScreen` (two `PinInputWidget` instances labeled "PIN" and "Confirm PIN"; prominent irrecoverability warning text; mismatch → show error and clear both fields; submit disabled until both fields are 4 digits; on valid submit calls `ref.read(authProvider.notifier).completeSetup(pin)`) in `my_apps/apps/sfinance/lib/ui/auth/pin_setup_screen.dart`

**Checkpoint**: User Story 1 fully functional — fresh install shows only the setup screen, completes PIN creation, and reaches `/resumen` with no flash of financial content.

---

## Phase 4: User Story 2 — Launch Authentication (Priority: P2)

**Goal**: On every subsequent launch, the PIN entry screen appears first with no financial data visible; the correct PIN unlocks the app; a wrong PIN shows remaining attempts; the loading indicator is shown and input disabled during PBKDF2 verification.

**Independent Test**: Close and reopen the app after setup. Confirm PIN screen appears, entering the correct PIN reaches `/resumen`, entering a wrong PIN shows remaining attempts. See quickstart.md Validations 2 and 6.

### Tests for User Story 2 ⚠️ Write FIRST — confirm they FAIL before implementing

- [X] T029 [US2] Write failing `AuthService` tests for scenarios 3 and 6: (3) `verifyPin('9999')` throws `WrongPinException` with `failedAttempts=1` and `newLockout=null`; (6) 2 wrong PINs then correct PIN → `failedAttempts` in storage resets to 0; append to `my_apps/packages/shared_services/test/auth/auth_service_test.dart`

### Implementation for User Story 2

- [X] T030 [US2] Implement `AuthService.verifyPin(pin)` for the non-lockout path (derive wrapping key, attempt decrypt, on success reset `LockoutState.clean`, on failure increment `failedAttempts` and persist `LockoutState`, throw `WrongPinException`); also implement `AuthService.currentLockout()`; run T029 and confirm it passes in `my_apps/packages/shared_services/lib/src/auth/auth_service.dart`
- [X] T031 [US2] Add `submitPin(pin)` to `AuthNotifier` (`needsAuth → verifying → authenticated` with `RecurringGenerationService.run(db)` on success, or `needsAuth(error)` with remaining-attempts info on failure) in `my_apps/apps/sfinance/lib/providers/auth_provider.dart`
- [X] T032 [US2] Implement `PinEntryScreen` (one `PinInputWidget`; calls `submitPin` on completion; shows `CircularProgressIndicator` and disables input while `AuthStateVerifying`; shows error text with remaining-attempts count when `AuthStateNeedsAuth` has an error; auto-redirects via router on state change) in `my_apps/apps/sfinance/lib/ui/auth/pin_entry_screen.dart`

**Checkpoint**: User Stories 1 and 2 both work independently — launch authentication enforced, no FUOC, loading indicator visible during PBKDF2.

---

## Phase 5: User Story 3 — Lockout After Consecutive Failures (Priority: P3)

**Goal**: After 3 consecutive wrong PINs a lockout countdown screen appears; durations follow the `pow(5, block-1)` minute progression; lockout state persists across app restarts; counter resets on successful auth.

**Independent Test**: Enter 3 wrong PINs, verify 1-minute lockout appears, wait for expiry, re-enable input; authenticate correctly; enter 3 wrong PINs again and confirm block-1 lockout (not block-2). See quickstart.md Validations 3 and 4.

### Tests for User Story 3 ⚠️ Write FIRST — confirm they FAIL before implementing

- [X] T033 [P] [US3] Write failing tests for `LockoutPolicy` — all 10 exact assertions from contracts/auth-service.md: `lockoutFor(0)` → `null`, `lockoutFor(1)` → `null`, `lockoutFor(2)` → `null`, `lockoutFor(3)` → `Duration(minutes: 1)`, `lockoutFor(4)` → `null`, `lockoutFor(5)` → `null`, `lockoutFor(6)` → `Duration(minutes: 5)`, `lockoutFor(9)` → `Duration(minutes: 25)`, `lockoutFor(12)` → `Duration(minutes: 125)`, `lockoutFor(15)` → `Duration(minutes: 625)` in `my_apps/packages/shared_services/test/auth/lockout_policy_test.dart`
- [X] T034 [US3] Write failing `AuthService` tests for lockout scenarios 4–8: (4) 3 consecutive wrong PINs → 3rd throws `WrongPinException(failedAttempts:3, newLockout:Duration(minutes:1))`; (5) 4th attempt during active lockout → `LockedOutException` (no PBKDF2 work); (6) lockout persists across restart — fresh `AuthService` same storage → `bootstrap()` returns `lockedOut`; (7) 6 total failures → 5-min lockout, 9 → 25-min (use injected fake clock); scenarios 9–11: corrupt envelope → `fatalError`; pre-existing DB → `fatalError` with path; `isAvailable()` false → `fatalError`; append to `my_apps/packages/shared_services/test/auth/auth_service_test.dart`

### Implementation for User Story 3

- [X] T035 [US3] Implement `LockoutPolicy` (`lockoutFor(int failedAttempts)` using `pow(5, blockNumber - 1)` minutes where `blockNumber = failedAttempts ~/ 3`; returns `null` when not on a block boundary); run T033 and confirm all 10 assertions pass in `my_apps/packages/shared_services/lib/src/auth/lockout_policy.dart`
- [X] T036 [US3] Add lockout enforcement to `AuthService.verifyPin` (check `isLockedOut` before any PBKDF2 work, throw `LockedOutException` if active; after wrong PIN, call `LockoutPolicy.lockoutFor`, persist new `LockoutState` with `expiresAt` when on a block boundary, include `newLockout` in `WrongPinException`); complete `AuthService.bootstrap` pre-existing DB check (envelope absent + DB file present → `fatalError` with absolute path) and corrupt envelope handling; run T034 and confirm all pass in `my_apps/packages/shared_services/lib/src/auth/auth_service.dart`
- [X] T037 [US3] Add `lockedOut` state handling to `AuthNotifier`: `submitPin` emits `AuthStateLockedOut` on `LockedOutException`; add `clearLockout()` method (called by `LockoutScreen` when countdown expires, transitions back to `needsAuth`) in `my_apps/apps/sfinance/lib/providers/auth_provider.dart`
- [X] T038 [US3] Implement `LockoutScreen` (reads `expiresAt` from `AuthStateLockedOut` via `ref.watch(authProvider)`; `Timer.periodic(Duration(seconds: 1))` countdown; calls `ref.read(authProvider.notifier).clearLockout()` when remaining ≤ 0; displays `MM:SS` or `Xm Ys` remaining; no dismiss) in `my_apps/apps/sfinance/lib/ui/auth/lockout_screen.dart`

**Checkpoint**: All 3 user stories fully functional and independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T039 [P] Write widget tests for `PinSetupScreen`: mismatch → error shown and both fields cleared; submit button/action disabled when either field has < 4 digits in `my_apps/apps/sfinance/test/ui/auth/pin_setup_screen_test.dart`
- [X] T040 [P] Write widget tests for `PinEntryScreen`: while `AuthStateVerifying` → spinner shown and `PinInputWidget` is `enabled: false`; while `AuthStateNeedsAuth` with error → remaining-attempts text visible in `my_apps/apps/sfinance/test/ui/auth/pin_entry_screen_test.dart`
- [X] T041 Run `melos run test` from `my_apps/` and fix all test failures before proceeding
- [X] T042 Run `flutter analyze` from `my_apps/` and fix all warnings and hints
- [X] T043 Grep for `print(` and `debugPrint(` in `my_apps/packages/shared_services/lib/src/auth/` and `my_apps/apps/sfinance/lib/providers/`; remove any statement that logs PIN, key bytes, salt, nonce, tag, envelope JSON, or lockout state
- [X] T044 Run quickstart.md Validations 1–8 manually on Windows desktop; all 8 must pass before marking this feature complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** (Setup): No dependencies — start immediately.
- **Phase 2** (Foundational): Depends on Phase 1 completion — blocks all user stories.
- **Phase 3** (US1): Depends on Phase 2 completion. No dependencies on US2 or US3.
- **Phase 4** (US2): Depends on Phase 3 completion (needs `AuthService`, `authServiceProvider`, `routerProvider`).
- **Phase 5** (US3): Depends on Phase 4 completion (extends `AuthService.verifyPin`).
- **Phase 6** (Polish): Depends on Phases 3–5.

### Within Phase 3

- T012, T013, T014 (tests) can run in parallel — confirm all FAIL before any impl.
- T015 (AuthService test) depends on T005 (SecureStorageService) and T006 (fake).
- T016, T017, T018 (impls) can run in parallel once their respective tests are written.
- T019 (AuthService impl) depends on T016 + T017 + T018 being complete.
- T020 depends on T019 (AuthService).
- T021, T025, T026, T027 can run in parallel once T007 (AuthState) and T020 are done.
- T022 depends on T021 (masterKeyProvider).
- T023 depends on T020 (AuthNotifier).
- T024 depends on T020 and T007 (AuthState + AuthNotifier).
- T028 (PinSetupScreen) depends on T025 (PinInputWidget).

### Within Phase 5

- T033 (LockoutPolicy test) and T034 (AuthService lockout tests) can be written in parallel.
- T035 (LockoutPolicy impl) depends on T033; T036 (AuthService lockout) depends on T035.
- T037 and T038 (AuthNotifier + LockoutScreen) depend on T036.

---

## Parallel Execution Examples

### Phase 3 — Tests (run together, all should FAIL)

```
T012: key_derivation_service_test.dart
T013: encryption_service_test.dart
T014: auth_envelope_test.dart
```

### Phase 3 — Implementations (run together after tests written)

```
T016: key_derivation_service.dart
T017: encryption_service.dart
T018: auth_envelope.dart
```

### Phase 3 — App-layer scaffolding (run together after T020)

```
T021: master_key_provider.dart
T025: pin_input_widget.dart
T026: bootstrap_screen.dart
T027: fatal_error_screen.dart
```

### Phase 6 — Polish (run together)

```
T039: pin_setup_screen_test.dart
T040: pin_entry_screen_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Run quickstart.md Validation 1 independently
5. Continue to US2 once US1 is green

### Incremental Delivery

1. Setup + Foundational → depependency ready
2. US1 complete → fresh-install PIN creation works end-to-end
3. US2 complete → returning-user unlock works, FUOC eliminated, loading indicator visible
4. US3 complete → brute-force lockout enforced, persists across restarts
5. Polish → all tests green, analyze clean, quickstart passed

---

## Task Summary

| Phase | Tasks | Scope |
|---|---|---|
| 1 — Setup | T001–T004 | Pubspec / dependency changes |
| 2 — Foundational | T005–T011 | SecureStorageService, AuthState, LockoutState, AppDatabase |
| 3 — US1 (P1) | T012–T028 | PIN setup: tests + services + app wiring + UI |
| 4 — US2 (P2) | T029–T032 | PIN unlock: verifyPin + PinEntryScreen |
| 5 — US3 (P3) | T033–T038 | Lockout: LockoutPolicy + enforcement + LockoutScreen |
| 6 — Polish | T039–T044 | Widget tests, analyze, quickstart |
| **Total** | **44 tasks** | |

**Parallel opportunities**: 16 tasks marked [P].
**Independent test criteria per story**: see each phase's "Independent Test" line.
**Suggested MVP scope**: Phases 1 + 2 + 3 (User Story 1 only — first-launch PIN setup).
