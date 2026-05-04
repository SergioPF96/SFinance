# Quickstart: PIN Authentication & Database Encryption

**Feature**: 013-pin-auth-encryption
**Audience**: Sergio (validating manually after implementation)

This is the manual end-to-end validation guide. Run it on Windows desktop
after `melos run test` and `flutter analyze` are green.

## Prerequisites

- All tasks in `tasks.md` are complete.
- `melos run test` passes.
- A clean run target: delete `%APPDATA%\com.example.sfinance\` and any
  `%LOCALAPPDATA%\sfinance\` data directory before starting.
- Wipe `flutter_secure_storage` for the app: on Windows this is the
  `Credential Manager` entry under "Generic Credentials" with prefix
  `sfinance`. Delete those entries.

## Validation 1 — First-launch PIN setup (US1, P1)

**Steps**:
1. Launch the app fresh.
2. Confirm: the **only** screen visible is the PIN setup screen. No
   `/resumen`, `/analisis`, `/entradas` content is rendered behind it.
3. Confirm the screen shows two PIN entry fields and a prominent warning
   stating the PIN cannot be recovered.
4. Type `1234` in the first field. Press Tab. Type `1235` in the second.
5. Press Enter.
6. **Expect**: a clear mismatch error appears. Both fields clear.
7. Type `1234` in both fields. Press Enter.
8. **Expect**: brief loading indicator (~1–2 s). Then the initial balance
   dialog appears (unchanged from prior behavior).
9. Set an initial balance (e.g., `1000.00 €`). Confirm.
10. **Expect**: home screen `/resumen` renders.

**Pass criteria**:
- Steps 6 and 8 behave exactly as described.
- After step 9, you can navigate to `/entradas` and `/analisis` normally.
- Closing and reopening the app proceeds to Validation 2 (PIN required).

## Validation 2 — Subsequent-launch authentication (US2, P2)

**Pre-state**: PIN already set up (from Validation 1).

**Steps**:
1. Close the app fully.
2. Relaunch.
3. **Expect**: PIN entry screen is the **first** thing rendered. No
   financial data is visible (check for any flicker — there should be
   none).
4. Type `1234`. Wait for the auto-submit on the 4th digit.
5. **Expect**: loading indicator briefly visible, PIN field disabled
   during this period.
6. **Expect**: home screen renders, with the same data as before close.

**Pass criteria**:
- Step 3: no flash of unauthorized content (FUOC). Use a slow
  framerate emulator if needed (`flutter run --enable-software-rendering`)
  to confirm no transient render of `/resumen` before the redirect kicks in.
- Step 5: PIN input is visibly disabled (not just non-functional —
  the cursor or visual state must indicate disabled).
- Step 6: previously entered transactions, balances, and recurring
  templates are all present and correct.

## Validation 3 — Lockout enforcement (US3, P3)

**Pre-state**: PIN already set up.

**Steps**:
1. Launch the app.
2. On the PIN screen, enter `0000`. Submit.
3. **Expect**: error "Wrong PIN. 2 attempts remaining" (or equivalent
   Spanish wording), input clears.
4. Enter `0001`. Submit.
5. **Expect**: error showing 1 attempt remaining.
6. Enter `0002`. Submit.
7. **Expect**: immediate transition to lockout screen with **1 minute**
   countdown. PIN entry is gone or disabled.
8. Note the start time. Wait 1 minute.
9. **Expect**: countdown reaches 0 and PIN entry is re-enabled.
10. Enter `0003`, `0004`, `0005` (3 more wrong PINs).
11. **Expect**: 5-minute lockout (block 2).
12. Wait or, for fast verification, terminate the app, modify your system
    clock forward by 5 minutes, and relaunch.
13. **Expect**: PIN entry re-enabled.
14. Enter the correct PIN `1234`.
15. **Expect**: home screen renders. Counter reset.
16. Now enter wrong PIN 3 times again.
17. **Expect**: 1-minute lockout (block 1, NOT block 3 — counter reset by
    step 14).

**Pass criteria** (matching SC-003, SC-005, SC-006, SC-007):
- Step 7: lockout screen appears within 1 second of submitting the 3rd
  wrong PIN.
- Step 11: lockout duration is exactly 5 minutes.
- Step 13: lockout is honored across app restart and clock adjustment.
- Step 17: counter reset after success → block 1 again.

## Validation 4 — Lockout persists across crash (Edge Case)

**Pre-state**: PIN set up, no current lockout.

**Steps**:
1. Launch app, enter 3 wrong PINs to trigger 1-minute lockout.
2. Force-kill the app (Task Manager → End Task). Do NOT use a clean exit.
3. Within the 1 minute, relaunch.
4. **Expect**: lockout screen appears immediately, with the **remaining**
   countdown (less than 1 min, depending on how fast you relaunched).

**Pass criteria**: countdown picks up where it left off based on
wall-clock time, not from 0.

## Validation 5 — Database is unreadable without correct PIN (FR-015)

**Steps**:
1. Set up the app with PIN `1234`. Add a transaction with amount
   `99.99`.
2. Close the app.
3. Locate the database file at `%APPDATA%\com.example.sfinance\sfinance.sqlite`
   (path may vary — check `getApplicationDocumentsDirectory`).
4. Open the file in any SQLite browser (DB Browser for SQLite, etc.) **without** a
   passphrase.
5. **Expect**: the browser reports "file is not a database" or similar.
   You CANNOT read `99.99` from the file in plaintext.
6. Run `xxd` (or PowerShell `Format-Hex`) on the first 100 bytes of the
   file. **Expect**: high-entropy binary, NOT the SQLite magic header
   `53 51 4C 69 74 65 20 66 6F 72 6D 61 74` ("SQLite format 3").

**Pass criteria**: encryption is verifiable at the file level.

## Validation 6 — Loading indicator is shown during PBKDF2 (FR-020)

**Steps**:
1. Launch the app at the PIN entry screen.
2. Submit any 4-digit PIN.
3. Visually confirm: a spinner or progress indicator appears
   immediately, the PIN input is disabled, and remains disabled until the
   verification completes (~1–2 s).

**Pass criteria**: no UI freeze, no janky frames during verification
(check `flutter run --profile` for frame stats if you want to be
exhaustive).

## Validation 7 — Secure storage absent → fatal error (FR-018)

**Steps**:
1. On Windows, temporarily revoke access to the Credential Manager (or
   simulate by injecting a `SecureStorageService` that returns
   `isAvailable() == false`).
2. Launch the app.
3. **Expect**: a clear error screen explaining secure storage is
   unavailable, with no fallback to unprotected operation.

This validation may be easier as an integration test than a manual run.

## Validation 8 — Pre-existing unencrypted DB → fatal error (Decision 9)

**Pre-state**: a freshly-wiped install (no envelope in secure storage)
plus an old plaintext `sfinance.sqlite` file still present from a
pre-encryption build.

**Setup**:
1. Wipe the Credential Manager entries (no envelope).
2. Place a non-empty plaintext SQLite file at
   `%APPDATA%\com.example.sfinance\sfinance.sqlite` (e.g., copy one from
   a checkout of branch `011-quick-expenses`).
3. Launch the app.

**Expect**:
- A fatal error screen is shown immediately.
- The screen names the absolute path of the offending file.
- The screen instructs the user to delete the file manually and relaunch.
- The app does **not** auto-delete the file. Verify the file is still
  on disk after closing the app.
- After manually deleting the file and relaunching, the app proceeds to
  the PIN setup screen normally.

**Pass criteria**: no destructive action taken by the app, no silent data
loss possible.

## Final checklist

- [ ] All 7 validations pass on Windows desktop.
- [ ] `melos run test` is green.
- [ ] `flutter analyze` shows no warnings.
- [ ] No `print()` or `debugPrint()` statements log any PIN, derived
      key, master key bytes, salt, GCM tag, envelope, or lockout state.
- [ ] No new `// TODO` comments remain in the auth-related code.
