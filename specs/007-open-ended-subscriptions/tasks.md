# Tasks: Open-Ended Subscriptions (007)

**Feature**: 007-open-ended-subscriptions  
**Branch**: `007-open-ended-subscriptions`  
**Plan**: plan.md  

## Phase 1 — Setup

- [X] T001 Verify Drift schema version is 2 in `packages/shared_services/lib/src/database/app_database.dart`

## Phase 2 — Foundational (blocking all user stories)

- [X] T002 Make `endDate` nullable in the Drift table: change `dateTime()()` → `dateTime().nullable()()` in `packages/shared_services/lib/src/database/tables/recurring_templates.dart`
- [X] T003 Bump `schemaVersion` to 3 and add migration (ALTER TABLE or recreate) for nullable `end_date` in `packages/shared_services/lib/src/database/app_database.dart`

## Phase 3 — User Story 1: Create open-ended subscription (P1)

### Tests (TDD — write before implementation)

- [X] T004 [P] [US1] Add `PeriodGenerator.computeDueKeys` null-endDate tests (endDate=null → upper bound is today) in `packages/shared_services/test/generation/period_generator_test.dart`
- [X] T005 [P] [US1] Add `ExpenseFormNotifier` open-ended submit tests: (a) open-ended saves template with endDate=null, (b) FR-006 not triggered when openEnded=true in `apps/sfinance/test/providers/expense_form_provider_test.dart`

### Implementation

- [X] T006 [US1] Update `PeriodGenerator.computeDueKeys` signature: `endDate: required DateTime?`; when null use `today` as sole upper bound in `packages/shared_services/lib/src/generation/period_generator.dart`
- [X] T007 [US1] Update `RecurringGenerationService.generateForTemplate` to handle `template.endDate` being null — pass null safely to `computeDueKeys` in `apps/sfinance/lib/services/recurring_generation_service.dart`
- [X] T008 [US1] Add `openEnded` bool field (default false) to `ExpenseFormState` and `copyWith` in `apps/sfinance/lib/providers/form_providers.dart`
- [X] T009 [US1] Add `setOpenEnded(bool)` method to `ExpenseFormNotifier`; when true clear `fechaFin`; reset `openEnded` to false in `setCategoria` and `setPeriodicidad` in `apps/sfinance/lib/providers/form_providers.dart`
- [X] T010 [US1] Update `ExpenseFormNotifier.submit()`: skip FR-006 validation when `openEnded` is true; pass `endDate: Value(s.openEnded ? null : s.fechaFin)` to `RecurringTemplatesCompanion.insert` in `apps/sfinance/lib/providers/form_providers.dart`
- [X] T011 [US1] Add "Sin fecha de fin" toggle to the expense form widget — shown when `isRecurring` and `periodicidad != null`; hides endDate selector when active in `apps/sfinance/lib/ui/` (expense form widget)

## Phase 4 — User Story 2: Toggle off restores empty endDate (P1)

### Tests (TDD)

- [X] T012 [US2] Add unit tests: `setOpenEnded(true)` then `setOpenEnded(false)` → `fechaFin == null`; prior fechaFin not restored in `apps/sfinance/test/providers/expense_form_provider_test.dart`

### Implementation

- [X] T013 [US2] Verify `setOpenEnded(false)` does NOT restore a previous `fechaFin` value — confirm the logic in T009 is correct (no change needed if already correct) in `apps/sfinance/lib/providers/form_providers.dart`

## Phase 5 — User Story 3: Recurrentes list shows "Sin fecha de fin" (P2)

### Implementation

- [X] T014 [US3] Make `TemplateDisplay.endDate` nullable (`DateTime?`) and update `activeTemplatesProvider` mapping in `apps/sfinance/lib/providers/template_providers.dart`
- [X] T015 [US3] Update any UI widget that renders `TemplateDisplay.endDate` to show "Sin fecha de fin" when null in `apps/sfinance/lib/ui/`

## Phase 6 — Polish & Validation

- [X] T016 Run all tests and confirm passing: `flutter test` in `packages/shared_services` and `apps/sfinance`
- [X] T017 Run `flutter analyze` across the monorepo and fix any warnings
- [ ] T018 Manual smoke test: create a Suscripción with "Sin fecha de fin" active → confirm template saved with null endDate and no error; create a Suscripción with endDate set → confirm existing behaviour unchanged

## Dependencies

```
T001 (verify schema version)
  └─ T002 (make endDate nullable)
       └─ T003 (migration v2→v3)
            ├─ T006 (PeriodGenerator null endDate) ← T004 must fail first
            ├─ T007 (RecurringGenerationService null handling)
            ├─ T008 + T009 + T010 (form state) ← T005 must fail first
            └─ T011 (UI toggle)
                 └─ T012 + T013 (toggle-off behavior)
                      └─ T014 + T015 (Recurrentes display)
                           └─ T016 + T017 + T018 (validation)
```

## Parallel Opportunities

- T004 and T005 can be written in parallel (different files, both TDD).
- T006 and T008/T009/T010 can be implemented in parallel after T003.
- T014 and T015 can be done in parallel after T013.

## Implementation Strategy

MVP = Phase 3 (US1): open-ended save + generation. Phase 4 (US2) is a behavioural guard already implied by Phase 3 logic. Phase 5 (US3) is cosmetic and can ship after core functionality.
