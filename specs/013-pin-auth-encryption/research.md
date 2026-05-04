# Phase 0 Research: PIN Authentication & Database Encryption

**Feature**: 013-pin-auth-encryption
**Date**: 2026-05-04

This document records the technical decisions taken during planning, the
rationale behind each, and the alternatives considered. The decisions in the
user-supplied technical context are recorded here verbatim where they were
accepted, and explicitly amended where research surfaced a better path.

## Decision 1 — Native SQLite encryption library

**Decision**: Use `sqlite3_multiple_ciphers` (via `drift ^2.32.0`), **not**
`sqlcipher_flutter_libs` as originally proposed.

**Rationale**:
- The official Drift documentation
  (https://drift.simonbinder.eu/platforms/encryption/) states verbatim:
  > "Previous versions of the `sqlite3` package required a dependency on
  > `sqlcipher_flutter_libs`. That package is no longer necessary after
  > upgrading to drift 2.32.0 and can be removed."
- `sqlcipher_flutter_libs` has unresolved Windows desktop build issues
  related to OpenSSL (`libcrypto`) discovery and Windows system library
  linkage. SFinance's primary target is Windows, making this a blocker.
- `sqlite3_multiple_ciphers` bundles multiple cipher schemes including
  **SQLCipher v4** (the cipher format used by SQLCipher itself). This means
  the on-disk format and `PRAGMA key` semantics remain identical to the
  Constitution mandate: "AES-256 SQLCipher full-database encryption."
- Constitution Principle V mandates "SQLCipher (AES-256 full-database
  encryption)" — this refers to the cipher format, which `sqlite3_multiple_ciphers`
  provides. Compliance is preserved.

**Alternatives considered**:
- **`sqlcipher_flutter_libs`**: rejected due to Windows desktop build
  failures and deprecation in Drift's official documentation.
- **Roll-our-own per-field encryption**: explicitly prohibited by
  Constitution Principle V ("Field-level encryption is explicitly prohibited
  as a substitute for full-database encryption").

**Implications**:
- Drift must be upgraded from `^2.20.0` to `^2.32.0` in
  `shared_services/pubspec.yaml` and matching `dev_dependencies` everywhere.
- `sqlite3_flutter_libs` must be removed and replaced with
  `sqlite3_multiple_ciphers` in `shared_services/pubspec.yaml`. The two are
  mutually exclusive (linker conflict); confirmed by upstream guidance.
- The opening pattern uses `PRAGMA key = "x'<hex>'";` — the `x'…'` hex
  literal form, which `sqlite3_multiple_ciphers` accepts identically to
  SQLCipher.

## Decision 2 — Pure-Dart cryptography library

**Decision**: Use `cryptography` (package by `dint`) — version `^2.9.0`.

**Rationale**:
- Active maintenance (last release ~5 months ago vs. ~14 months for
  `pointycastle`).
- Cleaner async API: `await Pbkdf2(macAlgorithm: Hmac.sha256(),
  iterations: 500000, bits: 256).deriveKeyFromPassword(password: pin,
  nonce: salt)` — type-safe and idiomatic.
- AES-GCM is exposed as `AesGcm.with256bits()` with first-class
  authentication tag handling (encryption returns `SecretBox` with
  `cipherText`, `nonce`, `mac`).
- No platform issues on Flutter Windows desktop (pure Dart).
- PBKDF2 (500k iterations) takes ~1–2 s on a modern desktop. We will run
  it inside `compute()` so the UI stays responsive during verification
  (FR-020).

**Alternatives considered**:
- **`pointycastle`**: rejected for verbose registry-based API and slower
  release cadence. Same actual performance for our use case.
- **`cryptography_flutter`**: rejected. Adds a native acceleration layer
  that only benefits Android/iOS (~50× AES-GCM gains on mobile). On Windows
  it falls back to background isolates anyway, so we'd pay an extra
  dependency for zero benefit on the primary platform.

## Decision 3 — Secure storage for non-DB material

**Decision**: Use `flutter_secure_storage ^9.0.0` for the encrypted master
key blob, GCM tag, salt, and lockout state.

**Rationale**:
- This is the de-facto Flutter wrapper around platform secure storage:
  Windows Credential Manager (Win32 DPAPI under the hood), Android Keystore
  (planned phase), macOS Keychain.
- Storing lockout state outside the database is non-negotiable: during
  lockout the database is, by design, inaccessible. Constitution Principle V
  mandates `flutter_secure_storage` explicitly.
- The package handles platform differences (Linux falls back to
  `libsecret`, but Linux is not a target) and exposes a uniform
  `read/write/delete` API.

**Alternatives considered**:
- **A custom file-based store with our own AES wrapper**: rejected — extra
  surface area for plaintext leaks and manual key-management code we'd
  have to audit.
- **Storing the envelope inside SQLite (in a separate non-encrypted
  table)**: rejected — defeats the encryption-at-rest guarantee and makes
  the lockout problem unsolvable.

## Decision 4 — Routing & auth gating

**Decision**: Convert `appRouter` from a top-level `final` to a
`routerProvider` (Riverpod `Provider<GoRouter>`) that watches the auth
state. Use GoRouter's `redirect` callback together with a
`refreshListenable` derived from the auth state.

**Rationale**:
- The current `final appRouter = GoRouter(...)` is constructed once at
  module-load time and cannot reactively redirect when auth state changes.
- A `routerProvider` lets the redirect closure read `authProvider`'s state
  via `ref` and ensures the router rebuilds when auth state transitions
  (`unauthenticated` → `authenticated`, etc.).
- Centralized auth gating in the router enforces that no widget can
  bypass the PIN check by navigating directly — the redirect runs on every
  route change. This satisfies FR-005 ("PIN authentication screen before
  any financial data is accessible or rendered").

**Alternatives considered**:
- **Per-widget guards**: rejected — violates Constitution Principle III
  (UI/Business Logic Separation) and is easy to forget when adding new
  routes. The router is the single choke point.
- **Wrapping `MaterialApp.router` in an `auth-or-screen` builder**:
  rejected — breaks deep-link state and doesn't compose with go_router's
  shell routes.

## Decision 5 — Async database opening pattern

**Decision**: Convert `databaseProvider` from `Provider<AppDatabase>` to
`Provider<AppDatabase>` that depends on the **decrypted master key**, and
introduce a `masterKeyProvider` populated only after successful auth.
Code that previously assumed synchronous DB availability (`main.dart`
calling `RecurringGenerationService.run(db)` before `runApp`) is moved to
a post-auth hook.

**Rationale**:
- An encrypted database can only be opened once the master key is in
  memory. Opening must be deferred until after PIN verification succeeds.
- The current code path opens the DB before `runApp`; with encryption,
  this would either (a) require holding the PIN before `runApp` (not
  possible — UI must run to collect it) or (b) open with no key (defeats
  encryption). Neither is acceptable.
- `RecurringGenerationService.run(db)` is moved into a one-shot effect
  triggered by `authProvider` reaching `authenticated`, before the home
  screen's first frame.

**Alternatives considered**:
- **Open the DB at startup with no key, then `PRAGMA rekey` after
  auth**: rejected — leaves the DB unencrypted on disk for the lifetime of
  every prior unauthenticated launch.
- **Two-database architecture (one encrypted, one not)**: rejected —
  violates Principle V (no plaintext storage of any sensitive data).

## Decision 6 — PIN input widget structure

**Decision**: Create a `PinInputWidget` that exposes a single
`onPinComplete(String pin)` callback and abstracts the entry mechanism
behind an internal `PinInputBackend` interface. The desktop implementation
is a `_DesktopKeyboardBackend` (current scope). A future
`_AndroidKeypadBackend` can be swapped in without screen redesign.

**Rationale**:
- FR-008 and the clarifications mandate desktop keyboard now and
  on-screen keypad (Android) later. Spec assumption: "The widget must be
  structured to accommodate both without a full rewrite."
- A backend strategy keeps the screen layout (title, warning text, error
  display, loading indicator) stable while only the input mechanism
  changes.

**Alternatives considered**:
- **Two separate screens**: rejected — duplicates layout, error handling,
  loading state, and keyboard navigation logic. Increases maintenance
  surface.
- **Conditional `if (Platform.isAndroid)` inside one widget**: rejected
  — encodes platform branching in widget logic, which violates Principle
  III (business logic in widgets).

## Decision 7 — Lockout time computation

**Decision**: Implement the exponential lockout as
`waitMinutes = pow(5, blockNumber - 1)` where `blockNumber = floor(failures / 3)`.
Block 1 → 1 min, block 2 → 5, block 3 → 25, block 4 → 125, block n → 5^(n-1).
Stored as `int waitMinutes` and the absolute `DateTime lockoutExpiresAt`.

**Rationale**:
- Storing the absolute expiry timestamp (rather than just remaining
  seconds) makes restart resilience trivial — on relaunch we compare to
  `DateTime.now()`. SC-005 ("Lockout state is fully preserved after an app
  restart").
- Block number is derived, not stored independently — a single
  `failedAttempts` counter is the source of truth.
- Counter resets to 0 on successful auth (FR-013).

**Alternatives considered**:
- **Track block number separately**: rejected — duplicate state risks
  drift and complicates the reset path.
- **Store remaining seconds and update periodically**: rejected — would
  require a background timer to keep state fresh and would lose accuracy
  on suspend/resume.

## Decision 8 — Test seam for SecureStorage and crypto in unit tests

**Decision**: All four services (`KeyDerivationService`, `EncryptionService`,
`SecureStorageService`, `AuthService`) take their dependencies through
constructor injection. Unit tests instantiate `AuthService` with a fake
`SecureStorageService` (in-memory map) so tests can run without
`flutter_secure_storage` (which requires platform plugins).

**Rationale**:
- Constitution Principle IV requires unit tests written and failing
  before implementation. Tests must run via `flutter test` without
  platform-channel availability.
- An in-memory fake of `SecureStorageService` (a Map<String, String>)
  exercises the same `read/write/delete` surface that the real
  implementation uses.

**Alternatives considered**:
- **Mocking via `mocktail`/`mockito`**: acceptable but adds a dev
  dependency and makes tests less readable than a small hand-written fake
  for a 4-method interface.

## Decision 9 — What happens to existing development databases

**Decision**: This feature treats every install as a fresh start. Any
pre-existing unencrypted `sfinance.sqlite` on disk is **deleted** during
first launch when the encryption initialization runs (i.e., when no
authentication envelope is present in secure storage but a database file
exists). This is destructive but acceptable per the Spec Assumption:
"There is no existing production user data to migrate from an
unencrypted database. The app is in development and this feature treats
every install as a fresh start."

**Rationale**:
- SQLite3MultipleCiphers will refuse to open an unencrypted file with the
  cipher pragma set — the failure mode is opaque and would surface as a
  generic database error.
- Detecting "envelope absent + DB file present" is unambiguous and
  treats the situation as a fresh setup, which matches the assumption.
- Single-line warning logged (no sensitive data) so the developer notices
  during dev work.

**Alternatives considered**:
- **In-place migration with `sqlcipher_export`**: rejected — explicit
  Spec Assumption that no migration is needed; adds code we'd have to
  remove later.
- **Refuse to start and show a migration UI**: rejected — same reason.

## Decision 10 — DateTime serialization for lockout expiry

**Decision**: Store `lockoutExpiresAt` as **UTC ISO-8601 string** (e.g.,
`2026-05-04T19:32:11.234Z`). Wall-clock comparison uses
`DateTime.now().toUtc()`.

**Rationale**:
- ISO-8601 is unambiguous, human-readable in logs (without revealing
  cryptographic material), and trivially parseable.
- UTC avoids timezone drift if the user's system clock changes timezone
  while the app is closed (e.g., laptop crosses a timezone).
- Spec Assumption: "The lockout countdown is based on wall-clock time,
  not app uptime."

**Alternatives considered**:
- **Unix timestamp (seconds)**: equally valid, slightly less readable.
  Either is acceptable; ISO-8601 chosen for symmetry with `intl`
  formatting elsewhere.

## Open Items Deferred to Implementation

- Exact widget styling (typography sizes, spacing) for the PIN screens —
  deferred to the `shared_ui` theme constants. The plan only mandates
  "same dark theme as the rest of the app" (FR-017).
- Error message wording (Spanish localization) — `intl` already in use.
  Strings to be drafted at task time and reviewed for clarity.
- Whether the lockout countdown uses `MM:SS` or "X min Y s" format —
  display detail; the plan only mandates correct duration handling.
