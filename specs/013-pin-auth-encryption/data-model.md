# Data Model: PIN Authentication & Database Encryption

**Feature**: 013-pin-auth-encryption
**Date**: 2026-05-04

This feature does **not** add any new tables to the SQLite (Drift) schema —
the schema version stays at `4`. All new persistent data lives in
`flutter_secure_storage` (platform-isolated key/value store) so it is
accessible while the database is locked.

## Entities

### AuthEnvelope (persisted in `flutter_secure_storage`)

The artifact that binds the user's PIN to the Master Key. Created at first
launch; read on every subsequent launch.

| Field | Type | Encoding | Notes |
|---|---|---|---|
| `salt` | bytes (16) | hex string | Random per-install. Used as PBKDF2 salt. |
| `iterations` | int | decimal string | Stored to allow future iteration count bumps without breaking existing installs. Initial value: `500000`. |
| `encryptedMasterKey` | bytes (32) | base64 | Master Key after AES-256-GCM encryption with the PIN-derived key. |
| `gcmNonce` | bytes (12) | base64 | Random per-encryption nonce (IV). |
| `gcmTag` | bytes (16) | base64 | Authentication tag from AES-GCM. Mismatch on decrypt → wrong PIN. |
| `version` | int | decimal string | Envelope schema version. Initial: `1`. Allows future format changes (e.g., adding biometric wrapping). |

**Validation rules**:
- All fields MUST be present together. Partial envelope = corrupted state →
  reinstall path (Edge Case in spec).
- `salt` and `gcmNonce` MUST be from `Random.secure()`.
- `iterations` MUST be ≥ 500,000 (Constitution Principle V minimum).

**Lifecycle**:
- *First launch*: created during PIN setup. No prior envelope exists.
- *Every launch thereafter*: read at app start; PIN verifies it.
- *Never modified after creation* in this phase. (PIN change, out of scope,
  would re-wrap the same Master Key with a new salt + GCM tag.)

**Storage keys** (`flutter_secure_storage` key names):

```
auth.envelope.salt
auth.envelope.iterations
auth.envelope.encryptedMasterKey
auth.envelope.gcmNonce
auth.envelope.gcmTag
auth.envelope.version
```

### LockoutState (persisted in `flutter_secure_storage`)

| Field | Type | Encoding | Notes |
|---|---|---|---|
| `failedAttempts` | int | decimal string | Total consecutive failed PIN attempts since the last success. Resets to 0 on successful auth. |
| `lockoutExpiresAt` | DateTime? | UTC ISO-8601 or absent | When the current lockout ends. Absent if not currently locked out. |

**Derived fields** (not stored):
- `currentBlock = floor(failedAttempts / 3)` — 0 means "no block yet."
- `isLockedOut = lockoutExpiresAt != null && DateTime.now().toUtc() < lockoutExpiresAt`
- `nextLockoutMinutes = pow(5, currentBlock - 1).toInt()` — only meaningful when triggering a new lockout.

**Validation rules**:
- `failedAttempts` MUST be `>= 0`.
- When `lockoutExpiresAt` is set, `failedAttempts` MUST be a positive
  multiple of 3.
- The `lockoutExpiresAt` value MUST be checked against current wall-clock
  UTC, not against `DateTime.now()` in local time.

**Lifecycle / state transitions**:

```text
[clean]                                  failedAttempts=0,    expiry=null
   │
   │ wrong PIN (1st of block)
   ▼
[failing-1]                              failedAttempts=1,    expiry=null
   │
   │ wrong PIN
   ▼
[failing-2]                              failedAttempts=2,    expiry=null
   │
   │ wrong PIN (3rd → block triggered)
   ▼
[locked-out, block=1, 1 min]             failedAttempts=3,    expiry=now+1min
   │
   ├─ correct PIN attempted → REJECTED (still locked) → state unchanged
   │
   │ countdown elapses, user enters wrong PIN again
   ▼
[failing-4]                              failedAttempts=4,    expiry=null
   │   (no new lockout until 6th total)
   │
   │ wrong PIN ×2 (5th, 6th)
   ▼
[locked-out, block=2, 5 min]             failedAttempts=6,    expiry=now+5min
   │
   ├─ correct PIN
   ▼
[clean]                                  failedAttempts=0,    expiry=null
```

**Storage keys**:

```
auth.lockout.failedAttempts
auth.lockout.expiresAt        (omitted when not locked out)
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
  fatalError(String reason)   // e.g., partial/corrupt envelope, no secure storage
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
| FR-012 — Lockout persists | `LockoutState` in `flutter_secure_storage` |
| FR-013 — Counter reset on success | `LockoutState.failedAttempts` set to 0 |
| FR-015 — Data unreadable without PIN | DB opened only when `AuthState.authenticated` |
| FR-016 — Biometric extensibility | `AuthEnvelope.version` field reserved for future biometric wrap |
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
