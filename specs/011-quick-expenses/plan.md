# Implementation Plan: Quick Expenses

**Branch**: `011-quick-expenses` | **Date**: 2026-04-29 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/011-quick-expenses/spec.md`

## Summary

Add a "Quick Expenses" feature: reusable, image-decorated shortcuts that pre-fill the "+Gasto" modal form. A new `quick_expenses` Drift table holds rows with name, amount (cents), expense category, optional internal image path, and creation timestamp. A new "Frecuentes" tab inside the Entradas view lets users create, edit, delete, and add/replace/remove images on quick expenses. The "+Gasto" modal grows a horizontal card row at the top (one tap-only card per quick expense, image or generic icon) plus a "Guardar como gasto común" button at the bottom that opens the edit dialog with the form's current values. The technical approach reuses Drift, Riverpod, and `shared_ui`/`shared_services` infrastructure already present, adds a single new third-party dependency (`file_picker`) for filesystem image selection, and introduces an `ImageStorageService` in `shared_services` that copies picked files into the app's documents directory and removes them on quick-expense deletion or image replacement.

## Technical Context

**Language/Version**: Dart 3.x — Flutter stable channel
**Primary Dependencies**: flutter_riverpod ^2.5.0, drift ^2.20.0, go_router ^14.0.0, intl ^0.19.0, path_provider ^2.1.0, path ^1.9.0, shared_models, shared_ui, shared_services. **NEW**: file_picker ^8.x (justified in Complexity Tracking).
**Storage**: SQLite via Drift, on-device only. Schema migration v3 → v4 (add `quick_expenses` table). Internal image files stored in `getApplicationDocumentsDirectory()/quick_expense_images/` (managed by `ImageStorageService`).
**Testing**: `flutter_test`, Drift `NativeDatabase.memory()` for DAO tests, Riverpod `ProviderContainer` for provider tests.
**Target Platform**: Desktop (Windows primary, per existing app config) with Android-compatible patterns preserved (no hover-only affordances; mouse-click-as-tap mapping retained).
**Project Type**: Flutter desktop app inside an existing Melos monorepo (`my_apps/`).
**Performance Goals**: Quick expense card row builds in < 16 ms for up to 50 cards (60 fps target). Image thumbnails decoded once and cached by Flutter's default `ImageCache`.
**Constraints**: Offline-first (zero network calls). All image I/O on a background isolate where possible (Drift already runs on a background DB isolate; `File.copy` is async). Image copy must be atomic — partial files must not be referenced if the copy fails.
**Scale/Scope**: Up to a few dozen quick expenses per user (per spec SC-004 assumption). Single-user, single-device. No concurrency.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Notes |
|-----------|-------|-------|
| I. Monorepo & Shared Code | New `QuickExpense` model in `packages/shared_models`. New `quick_expenses` table, `QuickExpenseDao`, and `ImageStorageService` in `packages/shared_services`. UI widgets app-local. **Breaking change**: `AppDatabase` schemaVersion bumps from 3 to 4 (additive only — new table, no existing-table changes). | PASS |
| II. Riverpod-Only State | All new providers globally scoped: `quickExpenseDaoProvider`, `quickExpensesStreamProvider`, `quickExpenseEditFormProvider`. No `setState` in any new widget. | PASS |
| III. UI/Business Logic Separation | Validation (name+amount required), amount-cents parsing, image-copy orchestration all live in `QuickExpenseEditFormNotifier` (provider) or `ImageStorageService`. Widgets only render and dispatch events. `QuickExpense` model is pure Dart (no Flutter imports). | PASS |
| IV. Test-First for Financial Logic | Amount-cents parsing (`monto` string → `int amountCents`) is financial logic and reuses the same algorithm already in `ExpenseFormNotifier.submit()`. New unit tests written and confirmed failing before implementation: `quick_expense_form_notifier_test.dart` covering name+amount validation, cent rounding, and edit-vs-create flows. | PASS (test-first) |
| V. Offline-First & Privacy | Zero network calls. File picker invokes OS-native dialog. No telemetry, no analytics, no logs containing image paths or names beyond stdout debug aids that are excluded in release builds. | PASS |
| VI. Financial UX Clarity | Amount in `Frecuentes` list and edit dialog formatted via existing `currency_formatter.dart`. No dates shown to user (createdAt is internal sort-only). Disabled-button tooltip uses Flutter `Tooltip` widget which is accessible. Card row supports keyboard scroll (focus traversal). Mouse-click-as-tap mapping preserved; long-press not used. WCAG AA contrast checked against `AppColors`. | PASS |
| VII. Simplicity | **NEW DEPENDENCY**: `file_picker` — justified in Complexity Tracking. **REFACTORING**: existing single-list `EntradasView` becomes a 3-tab `TabController` view (Transacciones / Recurrentes / Frecuentes), and the top-level `/recurrentes` nav route is consolidated under `/entradas` — justified in Complexity Tracking. No new state-management or routing libraries. No premature abstractions. | PASS WITH JUSTIFICATIONS |

## Project Structure

### Documentation (this feature)

```text
specs/011-quick-expenses/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── quick_expense_dao.md
│   ├── image_storage_service.md
│   └── quick_expenses_provider.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
my_apps/
├── apps/
│   └── sfinance/
│       └── lib/
│           ├── providers/
│           │   ├── dao_providers.dart                    # ADD quickExpenseDaoProvider
│           │   └── quick_expenses_provider.dart          # NEW: stream + edit form provider
│           ├── services/
│           │   └── image_picker_service.dart             # NEW: thin file_picker wrapper
│           ├── ui/
│           │   ├── entradas/
│           │   │   ├── entradas_view.dart                # MODIFY: wrap in TabController
│           │   │   ├── tabs/
│           │   │   │   ├── transacciones_tab.dart        # NEW: extracted from current entradas_view
│           │   │   │   ├── recurrentes_tab.dart          # NEW: extracted from recurrentes_view
│           │   │   │   └── frecuentes_tab.dart           # NEW
│           │   │   └── quick_expense_edit_dialog.dart    # NEW
│           │   ├── forms/
│           │   │   ├── expense_form.dart                 # MODIFY: add card row + button
│           │   │   └── quick_expense_card_row.dart       # NEW
│           │   ├── recurrentes/
│           │   │   └── recurrentes_view.dart             # DELETE (logic moves to recurrentes_tab.dart)
│           │   └── shell/
│           │       └── app_shell.dart                    # MODIFY: drop top-level Recurrentes nav
│           └── routing/
│               └── app_router.dart                       # MODIFY: drop /recurrentes route
├── packages/
│   ├── shared_models/
│   │   └── lib/
│   │       └── src/
│   │           └── quick_expense.dart                    # NEW
│   ├── shared_services/
│   │   ├── lib/
│   │   │   └── src/
│   │   │       ├── database/
│   │   │       │   ├── app_database.dart                 # MODIFY: schemaVersion 3→4, register table+DAO
│   │   │       │   ├── tables/
│   │   │       │   │   └── quick_expenses.dart          # NEW
│   │   │       │   └── daos/
│   │   │       │       └── quick_expense_dao.dart       # NEW
│   │   │       └── storage/
│   │   │           └── image_storage_service.dart        # NEW
│   │   └── pubspec.yaml                                  # NO CHANGE (path_provider already present)
│   └── shared_ui/                                        # NO CHANGE (reuse ConfirmationDialog)
└── melos.yaml                                            # NO CHANGE
```

**Tests**:

```text
my_apps/
├── apps/sfinance/test/
│   ├── providers/
│   │   └── quick_expense_form_notifier_test.dart        # NEW (validation, cents, dialog flows)
│   └── ui/
│       └── quick_expense_card_row_test.dart             # NEW (widget test: tap fills form)
├── packages/shared_models/test/
│   └── quick_expense_test.dart                          # NEW (model invariants)
└── packages/shared_services/test/
    ├── quick_expense_dao_test.dart                       # NEW (CRUD, ordering)
    └── image_storage_service_test.dart                   # NEW (copy, delete, atomic-failure)
```

**Structure Decision**: Layered Flutter monorepo. Domain types in `shared_models`, persistence and filesystem in `shared_services`, app-specific UI and providers in `apps/sfinance`. The Entradas view is refactored from a single list to a 3-tab `TabBar`/`TabBarView` and the top-level Recurrentes nav entry is removed (its content becomes the Recurrentes tab). This consolidation is necessary to satisfy spec FR-007.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| New dependency: `file_picker ^8.x` | Need OS-native file dialog to let the user pick an image from the filesystem (spec FR-006). No existing app dependency provides this. | Writing a custom file dialog per platform would require duplicating native plugin work that `file_picker` already encapsulates and which is widely used (>2M monthly pub downloads), well-maintained, and supports both Windows and Android (the app's two target platforms). |
| Refactor: `EntradasView` becomes a 3-tab view; top-level `/recurrentes` route is removed | Spec FR-007 requires "Frecuentes" as the last tab in Entradas, alongside "Transacciones" and "Recurrentes". The current app has Entradas as a flat list and Recurrentes as a sibling top-level nav. Consolidating them under Entradas is the only way to satisfy the spec text. | Adding "Frecuentes" as a 5th top-level nav (parallel to Recurrentes) would technically work but would directly contradict the spec wording and miss the user's information-architecture intent (manage shortcuts adjacent to the data they affect). |
| Schema migration v3 → v4 | New `quick_expenses` table is required for persistence. | An in-memory or JSON-file store would avoid the migration but would diverge from the established Drift pattern used by every other persisted entity in the app, and would not get free reactive `Stream` updates. |
