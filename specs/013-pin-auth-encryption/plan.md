# Implementation Plan: PIN Authentication & Database Encryption

**Branch**: `013-pin-auth-encryption` | **Date**: 2026-05-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/013-pin-auth-encryption/spec.md`

## Summary

Add a PIN-protected, fully encrypted at-rest SQLite database to SFinance.
First launch presents a mandatory PIN setup (with confirmation and an
irrecoverability warning) before the existing initial balance dialog.
Every subsequent launch requires PIN entry before any financial data is
rendered. The PIN never opens the database directly — it derives a
wrapping key (PBKDF2-SHA256, ≥500,000 iterations, random 16-byte salt)
that decrypts a randomly generated 32-byte master key (AES-256-GCM).
The master key opens the database via SQLCipher (AES-256). Three
consecutive wrong PINs trigger an exponential lockout (1, 5, 25, 125…
minutes, ×5 per block), enforced before any decryption attempt and
persisted in `flutter_secure_storage` so it survives app restarts and
crashes. The architecture deliberately keeps the master key independent
of the PIN so biometric unlock can be added in the Android phase without
re-encrypting the database.

## Technical Context

**Language/Version**: Dart 3.x (Flutter stable channel)
**Primary Dependencies**:
- Existing: `flutter_riverpod ^2.5.0`, `go_router ^14.0.0`,
  `drift ^2.20.0` *(must be upgraded to `^2.32.0`)*, `intl ^0.19.0`,
  `path_provider ^2.1.0`, `path ^1.9.0`.
- **Removed**: `sqlite3_flutter_libs ^0.5.0` (incompatible with the new
  encrypted-DB approach).
- **Added**: `sqlite3_multiple_ciphers ^4.0.0` (replaces
  `sqlite3_flutter_libs`; provides SQLCipher v4 cipher format with
  Windows desktop support — see research.md Decision 1).
- **Added**: `flutter_secure_storage ^9.0.0` (for envelope and lockout
  state — Constitution Principle V mandate).
- **Added**: `cryptography ^2.9.0` (PBKDF2-SHA256 and AES-256-GCM in
  pure Dart — see research.md Decision 2).

**Storage**: SQLite via Drift, on-device only. Schema version stays at
`4` — encryption is transparent to the schema. New persistent state
(`AuthEnvelope`, `LockoutState`) lives in `flutter_secure_storage`, not
the database.

**Testing**: `flutter_test`, Riverpod test utilities,
in-memory `SecureStorageService` fake for unit tests. Real
`flutter_secure_storage` exercised only by integration tests / quickstart.

**Target Platform**: Windows desktop (primary). Android (planned, out of
scope for this feature — but the PIN input widget and master-key
architecture are designed to extend cleanly to the Android phase).

**Project Type**: Flutter desktop app in a Melos monorepo (existing
structure — see Project Structure section).

**Performance Goals**:
- Unlock end-to-end (PIN typed → home screen) ≤ 15 s (SC-002).
- PBKDF2 derivation ~1–2 s on Windows desktop hardware; runs via
  `compute()` so the UI stays responsive (FR-020).
- Lockout countdown updates at 1 Hz; no perceptible jitter.

**Constraints**:
- Offline-only — no network calls (Constitution Principle V, unchanged).
- No plaintext cryptographic material on disk, in logs, or in error
  messages (Constitution Principle V).
- Master Key MUST NOT be derived from the PIN; it is independent
  (Constitution Principle V; spec FR-019).
- Lockout enforcement happens BEFORE any decryption attempt
  (Constitution Principle V).

**Scale/Scope**:
- Single user, single device (no multi-tenant data).
- Database < 100 MB (typical personal finance dataset).
- ~10 new files in `shared_services/lib/src/auth/` and
  `apps/sfinance/lib/ui/auth/`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Check | Notes |
|-----------|-------|-------|
| I. Monorepo & Shared Code | All four auth services placed in `shared_services/lib/src/auth/`. Auth Riverpod provider lives in the app (`apps/sfinance/lib/providers/`) because Riverpod is the app-layer concern. **Breaking change**: `AppDatabase()` no-arg constructor removed in favor of `AppDatabase(Uint8List masterKey)`. Documented in Complexity Tracking. | ✅ PASS (with documented breaking change) |
| II. Riverpod-Only State | `authProvider` (`AsyncNotifierProvider<AuthNotifier, AuthState>`), `authServiceProvider`, `masterKeyProvider`, `databaseProvider` — all globally scoped. No `setState`. | ✅ PASS |
| III. UI/Business Logic Separation | All auth logic in `shared_services` (pure Dart, no Flutter imports). Widgets are presentational and call notifier methods. Routing centralized in `routerProvider` with redirect-based gating. Models pure Dart. | ✅ PASS |
| IV. Test-First for Financial Logic | Crypto and lockout math are non-financial but security-critical. Same discipline applied: unit tests for `LockoutPolicy`, `KeyDerivationService`, `EncryptionService`, `AuthService` written and confirmed failing before implementation. | ✅ PASS |
| V. Offline-First, Privacy & Encryption | No network calls. SQLCipher v4 cipher format via `sqlite3_multiple_ciphers` (constitution mandates "SQLCipher AES-256" — same on-disk format). Master key independent of PIN. PBKDF2 ≥ 500k iterations. AES-256-GCM with `flutter_secure_storage` for envelope. Lockout enforced before any decryption. No plaintext crypto material logged. | ✅ PASS |
| VI. Financial UX Clarity | Dark theme inherited. Keyboard navigation (Tab/Enter) covered by FR-009. WCAG AA contrast: applies the same theme as the rest of the app, which is already AA. PIN input widget designed to swap desktop keyboard for Android keypad without screen redesign (Decision 6). | ✅ PASS |
| VII. Simplicity | Three new dependencies — each justified in research.md (Decisions 1, 2, 3). No premature abstractions: `PinInputBackend` strategy exists only because we have two concrete platforms in the foreseeable future (Constitution Principle VII guidance). | ✅ PASS |

> **Result**: All gates pass. One breaking change (`AppDatabase` constructor)
> documented in Complexity Tracking — not a violation, just the migration
> note required by the Development Workflow rule.

## Project Structure

### Documentation (this feature)

```text
specs/013-pin-auth-encryption/
├── plan.md                          # This file
├── research.md                      # Phase 0 — 10 technical decisions
├── data-model.md                    # Phase 1 — entities and state machine
├── quickstart.md                    # Phase 1 — manual validation guide
├── contracts/
│   ├── auth-service.md              # Service interfaces + test contracts
│   └── routing-and-startup.md       # main.dart and routing changes
├── checklists/
│   └── requirements.md              # From /speckit.specify
├── spec.md                          # Feature spec (3 stories, 20 FRs)
└── tasks.md                         # Phase 2 — generated by /speckit.tasks
```

### Source Code (monorepo root: `my_apps/`)

```text
my_apps/packages/shared_services/
├── pubspec.yaml                            # MODIFIED — drift bump, sqlite3_multiple_ciphers, flutter_secure_storage, cryptography
├── lib/
│   ├── shared_services.dart                # MODIFIED — export new auth/
│   └── src/
│       ├── database/
│       │   └── app_database.dart           # MODIFIED — accepts masterKey, sets PRAGMA key
│       └── auth/                           # NEW
│           ├── auth_service.dart           # Orchestrator
│           ├── auth_state.dart             # Sealed class
│           ├── auth_envelope.dart          # Value type
│           ├── lockout_state.dart          # Value type
│           ├── lockout_policy.dart         # Pure exponential math
│           ├── key_derivation_service.dart # PBKDF2-SHA256 (cryptography)
│           ├── encryption_service.dart     # AES-256-GCM (cryptography)
│           └── secure_storage_service.dart # flutter_secure_storage wrapper
└── test/
    └── auth/                               # NEW
        ├── lockout_policy_test.dart        # 10 exact assertions
        ├── key_derivation_service_test.dart
        ├── encryption_service_test.dart
        ├── auth_service_test.dart          # 10 scenarios from contracts/
        └── fakes/
            └── in_memory_secure_storage.dart

my_apps/apps/sfinance/
├── lib/
│   ├── main.dart                           # MODIFIED — bootstrap auth before runApp; delete pre-existing unencrypted DB
│   ├── providers/
│   │   ├── auth_provider.dart              # NEW — AuthNotifier, authProvider
│   │   ├── database_provider.dart          # MODIFIED — depends on masterKeyProvider
│   │   └── master_key_provider.dart        # NEW — fail-fast guard
│   ├── routing/
│   │   └── app_router.dart                 # MODIFIED — routerProvider with redirect
│   └── ui/
│       └── auth/                           # NEW
│           ├── pin_setup_screen.dart
│           ├── pin_entry_screen.dart
│           ├── lockout_screen.dart
│           ├── bootstrap_screen.dart
│           ├── fatal_error_screen.dart
│           └── widgets/
│               └── pin_input_widget.dart
└── test/
    └── ui/
        └── auth/                           # NEW (widget tests)
            ├── pin_setup_screen_test.dart
            └── pin_entry_screen_test.dart
```

**Structure Decision**: SFinance is a Flutter desktop app inside a Melos
monorepo (existing layout). Cross-app reusable security plumbing
(`auth_service`, key derivation, encryption, secure storage wrapper)
goes in `packages/shared_services/lib/src/auth/`. UI screens are
SFinance-specific and live in `apps/sfinance/lib/ui/auth/`. Riverpod
providers stay in the app (`apps/sfinance/lib/providers/`) per the
existing convention.

## Complexity Tracking

| Item | Why Needed | Simpler Alternative Rejected Because |
|------|------------|-------------------------------------|
| **Breaking change**: `AppDatabase()` no-arg constructor removed; new signature is `AppDatabase(Uint8List masterKey)` | The DB cannot be opened until the master key is in memory. Existing call sites (`databaseProvider`, `migration_v2_test`, etc.) must update. | Defaulting `masterKey` to a hardcoded value would defeat encryption. Wrapping the DB in a lazy-key adapter would push the breaking change one layer down without removing it — and add an indirection (Principle VII). |
| **Drift upgrade** `^2.20.0 → ^2.32.0` | Required for `sqlite3_multiple_ciphers` integration (research.md Decision 1). | Staying on 2.20.x means using the deprecated `sqlcipher_flutter_libs`, which has unresolved Windows build issues (Decision 1). |
| **Three new packages** (`sqlite3_multiple_ciphers`, `flutter_secure_storage`, `cryptography`) | Encryption, secure storage, and pure-Dart crypto are constitutional mandates. Each is the well-maintained, widely-used choice in its category (research.md Decisions 1–3). | No subset of these can be dropped without violating Principle V. Replacing any one with a roll-our-own equivalent would expand attack surface and review burden. |
| **`PinInputBackend` strategy in `pin_input_widget.dart`** | The spec explicitly mandates a structure that supports adding the Android keypad without redesign. | Two duplicate screens (one per platform) would diverge in error handling, theming, and keyboard navigation. A single `if (Platform.isAndroid)` branch inside the widget would put platform branching in UI code (Principle III). |

## Phase 0 — Outline & Research

✅ **Complete**. See [research.md](./research.md).

10 technical decisions recorded:
1. SQLite encryption library: `sqlite3_multiple_ciphers` (NOT `sqlcipher_flutter_libs`).
2. Crypto package: `cryptography` (NOT `pointycastle` or `cryptography_flutter`).
3. Secure storage: `flutter_secure_storage`.
4. Routing: `routerProvider` with `redirect` and `refreshListenable`.
5. DB opening: deferred until after auth; `databaseProvider` depends on `masterKeyProvider`.
6. PIN widget: `PinInputBackend` strategy for desktop/Android extensibility.
7. Lockout math: `pow(5, blockNumber - 1)` minutes; absolute UTC expiry.
8. Test seam: in-memory `SecureStorageService` fake for unit tests.
9. Existing unencrypted DB: deleted on first launch (per spec assumption).
10. DateTime serialization: UTC ISO-8601.

## Phase 1 — Design & Contracts

✅ **Complete**. See:

- [data-model.md](./data-model.md) — `AuthEnvelope`, `LockoutState`,
  `MasterKey`, `AuthState`, with validation rules and the lockout state
  machine.
- [contracts/auth-service.md](./contracts/auth-service.md) — Public API
  for `KeyDerivationService`, `EncryptionService`, `SecureStorageService`,
  `LockoutPolicy`, `AuthService`. Includes the exact test scenarios that
  drive the test-first implementation.
- [contracts/routing-and-startup.md](./contracts/routing-and-startup.md)
  — Modified `main.dart`, the new `routerProvider`, the post-auth
  one-shot for `RecurringGenerationService`, and the fail-fast guard on
  `masterKeyProvider`.
- [quickstart.md](./quickstart.md) — Seven validation passes covering
  US1, US2, US3, lockout persistence, file-level encryption check,
  loading state, and secure-storage absence.

## Constitution Re-Check (post-Phase 1)

All seven principles re-checked against the design artifacts:

| Principle | Re-check |
|-----------|----------|
| I. Monorepo | Auth services in `shared_services` ✅. Breaking change documented ✅. |
| II. Riverpod | All providers globally scoped ✅. `AuthNotifier` is the single mutator of `AuthState` ✅. |
| III. UI/Logic | All security logic in `shared_services` ✅. Widgets only call notifier methods ✅. |
| IV. Test-First | `auth-service.md` lists exact test scenarios — they will be written and confirmed failing before any implementation task. ✅ |
| V. Privacy & Encryption | Master key independent of PIN ✅. PBKDF2 500k iterations ✅. AES-256-GCM ✅. `flutter_secure_storage` for envelope and lockout ✅. Lockout pre-decryption ✅. No plaintext crypto material in any file/log path. ✅ |
| VI. UX Clarity | Dark theme + keyboard navigation enforced by `pin_input_widget.dart`. Touch-compatible structure preserved via `PinInputBackend`. ✅ |
| VII. Simplicity | Each new dep justified ✅. No premature abstractions beyond the one explicitly mandated by spec (PIN input strategy). ✅ |

**Result**: PASS. Ready for `/speckit.tasks`.

## What this command did NOT do

- Did not create `tasks.md`. That is the next command's job.
- Did not modify any source code under `my_apps/`.
- Did not run `flutter pub get` or upgrade Drift. The dependency changes
  listed in Technical Context are recorded for the implementation phase.
