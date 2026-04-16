# Tasks: Recurring Payment Day (005)

**Input**: Design documents from `/specs/005-recurring-payment-day/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: TDD is required by Constitution IV for all financial calculation logic:
- `_dateForPeriod()` date resolution with paymentDay
- First-occurrence skip logic (day passed → next month)
- Month-length clamping (day 31 in February)

**Organization**: Grouped by user story. US1 (monthly) is MVP and must be complete before US2 (annual). US3 (badge) is fully independent after the foundational phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no unmet dependencies)
- **[Story]**: User story label (US1, US2, US3)

## Path Conventions

- **App lib**: `my_apps/apps/sfinance/lib/`
- **App tests**: `my_apps/apps/sfinance/test/`
- **shared_models**: `my_apps/packages/shared_models/lib/src/`
- **shared_services**: `my_apps/packages/shared_services/lib/src/`
- **shared_ui**: `my_apps/packages/shared_ui/lib/src/`

---

## Phase 1: Setup

**Purpose**: No new project setup required — this is an additive change to an existing Flutter project. The single setup step is to establish the TDD baseline for the migration before any schema change is written.

- [X] T001 Write failing test for Drift migration v1→v2: verify `payment_day` column is added and backfilled to `1` for existing rows in `my_apps/packages/shared_services/test/database/migration_v2_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema migration and model update. No user story work can begin until `paymentDay` exists in the DB and the generated Drift code is rebuilt.

**⚠️ CRITICAL**: Must complete before ANY user story phase begins.

- [X] T002 Add `paymentDay` nullable `IntColumn` to `RecurringTemplates` table in `my_apps/packages/shared_services/lib/src/database/tables/recurring_templates.dart`
- [X] T003 Bump `schemaVersion` to `2` and implement `MigrationStrategy` with `onUpgrade` (ALTER TABLE + backfill UPDATE) in `my_apps/packages/shared_services/lib/src/database/app_database.dart`
- [X] T004 Regenerate Drift code after table change: run `dart run build_runner build --delete-conflicting-outputs` in `my_apps/packages/shared_services/`
- [X] T005 [P] Add `int paymentDay` field (default `1`, immutable per FR-006) to `RecurringTemplate` model in `my_apps/packages/shared_models/lib/src/recurring_template.dart`

**Checkpoint**: `payment_day` column exists in schema, Drift code compiles, migration test passes, `RecurringTemplate` carries `paymentDay`.

---

## Phase 3: User Story 1 — Monthly Recurring Day Selection (Priority: P1) 🎯 MVP

**Goal**: Users can set the exact day of month for monthly recurring entries (expenses and salary income). The first occurrence correctly skips to next month if the selected day has already passed.

**Independent Test**: Create a monthly expense recurring (suscripción) with day 15 — first generated transaction date is 15th of current or next month depending on today's date. Create another with day 31 — February occurrences land on Feb 28/29.

### Tests for User Story 1 ⚠️ WRITE FIRST — CONFIRM FAILING BEFORE T008

- [X] T006 [P] [US1] Write failing unit tests for `_dateForPeriod()` monthly branch with `paymentDay`: day 15 → correct day; day 31 in Feb → last day of Feb; day 31 in March → 31 March; in `my_apps/apps/sfinance/test/services/recurring_generation_service_test.dart`
- [X] T007 [P] [US1] Write failing unit tests for first-occurrence skip logic: today=Apr 13, day=10 → first occurrence May 10; today=Apr 13, day=20 → first occurrence Apr 20; today=Apr 13, day=13 → first occurrence Apr 13 (edge: same day is not "passed"); in `my_apps/apps/sfinance/test/providers/expense_form_provider_test.dart`

### Implementation for User Story 1

- [X] T008 [US1] Update `_dateForPeriod()` monthly branch in `my_apps/apps/sfinance/lib/services/recurring_generation_service.dart`: use `template.paymentDay ?? 1`; clamp to `daysInMonth(year, month)` using `DateTime(year, month + 1, 0).day`
- [X] T009 [US1] Add `paymentDay: int?` field and `setPaymentDay(int? v)` setter to `ExpenseFormState` and `ExpenseFormNotifier`; `setCategoria()` and `setPeriodicidad()` clear `paymentDay`; `submit()` validates `paymentDay != null` when `isRecurring`; in `my_apps/apps/sfinance/lib/providers/form_providers.dart`
- [X] T010 [US1] Update `ExpenseFormNotifier.submit()` to compute first-occurrence date using paymentDay skip logic: clamp day to current month length, compare with `today.day`, use next month if `clampedDay < today.day`; set `startDate` and first transaction `date` accordingly; in `my_apps/apps/sfinance/lib/providers/form_providers.dart`
- [X] T011 [US1] Add `paymentDay: int?` field and `setPaymentDay(int? v)` setter to `IncomeFormState` and `IncomeFormNotifier`; `setCategoria()` and `setNumeroPagas()` clear `paymentDay`; `submit()` validates `paymentDay != null` when `isSalario`; in `my_apps/apps/sfinance/lib/providers/form_providers.dart`
- [X] T012 [US1] Update `IncomeFormNotifier.submit()` to compute first-occurrence date using paymentDay skip logic (salary is always mensual); in `my_apps/apps/sfinance/lib/providers/form_providers.dart`
- [X] T013 [P] [US1] Add `_DayDropdown` widget to `expense_form.dart`: `DropdownButtonFormField<int>`, values 1–31, visible only when `isRecurring && periodicidad == Periodicity.mensual`, positioned after the Periodicidad dropdown; in `my_apps/apps/sfinance/lib/ui/forms/expense_form.dart`
- [X] T014 [P] [US1] Add `_DayDropdown` widget to `income_form.dart`: values 1–31, visible only when `isSalario`, positioned after the NumeroPagas dropdown; in `my_apps/apps/sfinance/lib/ui/forms/income_form.dart`

**Checkpoint**: Create monthly expense with day 15 → transaction on correct date. Create salary with day 28 → first entry on 28th (or next month's 28th). Tests T006/T007 pass.

---

## Phase 4: User Story 2 — Annual Recurring Day Selection (Priority: P2)

**Goal**: Users can set the exact day within the annual payment month (derived from the `fechaFin` month). The day selector dynamically updates when `fechaFin` changes to a month with fewer days.

**Independent Test**: Create an annual expense recurring with `fechaFin` in June, day 15 → occurrence is June 15 every year. Change `fechaFin` month to February with day 30 selected → selector clamps to 28/29.

### Tests for User Story 2 ⚠️ WRITE FIRST — CONFIRM FAILING BEFORE T016

- [X] T015 [US2] Write failing unit tests for `_dateForPeriod()` annual branch with `paymentDay`: periodKey `"2026"` + `endDate.month=6` + `paymentDay=10` → June 10 2026; `paymentDay=30` + `endDate.month=2` → Feb 28 2026; leap year Feb 29; in `my_apps/apps/sfinance/test/services/recurring_generation_service_test.dart`

### Implementation for User Story 2

- [X] T016 [US2] Update `_dateForPeriod()` annual branch in `my_apps/apps/sfinance/lib/services/recurring_generation_service.dart`: use `template.endDate.month` for the month; clamp `paymentDay` to `daysInMonth(year, endDate.month)` — handles leap years correctly because the year of the occurrence is used, not endDate's year
- [X] T017 [US2] Update `ExpenseFormNotifier.setFechaFin()` to clamp `paymentDay` to `daysInMonth(newFechaFin.month)` when `periodicidad == Periodicity.anual` (implements FR-009); in `my_apps/apps/sfinance/lib/providers/form_providers.dart`
- [X] T018 [US2] Update `expense_form.dart` annual day selector: show `_DayDropdown` when `periodicidad == Periodicity.anual && fechaFin != null`; max value = `daysInMonth(fechaFin!.month)` (rebuilds when `fechaFin` changes via provider watch); in `my_apps/apps/sfinance/lib/ui/forms/expense_form.dart`

**Checkpoint**: Annual expense with June fechaFin + day 15 → June 15 occurrence. Changing fechaFin to February with day 30 → selector auto-clamps to 28. Tests T015 pass.

---

## Phase 5: User Story 3 — Payment Day in Entradas Badge (Priority: P3)

**Goal**: The Entradas list shows the payment day on each recurring entry's badge without opening a detail panel.

**Independent Test**: With existing recurring entries (created after this feature), the list row displays "Día 15 de cada mes" for monthly and "10 de junio" for annual without any tap/expand.

### Implementation for User Story 3

- [X] T019 [US3] Extend `TransactionWithStatus` typedef in `my_apps/packages/shared_services/lib/src/database/daos/transaction_dao.dart` to include `templatePaymentDay: int?` and `templatePeriodicity: String?`; update the row mapping in `watchFilteredWithTemplateStatus()` to read these from `row.readTableOrNull(db.recurringTemplates)?.paymentDay / ?.periodicity`
- [X] T020 [US3] Add `paymentDay: int?` and `periodicity: String?` to `TransactionDisplay`; update `_toDisplay()` in `my_apps/apps/sfinance/lib/providers/transaction_providers.dart` to populate them and compute `recurringDetail` string: `"Día $n de cada mes"` for mensual, `"$day de $monthName"` for anual (use `intl` for month name), `null` for one-off
- [X] T021 [P] [US3] Add optional `recurringDetail: String?` parameter (default `null`) to `TransactionRow` in `my_apps/packages/shared_ui/lib/src/widgets/transaction_row.dart`; when non-null, render it as small text (fontSize 10, same color as `_color`) below the repeat icon in the leading Stack
- [X] T022 [US3] Update `EntradasView` to pass `entry.recurringDetail` to `TransactionRow` in `my_apps/apps/sfinance/lib/ui/entradas/entradas_view.dart`

**Checkpoint**: Recurring entries in the Entradas list show their payment day inline. One-off entries show nothing. Pre-feature entries (paymentDay=1 after migration) show "Día 1 de cada mes".

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T023 [P] Run `flutter analyze` from `my_apps/` — fix any warnings in changed files (shared_models, shared_services, shared_ui, sfinance app)
- [X] T024 [P] Run `flutter test` in `my_apps/packages/shared_services/` — confirm migration test passes
- [X] T025 Run `flutter test` in `my_apps/apps/sfinance/` — confirm T006, T007, T015 tests pass along with any pre-existing tests
- [ ] T026 Launch app (`flutter run -d windows`) and manually verify: (a) day selector appears after Periodicidad in expense form for monthly; (b) day selector appears in income form for salary; (c) annual selector max updates on fechaFin change; (d) badge shows day info in Entradas list

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on T001 (migration test written and failing) — BLOCKS all user story phases
- **Phase 3 (US1)**: Depends on Phase 2 completion — no dependency on US2 or US3
- **Phase 4 (US2)**: Depends on Phase 2 completion; logically extends US1's `_dateForPeriod` work
- **Phase 5 (US3)**: Depends on Phase 2 completion (needs `paymentDay` column in DB + Drift code); fully independent of US1/US2 UI logic
- **Phase 6 (Polish)**: Depends on all desired user story phases being complete

### Within Phase 3 (US1)

- T006, T007 must be written and **confirmed failing** before T008 begins (Constitution IV)
- T009, T010, T011, T012 are in the same file (`form_providers.dart`) → sequential
- T013, T014 are in different files → can run in parallel after T009/T011

### Within Phase 4 (US2)

- T015 must fail before T016 begins
- T017, T018 depend on `paymentDay` being in `ExpenseFormState` (T009 from US1)

### Within Phase 5 (US3)

- T019 (DAO) → T020 (provider) → T022 (view) are sequential (same data chain)
- T021 (TransactionRow widget) is independent → can be done in parallel with T019/T020

### Parallel Opportunities

```bash
# Phase 2 — after T001 passes:
Task T002: Add column to Drift table
Task T005: Add field to RecurringTemplate model   # different package, parallel
# → then T003 (migration), then T004 (build_runner)

# Phase 3 — tests first (parallel):
Task T006: _dateForPeriod monthly tests
Task T007: first-occurrence skip tests
# → then T008 (generation service), then T009-T012 (form providers), then T013/T014 (forms, parallel)

# Phase 5:
Task T021: TransactionRow widget update   # can start right after Phase 2
# in parallel with T019 → T020 → T022 chain
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T005)
3. Complete Phase 3: US1 — Monthly day selection (T006–T014)
4. **STOP and validate**: monthly day selector works, tests pass
5. Ship US1 independently

### Incremental Delivery

1. Setup + Foundational → schema ready
2. **US1** → monthly day selector for expenses + salary (MVP)
3. **US2** → annual day selector + dynamic max
4. **US3** → badge display in Entradas
5. Polish → clean up, full test run

---

## Notes

- `paymentDay` is immutable after creation (FR-006). The day selector must NOT appear in any edit flow (FR-010). Currently no edit flow exists; document this constraint if one is added later.
- `daysInMonth(year, month)` helper: `DateTime(year, month + 1, 0).day` — no external package needed.
- For month name in badge (US3): `intl` package is already a dependency; use `DateFormat('MMMM', 'es').format(DateTime(2000, month))`.
- [P] tasks operate on **different files** — safe to run in parallel within the same agent session.
- Commit after each checkpoint, not after each task.
