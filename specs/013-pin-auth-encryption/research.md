# Phase 0 Research: PIN Authentication & Database Encryption

**Feature**: 013-pin-auth-encryption
**Date**: 2026-05-04
**Last revised**: 2026-05-04 (after review — D1, D6, D9 amended; D11 added for envelope serialization simplification)

This document records the technical decisions taken during planning, the
rationale behind each, and the alternatives considered.

## Decision 1 — Native SQLite encryption library *(amended)*

**Decision**: Use the **`sqlite3` ^3.x package** (the modern Dart binding)
configured with a `pubspec.yaml` user-defines hook to select the
**`sqlite3mc`** native source. Bump Drift from `^2.20.0` to `^2.32.0`.

**Configuration** (in workspace-root `pubspec.yaml`):

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

This tells the `sqlite3` package's build hook to bundle SQLite3MultipleCiphers
(SQLCipher v4 cipher format compatible) instead of the standard SQLite
binary.

**Rationale**:
- **Verified directly on pub.dev**:
  - `sqlcipher_flutter_libs` is published as `0.7.0+eol`. README states:
    "Starting from version `0.7.0`, this package no longer does anything."
    Description: "Not used anymore, update to version 3.x of package:sqlite3
    instead."
  - `sqlite3_flutter_libs` is published as `0.6.0+eol`. Same EOL status.
- The official Drift docs at
  https://drift.simonbinder.eu/Platforms/encryption/ say verbatim:
  "Previous versions of the `sqlite3` package required a dependency on
  `sqlcipher_flutter_libs`. That package is no longer necessary after
  upgrading to drift 2.32.0 and can be removed."
- The recommended replacement is the `sqlite3` 3.x package with a build
  hook selecting the `sqlite3mc` source.
- SQLite3MultipleCiphers bundles the SQLCipher v4 cipher format. The
  Constitution Principle V mandate ("SQLCipher AES-256 full-database
  encryption") refers to the cipher format on disk, which is preserved.
- Windows desktop is supported via the same package — no OpenSSL
  dependency, no CMake build issues.

**Alternatives rejected**:
- `sqlcipher_flutter_libs` — EOL on pub.dev as of v0.7.0+eol.
- `sqlite3_flutter_libs` — EOL on pub.dev as of v0.6.0+eol.
- Field-level encryption — explicitly prohibited by Constitution V.

**Implications for `pubspec.yaml`**:
- `shared_services/pubspec.yaml`: drop `sqlite3_flutter_libs`; add
  `sqlite3: ^3.0.0`; bump `drift: ^2.32.0` and `drift_dev: ^2.32.0`.
- Workspace root `pubspec.yaml` (`my_apps/pubspec.yaml`): add the `hooks`
  block above.

The opening pattern in `app_database.dart` becomes:

```dart
NativeDatabase.createInBackground(
  file,
  setup: (rawDb) {
    rawDb.execute("PRAGMA key = \"x'${hexKey}'\";");
  },
);
```

(Hex literal form `x'…'` interpreted as a raw key by SQLCipher cipher mode.)

## Decision 2 — Pure-Dart cryptography library

**Decision**: Use `cryptography ^2.9.0` (package by `dint`).

**Rationale**:
- Active maintenance (last release ~5 months ago vs. ~14 months for
  `pointycastle`).
- Cleaner async API: `await Pbkdf2(macAlgorithm: Hmac.sha256(),
  iterations: 500000, bits: 256).deriveKeyFromPassword(password: pin,
  nonce: salt)`.
- AES-GCM exposed as `AesGcm.with256bits()` with first-class
  authentication tag handling.
- Pure Dart → no platform issues on Flutter Windows desktop.
- PBKDF2 (500k iterations) takes ~1–2 s on modern hardware. Wrapped in
  `compute()` so the UI stays responsive (FR-020).

**Alternatives rejected**:
- `pointycastle`: verbose registry-based API, slower release cadence.
- `cryptography_flutter`: native acceleration only benefits Android/iOS;
  no benefit on Windows (primary target).

## Decision 3 — Secure storage for non-DB material

**Decision**: Use `flutter_secure_storage ^9.0.0`.

**Rationale**:
- De-facto Flutter wrapper around platform secure storage: Windows
  Credential Manager, Android Keystore (planned phase), macOS Keychain.
- Lockout state must live outside the database (database is locked
  during a lockout period). Constitution Principle V mandates this
  package explicitly.
- Uniform `read/write/delete` API across platforms.

**Alternatives rejected**:
- Custom file-based store with our own AES wrapper: extra surface area
  for plaintext leaks and key-management code we'd have to audit.
- Storing the envelope inside SQLite (separate non-encrypted table):
  defeats encryption-at-rest; lockout problem unsolvable.

## Decision 4 — Routing & auth gating

**Decision**: Convert `appRouter` from a top-level `final` to a
`routerProvider` (Riverpod `Provider<GoRouter>`) that watches the auth
state. Use GoRouter's `redirect` callback together with a
`refreshListenable` driven by `AuthNotifier`.

**Rationale**:
- The current `final appRouter = GoRouter(...)` is constructed once at
  module-load time and cannot reactively redirect on auth state changes.
- A `routerProvider` lets the redirect closure read `authProvider` via
  `ref` and rebuild on transitions (`unauthenticated` → `authenticated`).
- Centralized gating in the router enforces FR-005: no widget can bypass
  the PIN check by navigating directly.

**Alternatives rejected**:
- Per-widget guards: violates Constitution Principle III.
- Wrapping `MaterialApp.router` in an `auth-or-screen` builder: breaks
  deep-link state and doesn't compose with shell routes.

## Decision 5 — Async database opening pattern

**Decision**: Convert `databaseProvider` from `Provider<AppDatabase>` to
a `Provider<AppDatabase>` that depends on a new `masterKeyProvider`,
populated only after successful auth. Code that previously assumed
synchronous DB availability (`main.dart` calling
`RecurringGenerationService.run(db)` before `runApp`) is moved into
`AuthNotifier`'s success path so it runs explicitly on every successful
auth.

**Rationale**:
- An encrypted database can only be opened once the master key is in
  memory.
- Explicit invocation inside `AuthNotifier` is more transparent than a
  one-shot listener provider, and keeps the side-effect at the obvious
  trigger point (auth success).

**Alternatives rejected**:
- One-shot listener provider firing on `unauthenticated → authenticated`:
  works but adds indirection. Direct call from the notifier is clearer.
- Open the DB at startup with no key, then `PRAGMA rekey` after auth:
  leaves the DB unencrypted on disk for the lifetime of every prior
  unauthenticated launch. Rejected.

## Decision 6 — PIN input widget *(amended — strategy dropped)*

**Decision**: `PinInputWidget` is a single, straightforward desktop
implementation: a `TextField` with numeric `inputFormatters`,
`maxLength: 4`, `obscureText: true`, auto-submit on the 4th digit, and
Enter-to-submit. Add an inline `// TODO(android-keypad): when adding
the Android phase, isolate the input mechanism behind a backend
interface.` Do **not** pre-build the strategy interface now.

**Rationale**:
- Constitution Principle VII: "No premature abstractions. Add a layer
  of indirection only when a second concrete use case demands it."
- The spec only requires the widget be *structurable* to accommodate
  the Android keypad later. A desktop-only implementation with all
  input mechanism in one place satisfies that — the refactor when
  Android arrives is mechanical.
- Removing the strategy collapses ~50 lines of layer-of-indirection
  into a direct `TextField`.

**Alternatives rejected**:
- Pre-built `PinInputBackend` strategy with desktop and stub Android
  implementations: speculative complexity that buys nothing today.

## Decision 7 — Lockout time computation

**Decision**: `waitMinutes = pow(5, blockNumber - 1)` where
`blockNumber = floor(failures / 3)`. Block 1 → 1 min, 2 → 5, 3 → 25,
4 → 125, n → 5^(n-1). Stored as the absolute UTC `lockoutExpiresAt`
ISO-8601 timestamp.

**Rationale**:
- Absolute expiry timestamps make restart resilience trivial — compare
  to `DateTime.now().toUtc()`. SC-005.
- Single `failedAttempts` counter is the source of truth; block number
  is derived.

## Decision 8 — Test seam for SecureStorage and crypto

**Decision**: All four services constructor-inject their dependencies.
Unit tests instantiate `AuthService` with a fake
`SecureStorageService` (in-memory `Map<String, String>`).

**Rationale**:
- Constitution Principle IV: tests must run via `flutter test` without
  platform-channel availability.
- Hand-written 4-method fake is more readable than `mocktail` for a
  small, stable interface.

## Decision 9 — Pre-existing unencrypted database *(amended — fatal error, not auto-delete)*

**Decision**: On startup, if **no envelope is present in secure storage
but a `sfinance.sqlite` file exists** at the expected path, the app
enters `AuthState.fatalError` with a message instructing the developer
to delete the file manually. The app does **not** auto-delete the file.

**Rationale**:
- Auto-delete is destructive — a startup glitch (e.g., transient
  Credential Manager unavailability mistaken for "no envelope") could
  destroy real data.
- The spec assumption ("no existing production user data to migrate")
  protects us against the alternative outcome regardless. If this is
  truly a fresh-install scenario, manual deletion is a one-time, no-cost
  step. If it isn't, we want loud failure, not silent destruction.
- The fatal error screen displays the absolute path of the file to
  delete and stays visible until the user resolves it.

**Alternatives rejected**:
- Silent auto-delete (previous decision): too aggressive given
  irreversibility.
- Attempt in-place migration via `sqlcipher_export`: out of scope per
  the spec assumption; adds removable code.

## Decision 10 — DateTime serialization

**Decision**: UTC ISO-8601 strings (e.g., `2026-05-04T19:32:11.234Z`).
Comparisons use `DateTime.now().toUtc()`.

**Rationale**: unambiguous, human-readable in logs (without revealing
crypto material), trivial to parse, robust to system timezone changes.

## Decision 11 — Envelope and lockout state serialized as JSON blobs *(new)*

**Decision**: Persist the auth envelope and lockout state in
`flutter_secure_storage` as **single JSON-encoded values** under one
key each, not as multiple separate keys.

```
auth.envelope  →  {"salt":"<hex>","encryptedMasterKey":"<base64>","gcmNonce":"<base64>","gcmTag":"<base64>"}
auth.lockout   →  {"failedAttempts":3,"expiresAt":"2026-05-04T19:32:11.234Z"}
                  (lockout key absent or {"failedAttempts":0} when not locked out)
```

**Rationale**:
- Atomic write: a single `write(key, json)` is harder to leave
  half-applied than 4–6 sequential writes.
- Easier corruption check: presence/absence of one key, JSON parse
  succeeds or fails — partial-state ambiguity disappears.
- `flutter_secure_storage` has small per-platform overhead per stored
  key on Windows (one Credential Manager entry per key); a single blob
  keeps the secure-storage footprint tiny.
- Trivially deletable on reinstall.

**Tradeoff**: a malformed JSON blob requires re-creating the envelope
(loss of access). Acceptable given the corruption recovery path is
already "reinstall" per the spec edge cases.

## Decision 12 — Drop envelope `iterations` and `version` fields *(new)*

**Decision**: The envelope stores **only**: `salt`, `encryptedMasterKey`,
`gcmNonce`, `gcmTag`. The PBKDF2 iteration count is a hardcoded
constant (`KeyDerivationService.iterations = 500_000`). There is no
explicit envelope `version` field.

**Rationale**:
- YAGNI. Storing iterations/version was speculative future-proofing
  with no concrete second use case (Constitution Principle VII).
- If we ever bump iterations or change envelope format, that change
  will require a migration anyway — and at that point we'll add the
  field. Storing it preemptively does not reduce future effort.
- Removing two fields simplifies the JSON shape and the test surface.

**Alternatives rejected**:
- Keep `iterations` "just in case": no concrete plan to vary it; the
  Constitution mandates ≥ 500_000 as a floor, not a variable.
- Keep `version`: same argument; an envelope shape change is a
  migration regardless.

## Open Items Deferred to Implementation

- Exact widget styling for the PIN screens — deferred to `shared_ui`
  theme constants. Plan only mandates "same dark theme as the rest of
  the app" (FR-017).
- Error message wording (Spanish) — drafted at task time.
- Lockout countdown display format (`MM:SS` vs "X min Y s") — display
  detail; plan only mandates correct duration handling.
- Exact pinned versions of `sqlite3`, `flutter_secure_storage`,
  `cryptography` — resolved at `flutter pub add` time to whatever is
  current; the caret-range minimums recorded above.
