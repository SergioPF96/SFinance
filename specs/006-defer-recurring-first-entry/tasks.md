# Tasks: Diferir primera entrada recurrente mensual según día de pago

**Input**: Design documents from `/specs/006-defer-recurring-first-entry/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓

**Tests**: Required by Constitution Principle IV — financial date logic. Tests MUST fail before implementation.

**Organization**: Foundational extraction first; all three P1 user stories share the same implementation change, so tests for all three scenarios are written together before any code is changed.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

- **Shared services**: `my_apps/packages/shared_services/lib/src/generation/`
- **Shared services tests**: `my_apps/packages/shared_services/test/generation/`
- **App services**: `my_apps/apps/sfinance/lib/services/`
- **App providers**: `my_apps/apps/sfinance/lib/providers/`
- **App service tests**: `my_apps/apps/sfinance/test/services/`

---

## Phase 1: Setup

No new infrastructure, dependencies, or schema changes required. `paymentDay` already exists in the `recurring_templates` table from feature 005. Skip to Phase 2.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extract shared computation methods that all user stories and test phases depend on. No behavioral change yet — pure extraction / refactoring.

**⚠️ CRITICAL**: Phases 3–5 cannot begin until this phase is complete.

- [x] T001 Extract `_dateForPeriod()` from `RecurringGenerationService` to `PeriodGenerator` as the public static method `dateForKey(String periodKey, int paymentDay, {int? annualMonth})` in `my_apps/packages/shared_services/lib/src/generation/period_generator.dart`. Logic: monthly key "YYYY-MM" → DateTime(year, month, paymentDay.clamp(1, daysInMonth)); key ending "-extra" strips suffix and uses same month; annual key "YYYY" → DateTime(year, annualMonth!, paymentDay.clamp(1, daysInMonth)).

- [x] T002 Extract the per-template generation loop from `RecurringGenerationService.run()` into a new public static method `generateForTemplate(AppDatabase db, RecurringTemplateRow template, {DateTime? today})` in `my_apps/apps/sfinance/lib/services/recurring_generation_service.dart`. The `run()` method calls `generateForTemplate()` for each active template. `_dateForPeriod()` inside the service is replaced with a call to `PeriodGenerator.dateForKey()`.

**Checkpoint**: Foundation ready. T001 and T002 must pass existing tests unchanged before proceeding.

---

## Phase 3: User Story 1 — Primer pago en el mismo día de hoy (Priority: P1) 🎯 MVP

**Goal**: When `paymentDay` equals today's day-of-month, the first transaction entry is generated immediately on save.

**Independent Test**: Save a monthly recurring template with `paymentDay == today.day`. Verify exactly one transaction entry exists in the DB with today's date after save.

### Tests for User Story 1 ⚠️ WRITE FIRST — must FAIL before T007

- [x] T003 [US1] Write failing test in `my_apps/packages/shared_services/test/generation/period_generator_test.dart`: `computeDueKeys(startDate: April 1, endDate: far-future, periodicity: 'mensual', paymentDay: 16, today: April 16)` → returns `['2026-04']`. This test MUST PASS even before T007 (current PeriodGenerator does include current month). Add it to confirm the scenario stays working after the change.

- [x] T004 [US1] Write test in `my_apps/packages/shared_services/test/generation/period_generator_test.dart`: `computeDueKeys(..., paymentDay: 1, today: April 16)` → returns `['2026-04']` (day 1 < today but already in past; note this is handled by startDate — if startDate = May 1, returns []; if startDate = April 1 and day 1 is in the past, this is the edge case discussed below). Document: PeriodGenerator date filter applies to upcoming-date filtering only; past-date filtering for "already passed this month" is handled by startDate in form providers.

### Implementation for User Story 1

- [x] T005 [US1] Add `int paymentDay = 1` optional named parameter to `PeriodGenerator.computeDueKeys()` in `my_apps/packages/shared_services/lib/src/generation/period_generator.dart`. After generating all month keys via `_generateAllKeys()`, add a filter step: for each key, call `PeriodGenerator.dateForKey(key, paymentDay, annualMonth: endDate.month)` and exclude keys where the resulting date is strictly after `today`. Annual keys are unaffected (annual period handling unchanged).

- [x] T006 [US1] Update `RecurringGenerationService.run()` call to `PeriodGenerator.computeDueKeys()` in `my_apps/apps/sfinance/lib/services/recurring_generation_service.dart` to pass `paymentDay: template.paymentDay ?? 1`. Verify all existing `RecurringGenerationService` tests continue to pass.

- [x] T007 [US1] Update `ExpenseFormNotifier.submit()` in `my_apps/apps/sfinance/lib/providers/form_providers.dart` (lines ~141–201): keep the `startDate` computation (skip logic: `clampedDay < today.day` → next month, else current month), remove the direct transaction insertion and the `templateDao.updateLastGeneratedPeriod()` call that follow the template insert, and instead call `RecurringGenerationService.generateForTemplate(db, savedTemplate, today: today)` after the template insert. The template is inserted with `lastGeneratedPeriod: const Value.absent()` (null).

- [x] T008 [US1] Verify T003 test passes and the US1 end-to-end scenario works: `paymentDay == today.day` produces exactly one transaction in the DB immediately after `generateForTemplate()`.

**Checkpoint**: US1 — paymentDay == today generates the entry immediately. All existing recurring generation service tests pass.

---

## Phase 4: User Story 2 — Primer pago en un día futuro del mes en curso (Priority: P1)

**Goal**: When `paymentDay` is greater than today's day-of-month (i.e., the payment day hasn't arrived yet this month), no entry is generated at save time.

**Independent Test**: Save a monthly recurring template with `paymentDay = today.day + 4`. Verify zero transaction entries exist in the DB immediately after save. Verify one entry is generated when `RecurringGenerationService.generateForTemplate()` is called with `today = DateTime(year, month, paymentDay)`.

### Tests for User Story 2 ⚠️ WRITE FIRST — must FAIL before T005 is applied

- [x] T009 [US2] Write failing test in `my_apps/packages/shared_services/test/generation/period_generator_test.dart`: `computeDueKeys(startDate: April 1, endDate: far-future, periodicity: 'mensual', paymentDay: 20, today: April 16)` → returns `[]` (April 20 > April 16, so current month excluded). **This test FAILS with current PeriodGenerator** (which returns `['2026-04']`). This is the primary failing test required by Constitution Principle IV.

- [x] T010 [P] [US2] Write failing test in `my_apps/packages/shared_services/test/generation/period_generator_test.dart`: `computeDueKeys(..., paymentDay: 31, today: April 16)` — paymentDay=31 clamped to April 30 → April 30 > April 16 → `[]`. Also add test for `today: April 30` → `['2026-04']` (April 30 == April 30, included on same day).

- [x] T011 [P] [US2] Confirm T009 and T010 FAIL with the current (unmodified) PeriodGenerator. This step is mandatory for Constitution Principle IV compliance — document the failing output as evidence.

### Implementation for User Story 2

- [x] T012 [US2] (Already done in T005) Verify that T009 and T010 now PASS after the date-filter implementation in T005. No additional code change needed — the PeriodGenerator change from US1 Phase covers this scenario.

- [x] T013 [US2] Verify end-to-end: form save with `paymentDay=20`, `today=April 16` → zero transactions in DB → on simulated app launch with `today=April 20`, `generateForTemplate()` produces exactly one transaction dated April 20.

**Checkpoint**: US2 — no premature entry for future paymentDay. PeriodGenerator date filter confirmed working.

---

## Phase 5: User Story 3 — Primer pago diferido al mes siguiente (Priority: P1)

**Goal**: When `paymentDay` is less than today's day-of-month (already passed this month), no entry is generated at save time; the first entry defers to `paymentDay` of the next month.

**Independent Test**: Save a monthly recurring template with `paymentDay = today.day - 6` (e.g., paymentDay=10, today=16). Verify zero entries in the DB at save time. Verify one entry dated May 10 is generated when the app runs on May 10.

### Tests for User Story 3 ⚠️ WRITE FIRST — must FAIL before T007 is applied

- [x] T014 [US3] Write test in `my_apps/packages/shared_services/test/generation/period_generator_test.dart`: `computeDueKeys(startDate: May 1, endDate: far-future, periodicity: 'mensual', paymentDay: 10, today: April 16)` → returns `[]` (startDate is May 1, no months between May 1 and April 16). This test PASSES with current PeriodGenerator (future startDate returns empty), but write it to document the US3 scenario and protect against regression.

- [x] T015 [P] [US3] Write test confirming that when `today=May 10`, `computeDueKeys(startDate: May 1, ..., paymentDay: 10, today: May 10)` returns `['2026-05']` (May 10 ≤ May 10, included).

- [x] T016 [US3] Update `IncomeFormNotifier.submit()` in `my_apps/apps/sfinance/lib/providers/form_providers.dart` (lines ~378–456): mirror T007 — keep `startDate` skip logic, remove direct transaction + `updateLastGeneratedPeriod` calls, call `RecurringGenerationService.generateForTemplate()` after template insert. Preserve the 14-paga `extraMonths` computation (it is still passed to the template insert; `generateForTemplate()` reads it from the saved template row).

- [x] T017 [US3] Verify end-to-end: `ExpenseFormNotifier` save with `paymentDay=10`, `today=April 16` → zero transactions in DB → on simulated launch with `today=May 10`, `generateForTemplate()` produces exactly one transaction dated May 10.

**Checkpoint**: US3 — already-passed paymentDay defers to next month with zero premature entries. All three P1 user stories now pass their independent tests.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T018 Update `specs/001-sfinance-core-app/spec.md`: add a note to FR-013 marking it superseded by spec 006 FR-001, and to SC-004 marking it superseded by spec 006 SC-001.

- [x] T019 [P] Run the full test suite for `shared_services` package: `cd my_apps/packages/shared_services && flutter test`. Verify all tests pass.

- [x] T020 [P] Run the full test suite for `sfinance` app: `cd my_apps/apps/sfinance && flutter test`. Verify all tests pass.

- [x] T021 Run `flutter analyze` from `my_apps/apps/sfinance` and from `my_apps/packages/shared_services`. Fix any analyzer warnings introduced by this change.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 2 (Foundational)**: No dependencies — start immediately.
- **Phase 3 (US1)**: Depends on Phase 2 (T001, T002 complete).
- **Phase 4 (US2)**: Depends on Phase 3 (T005 — date filter implemented). Tests (T009–T011) can be written in parallel with Phase 3 tests.
- **Phase 5 (US3)**: Depends on Phase 3 (T007 — form provider delegation). Tests (T014–T015) can be written in parallel with Phase 3 tests.
- **Phase 6 (Polish)**: Depends on Phases 3, 4, 5 complete.

### User Story Dependencies

- **US1**: No dependencies on US2 or US3. Core PeriodGenerator change + ExpenseFormNotifier delegation.
- **US2**: PeriodGenerator change from US1 Phase already covers this — only verification tasks.
- **US3**: ExpenseFormNotifier delegation from US1 Phase + IncomeFormNotifier delegation (T016).

### Within Each Phase

1. Tests written and FAIL confirmed before implementation (Constitution Principle IV)
2. T001 and T002 (extraction) before any test phase
3. T005 (PeriodGenerator implementation) before T006 (service update) before T007/T016 (form providers)
4. Analyzer clean-up (T021) last

### Parallel Opportunities

- T003 and T004 (US1 tests) can be written in parallel
- T009 and T010 (US2 tests) can be written in parallel with T003/T004
- T014 and T015 (US3 tests) can be written in parallel with T009/T010
- T019 and T020 (final test runs) can run in parallel
- T007 (ExpenseFormNotifier) and IncomeFormNotifier work (T016) are in the same file but sequential sections — run sequentially

---

## Parallel Example: Writing all failing tests before any implementation

```bash
# All test-writing tasks can be batched together before touching production code:
T003: Write PeriodGenerator test — paymentDay=16, today=April 16 → included
T004: Write PeriodGenerator test — paymentDay=1, today=April 16, startDate=April 1 edge case
T009: Write PeriodGenerator failing test — paymentDay=20, today=April 16 → excluded ← WILL FAIL
T010: Write PeriodGenerator failing test — paymentDay=31, today=April 16 → clamped=30, excluded ← WILL FAIL
T014: Write PeriodGenerator test — startDate=May 1, today=April 16 → []
T015: Write PeriodGenerator test — startDate=May 1, paymentDay=10, today=May 10 → ['2026-05']

# Then confirm T009 and T010 FAIL (T011)
# Then implement PeriodGenerator (T005)
# Then verify all tests pass
```

---

## Implementation Strategy

### MVP First (Core Change — Phases 2 + 3 + US2 verification)

1. Complete Phase 2: Extract `dateForKey()` and `generateForTemplate()`
2. Write all failing tests (T003, T004, T009, T010, T014, T015)
3. Confirm T009 and T010 fail — Constitution gate satisfied
4. Implement PeriodGenerator date filter (T005)
5. Update RecurringGenerationService (T006)
6. Update ExpenseFormNotifier (T007)
7. Update IncomeFormNotifier (T016)
8. **STOP and VALIDATE**: Run full test suite; verify all three P1 user stories pass

### Incremental Delivery (already one increment — all stories share one change)

Since all three user stories depend on the same PeriodGenerator change, the natural delivery is a single increment that completes all three. The phases are ordered by verification complexity, not by separate deployment gates.

---

## Notes

- [P] tasks = different files, no shared state dependencies
- [Story] label maps task to user story for traceability
- Tests T009 and T010 are the Constitution-mandated failing tests — do NOT skip the fail-confirmation step (T011)
- `paymentDay=1` with `startDate=current month` is the backward-compatible default: day 1 ≤ any today, so current month is always included — preserves behavior for templates without explicit paymentDay
- The form providers' startDate computation (skip logic) is NOT changed by this feature — it correctly determines the first eligible month; the PeriodGenerator date filter handles "within-month has the day arrived yet"
- Commit after each logical group: T001–T002, T003–T011, T005–T008, T014–T017, T018–T021
