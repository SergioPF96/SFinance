# Data Model: PIN Authentication & Database Encryption

**Feature**: 013-pin-auth-encryption
**Date**: 2026-05-04
**Last revised**: 2026-05-04 (envelope simplified, JSON-blob storage)

This feature does **not** add any new tables to the SQLite (Drift) schema —
the schema version stays at `4`. All new persistent data lives in
`flutter_secure_storage` (platform-isolated key/value store) so it is
accessible while the database is locked.

## Persistent storage layout

Two values, both serialized as JSON strings.

```
KEY                VALUE
auth.envelope      {"salt":"<hex>","encryptedMasterKey":"<b64>","gcmNonce":"<b64>","gcmTag":"<b64>"}
auth.lockout       {"failedAttempts":<int>,"expiresAt":"<UTC ISO-8601>"|null}
```

Either key may be absent:
- **`auth.envelope` absent** → fresh install, `AuthState.needsSetup`.
- **`auth.lockout` absent or `failedAttempts == 0`** → no lockout state.

PBKDF2 iteration count (`500_000`) is a hardcoded constant in
`KeyDerivationService` — not stored in the envelope.

## Entities

### AuthEnvelope (persisted as JSON under `auth.envelope`)

| Field | Type | Encoding | Notes |
|---|---|---|---|
| `salt` | bytes (16) | hex string | Random per-install. Used as PBKDF2 salt. |
| `encryptedMasterKey` | bytes (32) | base64 | Master Key after AES-256-GCM encryption with the PIN-derived key. |
| `gcmNonce` | bytes (12) | base64 | Random per-encryption nonce (IV). |
| `gcmTag` | bytes (16) | base64 | Authentication tag from AES-GCM. Mismatch on decrypt → wrong PIN. |

**Validation rules**:
- All four fields MUST be present together. JSON parse failure or any
  missing field → corrupted state → `AuthState.fatalError`.
- `salt` and `gcmNonce` MUST be from `Random.secure()`.

**Lifecycle**:
- *First launch*: created during PIN setup. No prior envelope exists.
- *Every launch thereafter*: read at app start; PIN verifies it.
- *Never modified after creation* in this phase. (PIN change, out of scope,
  would re-wrap the same Master Key with a new salt + GCM tag.)

### LockoutState (persisted as JSON under `auth.lockout`)

| Field | Type | Encoding | Notes |
|---|---|---|---|
| `failedAttempts` | int | JSON number | Total consecutive failed PIN attempts since the last success. Resets to 0 on successful auth. |
| `expiresAt` | DateTime? | UTC ISO-8601 string, or `null` | When the current lockout ends. `null` if not currently locked out. |

**Derived fields** (not stored):
- `currentBlock = floor(failedAttempts / 3)` — 0 means "no block yet."
- `isLockedOut = expiresAt != null && DateTime.now().toUtc() < expiresAt`
- `nextLockoutMinutes = pow(5, currentBlock - 1).toInt()` — only meaningful when triggering a new lockout.

**Validation rules**:
- `failedAttempts` MUST be `>= 0`.
- When `expiresAt` is non-null, `failedAttempts` MUST be a positive
  multiple of 3.
- `expiresAt` is compared to UTC, never local time.

**Lifecycle / state transitions**:

```text
[clean]                                  failedAttempts=0,    expiresAt=null
   │
   │ wrong PIN (1st of block)
   ▼
[failing-1]                              failedAttempts=1,    expiresAt=null
   │
   │ wrong PIN
   ▼
[failing-2]                              failedAttempts=2,    expiresAt=null
   │
   │ wrong PIN (3rd → block triggered)
   ▼
[locked-out, block=1, 1 min]             failedAttempts=3,    expiresAt=now+1min
   │
   ├─ correct PIN attempted → REJECTED (still locked) → state unchanged
   │
   │ countdown elapses, user enters wrong PIN again
   ▼
[failing-4]                              failedAttempts=4,    expiresAt=null
   │   (no new lockout until 6th total)
   │
   │ wrong PIN ×2 (5th, 6th)
   ▼
[locked-out, block=2, 5 min]             failedAttempts=6,    expiresAt=now+5min
   │
   ├─ correct PIN
   ▼
[clean]                                  failedAttempts=0,    expiresAt=null
```

### MasterKey (in-memory only)

| Field | Type | Notes |
|---|---|---|
| `bytes` | `Uint8List(32)` | The 256-bit key. NEVER serialized in plaintext. |

**Lifecycle**:
- Generated once at first launch via `Random.secure()`.
- Held in memory by `AuthService` after successful unlock.
- Used to open the Drift database via `PRAGMA key = "x'<hex>'";`.
- Cleared from memory on app termination. No explicit "logout" in this phase.

### AuthState (in-memory, exposed by Riverpod)

A discriminated union representing the auth provider's current state.
Defined as a sealed class:

```text
sealed class AuthState {
  bootstrapping     // app just launched, services initializing
  needsSetup        // no envelope present → first launch
  needsAuth         // envelope present, awaiting PIN
  verifying         // PIN submitted, PBKDF2 running
  authenticated     // master key recovered, DB ready
  lockedOut(DateTime expiresAt)
  fatalError(String reason)   // partial/corrupt envelope, no secure storage,
                              //   or pre-existing unencrypted DB present
}
```

State transitions are driven exclusively by `AuthService` method calls;
widgets only observe via `ref.watch(authProvider)`.

## Mapping to Spec Functional Requirements

| FR | Entity / state involved |
|---|---|
| FR-001 — PIN creation before initial balance | `AuthState.needsSetup` → `verifying` → `authenticated` |
| FR-005 — PIN required every launch | Envelope present → `AuthState.needsAuth` |
| FR-007 — Show remaining attempts | Derived from `LockoutState.failedAttempts` |
| FR-010 / FR-011 — Lockout policy | `LockoutState` + lockout transition above |
| FR-012 — Lockout persists | `LockoutState` JSON blob in `flutter_secure_storage` |
| FR-013 — Counter reset on success | `LockoutState.failedAttempts` set to 0 |
| FR-015 — Data unreadable without PIN | DB opened only when `AuthState.authenticated` |
| FR-016 — Biometric extensibility | A future "biometric envelope" can coexist alongside `auth.envelope` (no schema change required to add it) |
| FR-018 — Secure storage unavailable | `AuthState.fatalError` |
| FR-019 — Master key distinct from PIN | `MasterKey` is independent of PIN; PIN only derives a wrapping key |
| FR-020 — Loading during verification | `AuthState.verifying` |

## What is NOT in this data model

- **Drift schema**: unchanged. Schema version stays `4`. The DB is opened
  with the same migration logic; only the `setup` callback (PRAGMA key)
  is added.
- **Plaintext PIN storage**: never. The PIN is held in memory only inside
  `AuthService.verify(pin)` for the duration of the PBKDF2 derivation,
  then cleared.
- **Derived (PBKDF2) wrapping key**: never persisted. Computed fresh on
  every unlock and discarded after the master key is recovered.
- **`iterations` and `version` fields**: deliberately not stored
  (Decision 12 in research.md). Iteration count is a constant; envelope
  format changes will be migrations when they happen.
