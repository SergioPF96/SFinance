# Feature Specification: PIN Authentication & Database Encryption

**Feature Branch**: `013-pin-auth-encryption`
**Created**: 2026-05-04
**Status**: Draft
**Input**: User description: "Add PIN-based authentication and full-database encryption to SFinance."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Launch PIN Setup (Priority: P1)

A first-time user opens the app for the first time. Before any financial data
entry, the app requires them to create a 4-digit PIN. They enter the PIN once,
then confirm it by entering it a second time. If the two entries match, the PIN
is accepted. The user is prominently and explicitly warned that this PIN cannot
be recovered and that losing it means permanent, irrecoverable loss of all
their data. After the PIN is confirmed, the app proceeds to the existing
initial balance screen.

**Why this priority**: This is the security foundation. No user can proceed to
data entry, and no returning user can be authenticated, without this setup step
completing successfully. All other stories depend on it.

**Independent Test**: Install the app fresh, launch it, complete PIN setup with
two matching entries, verify the irrecoverability warning is shown prominently,
and confirm the app navigates to the initial balance screen upon success.

**Acceptance Scenarios**:

1. **Given** the app is launched for the first time, **When** the PIN setup
   screen appears, **Then** two separate PIN entry fields (enter and confirm)
   are shown, a prominent irrecoverability warning is displayed, and the
   confirm action is disabled until both fields contain exactly 4 digits.
2. **Given** both PIN fields contain the same 4-digit value, **When** the user
   confirms, **Then** the app stores the authentication data and navigates to
   the initial balance screen.
3. **Given** the PIN entries in the two fields do not match, **When** the user
   attempts to confirm, **Then** the app displays a clear mismatch error and
   clears both fields so the user can start over.
4. **Given** either field contains fewer than 4 digits, **When** the user
   attempts to confirm, **Then** the app prevents submission and shows a
   validation message.
5. **Given** the PIN setup screen is open on desktop, **When** the user presses
   Tab, **Then** focus moves between the two entry fields; pressing Enter
   triggers the confirm action.

---

### User Story 2 - Launch Authentication (Priority: P2)

On every launch after initial setup, the user sees a PIN entry screen before
any financial data is visible or accessible. They type their 4-digit PIN using
the keyboard. On a correct PIN, the app unlocks and shows the home screen. On
an incorrect PIN, an error is shown and the attempt is counted toward lockout.

**Why this priority**: This is the primary daily security interaction for all
returning users. Without it, the data protection set up in US1 has no
enforcement at runtime.

**Independent Test**: Close and reopen the app after setup. Verify the PIN
screen appears before any financial data and that entering the correct PIN
grants full access.

**Acceptance Scenarios**:

1. **Given** the app has been set up with a PIN, **When** the app launches,
   **Then** a PIN entry screen is the first thing shown — no financial data,
   navigation, or balances are visible behind it.
2. **Given** the PIN entry screen is shown, **When** the user types the correct
   4-digit PIN, **Then** the app unlocks and displays the home screen.
3. **Given** the PIN entry screen is shown, **When** the user types an incorrect
   PIN and submits, **Then** the input clears, an error is shown, and the number
   of remaining attempts before lockout is displayed.
4. **Given** the app is unlocked in the current session, **When** the user
   minimizes and restores the app, **Then** no re-authentication is required
   (the session stays unlocked until the app process ends).
5. **Given** the PIN entry screen is open on desktop, **When** the user types
   4 digits, **Then** the PIN is submitted automatically; pressing Enter also
   triggers submission.
6. **Given** the user has submitted their PIN, **When** verification is in
   progress, **Then** a loading indicator is shown, the PIN field and submit
   action are disabled, and they remain disabled until the outcome is known.

---

### User Story 3 - Lockout After Consecutive Failures (Priority: P3)

After 3 consecutive incorrect PIN attempts, the user is locked out and must
wait before trying again. A countdown is shown. Lockout duration grows
exponentially with each block of 3 failures (×5 per block). The counter resets
after a successful authentication.

**Why this priority**: Without lockout enforcement, an attacker with physical
device access could systematically try every possible 4-digit combination.
This story closes that brute-force attack vector.

**Independent Test**: Enter an incorrect PIN 3 times in a row, verify the
lockout screen appears with a 1-minute countdown, wait for expiry, verify
input re-enables, then authenticate successfully and verify the counter resets.

**Acceptance Scenarios**:

1. **Given** 3 consecutive incorrect PINs have been entered, **When** the 3rd
   failure is submitted, **Then** PIN input is immediately disabled and a
   lockout countdown of 1 minute is shown.
2. **Given** the user is in a lockout period, **When** the countdown expires,
   **Then** the PIN entry field is re-enabled and the user may attempt again.
3. **Given** the user completes a 1st lockout and fails 3 more times (6 total
   consecutive failures), **When** the 6th failure is submitted, **Then** the
   next lockout duration is 5 minutes (second block).
4. **Given** the user is locked out and closes then reopens the app, **When**
   the app launches, **Then** the lockout state and remaining countdown are
   fully preserved (lockout is not reset by restarting).
5. **Given** the user was previously locked out and then authenticated
   successfully, **When** they enter an incorrect PIN again, **Then** the
   failure counter starts from 1 (the block resets on successful auth).
6. **Given** the user is in a lockout period, **When** they view the screen,
   **Then** a clear message explains the wait time and makes clear that no data
   is accessible during this period.

---

### Edge Cases

- What if the app crashes mid-lockout? On restart, the lockout state (remaining
  time and failure count) is restored; the countdown continues from where it
  left off based on wall clock time, not app uptime.
- What if only non-digit characters are typed on the PIN screen? All non-digit
  input is silently ignored; only digits 0–9 are accepted.
- What if the authentication envelope (the stored data linking PIN to
  protected data) is missing or corrupted on launch? The app detects this,
  displays an unrecoverable error explaining all data is permanently lost, and
  prompts the user to reinstall to start fresh.
- What if the user attempts to navigate to financial data before completing PIN
  setup? This is not possible — no financial routes or data are reachable until
  authentication is complete.
- What if secure device storage is unavailable on the platform? The app cannot
  start securely and MUST display a clear error explaining that data protection
  is unavailable, rather than falling back to unprotected operation.
- What if a lockout block results in an extremely long wait (e.g., after many
  consecutive failure blocks)? The countdown display must handle arbitrarily
  large durations correctly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On first launch, the app MUST present a PIN creation screen
  before the existing initial balance screen. This step cannot be skipped.
- **FR-002**: The PIN creation screen MUST require the user to enter a 4-digit
  numeric PIN and then confirm it by entering the same PIN a second time.
- **FR-003**: The PIN creation screen MUST display a prominent, explicit warning
  that the PIN cannot be recovered and that losing it means permanent,
  irrecoverable loss of all financial data.
- **FR-004**: PIN creation MUST be rejected if the two entries do not match;
  both fields MUST be cleared and the user shown a clear mismatch error.
- **FR-005**: On every launch after initial setup, the app MUST display a PIN
  authentication screen before any financial data is accessible or rendered.
  There is no "remember session" option across launches.
- **FR-006**: Correct PIN entry MUST unlock the app and grant access to all
  financial screens for the duration of that session.
- **FR-007**: Incorrect PIN entry MUST display an error, clear the input, and
  show the number of remaining attempts before lockout.
- **FR-008**: The PIN entry screen MUST accept numeric keyboard input on
  desktop. Entering 4 digits MUST submit automatically; pressing Enter MUST
  also submit.
- **FR-009**: Tab key navigation MUST cycle through all interactive elements on
  both the PIN creation and authentication screens; Enter MUST trigger the
  primary action.
- **FR-010**: After 3 consecutive failed PIN attempts, PIN entry MUST be
  immediately disabled and a lockout countdown screen MUST be shown.
- **FR-011**: Lockout durations MUST follow an exponential progression: 1 min
  after block 1, 5 min after block 2, 25 min after block 3, 125 min after
  block 4, and so on (×5 per block).
- **FR-012**: Lockout state (failure count and lockout expiry time) MUST
  persist across app restarts, crashes, and device reboots. It MUST be stored
  independently of the Protected Data Store, since the data store is
  inaccessible during lockout.
- **FR-013**: Successful PIN authentication MUST reset the consecutive failure
  counter to zero.
- **FR-014**: The app MUST provide no PIN recovery mechanism of any kind — no
  hints, no reset flow, no backup codes, no secondary verification.
- **FR-015**: All financial data MUST be protected such that it cannot be read
  without the correct PIN, even with direct filesystem or storage access to the
  device.
- **FR-016**: The security architecture MUST support adding biometric
  authentication in a future phase using the same underlying protection
  mechanism, without altering stored protected data or requiring data
  migration.
- **FR-017**: The PIN creation and authentication screens MUST follow the same
  dark visual theme as the rest of the app.
- **FR-018**: If the device's secure storage is unavailable, the app MUST
  display a clear error and MUST NOT fall back to unprotected operation.
- **FR-019**: The Protected Data Store MUST be opened by a Master Key that is
  distinct from the user's PIN. The Master Key MUST be generated once at first
  launch; the PIN MUST NOT directly open the Protected Data Store.
- **FR-020**: While PIN verification is in progress (after submission), the app
  MUST display a loading indicator, disable the PIN input field and submit
  action, and keep them disabled until the verification result is known.

### Key Entities

- **PIN**: A 4-digit numeric code (digits 0–9 only) chosen by the user at
  first launch. Used only transiently during authentication to verify identity
  and gain access to protected data. Never stored in any form.
- **Master Key**: The secret value that directly opens the Protected Data
  Store. Generated once at first launch and never regenerated. Never stored in
  plaintext; exists only in memory during an authenticated session.
- **Protected Data Store**: The encrypted container holding all financial data
  (accounts, transactions, categories, recurring entries). Opened exclusively
  by the Master Key; accessible only after successful authentication in the
  current session.
- **Authentication Session**: The in-memory state indicating the current
  session is authenticated. Exists only while the app process is running;
  cleared on app termination.
- **Authentication Envelope**: The stored artifact that binds the user's PIN
  to the Master Key. Contains the Master Key in encrypted form, the
  verification data, and the derivation parameters (a random value generated
  at PIN creation time). Kept in the device's isolated secure storage area,
  separate from the Protected Data Store. Contains no plaintext credentials.
- **Lockout State**: Persistent record of the count of consecutive failed
  attempts and, when a lockout is active, the exact time the current lockout
  expires. Stored in the device's isolated secure storage area (not the
  Protected Data Store) so it is accessible even when the database is locked.
  Survives app restarts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A first-time user can complete PIN setup (enter, confirm, read
  warning, proceed) in under 90 seconds.
- **SC-002**: A returning user who knows their PIN can unlock the app and reach
  the home screen in under 15 seconds from launch.
- **SC-003**: After exactly 3 consecutive failed attempts, the lockout screen
  appears within 1 second and remains active for the full lockout duration
  before re-enabling PIN entry.
- **SC-004**: No financial data (balances, transactions, categories) is visible
  or retrievable at any point before successful PIN authentication on that
  launch — verifiable by attempting to access data without authenticating.
- **SC-005**: Lockout state is fully preserved after an app restart: remaining
  countdown continues correctly based on elapsed wall-clock time.
- **SC-006**: Each successive lockout block applies the correct ×5 multiplier —
  verified across at least 4 consecutive lockout blocks.
- **SC-007**: After a successful authentication following a lockout, the next 3
  incorrect attempts trigger a 1-minute lockout (block 1 again), confirming the
  counter reset.

## Assumptions

- A 4-digit numeric PIN is sufficient for the single-user, local-only threat
  model of this app. Users requiring stronger guarantees rely on full-device
  encryption at the OS level.
- The existing initial balance screen (existing onboarding step) is not
  modified by this feature and appears immediately after successful PIN creation,
  exactly as it does today.
- There is no existing production user data to migrate from an unencrypted
  database. The app is in development and this feature treats every install
  as a fresh start.
- Session unlock persists for the lifetime of the running process. Idle
  re-locking (e.g., locking after inactivity) is out of scope for this phase.
- The lockout countdown is based on wall-clock time, not app uptime. Closing
  the app during a lockout does not pause or extend the countdown.
- The Android on-screen numeric keypad is out of scope for this phase. The PIN
  entry widget will be structured to allow swapping the keyboard input mechanism
  for a visual keypad in a future phase without a screen redesign.
- Biometric authentication (Android) is out of scope for this phase. The
  security architecture must support it as a future extension without requiring
  changes to stored protected data.
- PIN change is out of scope for this phase. The Master Key architecture
  inherently supports it in a future phase — re-wrapping the Authentication
  Envelope with a newly derived key — without modifying the Protected Data Store.

## Clarifications

### Session 2026-05-04

- Q: Is PIN setup mandatory on first launch? → A: Yes, it cannot be skipped.
  It is the first step of onboarding, before the initial balance screen.
- Q: Does the user confirm the PIN when creating it? → A: Yes. The user enters
  the PIN twice; both entries must match before the PIN is accepted.
- Q: What format is the PIN? → A: Exactly 4 numeric digits (0–9). No letters
  or special characters.
- Q: What happens if the app is closed and reopened? → A: The PIN must be
  entered on every launch. There is no "remember session" option.
- Q: What is the lockout policy for failed attempts? → A: After every 3
  consecutive failed attempts (one block), the user must wait before retrying.
  Wait times: 1 min (block 1), 5 min (block 2), 25 min (block 3), 125 min
  (block 4), and so on (×5 per block). Counter resets on successful
  authentication.
- Q: Can the PIN be recovered if forgotten? → A: No. There is no recovery
  mechanism of any kind. The user is explicitly warned of this when setting the
  PIN for the first time.
- Q: How is the database encrypted? → A: Full-database encryption via SQLCipher
  (AES-256). A random 32-byte master key is generated at first launch and
  stored encrypted (AES-256-GCM) using a key derived from the PIN via
  PBKDF2-SHA256 with a random 16-byte salt and a minimum of 500,000
  iterations. The master key — not the PIN — opens the database.
- Q: Is biometric authentication in scope? → A: Not for this feature. The
  architecture must support adding it in the Android phase via platform keystore
  without re-encrypting the database.
- Q: How is the PIN entered on each platform? → A: On desktop: standard numeric
  keyboard input. On Android (future): on-screen numeric keypad. The widget
  must be structured to accommodate both without a full rewrite.
- Q: Where is lockout state stored? → A: In flutter_secure_storage, since the
  encrypted database is inaccessible during lockout.
- Q: Can the user change their PIN after initial setup? → A: Explicitly out of
  scope for this phase. The Master Key architecture supports it in a future
  phase (re-wrapping the Authentication Envelope) without re-encrypting the
  database.
- Q: What does the user see while PIN verification is processing? → A: A
  loading indicator is shown and the PIN field and submit action are disabled
  until the result is known.
