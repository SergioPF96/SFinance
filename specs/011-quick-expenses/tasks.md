# Tasks: Quick Expenses

**Input**: Design documents from `/specs/011-quick-expenses/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **This app (SFinance)**: `my_apps/apps/sfinance/lib/`, tests at `my_apps/apps/sfinance/test/`
- **Shared code**: `my_apps/packages/shared_models/`, `my_apps/packages/shared_ui/`, `my_apps/packages/shared_services/`
- **Providers**: `lib/providers/` — globally scoped, no widget-local providers
- **Widgets**: `lib/ui/` — presentational only, no business logic
- **Domain/services**: `lib/domain/` or `lib/services/`

---

## Phase 1: Setup

**Purpose**: Install new dependency before any other work begins.

- [X] T001 Add `file_picker: ^8.0.0` to `my_apps/apps/sfinance/pubspec.yaml` under `dependencies` and run `flutter pub get` from `my_apps/apps/sfinance`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure-Dart model, filesystem service, Drift table+DAO+migration, and providers — shared infrastructure every user story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Model

- [X] T002 [P] Write failing unit tests for `QuickExpense` model invariants (name non-empty, amountCents > 0, category valid `ExpenseCategory`, imagePath nullable) in `my_apps/packages/shared_models/test/quick_expense_test.dart`
- [X] T003 Create pure-Dart `QuickExpense` class with all fields (`id`, `name`, `amountCents`, `category`, `imagePath`, `createdAt`) in `my_apps/packages/shared_models/lib/src/quick_expense.dart` and export from `my_apps/packages/shared_models/lib/shared_models.dart`

### ImageStorageService

- [X] T004 [P] Write failing tests for `ImageStorageService` (happy-path copy returns canonical path, source missing throws `ImageCopyException`, unsupported extension throws `ImageCopyException`, `.tmp` partial file not left on failure, `deleteImageFile` silent on missing path, `assignTempFileToId` renames and removes temp path) in `my_apps/packages/shared_services/test/image_storage_service_test.dart`
- [X] T005 Create `ImageStorageService` with `copyImageForQuickExpense`, `copyImageForNewQuickExpense`, `assignTempFileToId`, and `deleteImageFile` — using atomic copy-to-.tmp-then-rename, best-effort delete (swallow exceptions), and `rootDirectoryOverride` injection for tests — in `my_apps/packages/shared_services/lib/src/storage/image_storage_service.dart`

### Drift layer

- [X] T006 [P] Create `QuickExpenses` Drift `Table` subclass (columns: `id` autoIncrement PK, `name` TextColumn, `amountCents` IntColumn, `category` TextColumn, `imagePath` TextColumn nullable, `createdAt` DateTimeColumn with `withDefault(currentDateAndTime)`) in `my_apps/packages/shared_services/lib/src/database/tables/quick_expenses.dart`
- [X] T007 [P] Create `QuickExpenseDao` stub (`@DriftAccessor(tables: [QuickExpenses])` class with method signature declarations for `insert`, `update`, `deleteById`, `watchAll`, `findById`) in `my_apps/packages/shared_services/lib/src/database/daos/quick_expense_dao.dart`
- [X] T008 Modify `AppDatabase` to bump `schemaVersion` from 3 to 4, add `QuickExpenses` to `@DriftDatabase(tables:)`, register `QuickExpenseDao` as a DAO accessor, and add `if (from < 4) { await m.createTable(quickExpenses); }` in the migration `onUpgrade` callback in `my_apps/packages/shared_services/lib/src/database/app_database.dart`
- [X] T009 Run `dart run build_runner build --delete-conflicting-outputs` from `my_apps/packages/shared_services` to generate `.g.dart` Drift files; commit all generated files
- [X] T010 [P] Write failing DAO tests (insert row appears in `watchAll()` stream, insert+findById returns row, update all fields, update `imagePath` to `Value(null)`, `deleteById` removes row from next stream emit, `watchAll` ordering stable by `createdAt ASC`, `findById` returns null for unknown id) using `NativeDatabase.memory()` in `my_apps/packages/shared_services/test/quick_expense_dao_test.dart`
- [X] T011 Implement full `QuickExpenseDao` methods (`insert` returns generated id, `update` patches only provided fields, `deleteById` hard-deletes, `watchAll` stream ordered by `createdAt ASC`, `findById` one-shot nullable fetch) in `my_apps/packages/shared_services/lib/src/database/daos/quick_expense_dao.dart`

### Providers

- [X] T012 Add `quickExpenseDaoProvider` (returns `ref.watch(appDatabaseProvider).quickExpenseDao`) and `imageStorageServiceProvider` (returns `ImageStorageService()`) to `my_apps/apps/sfinance/lib/providers/dao_providers.dart`
- [X] T013 Create `QuickExpenseEditFormState` (fields: `name`, `amount`, `category`, `pickedImagePath`, `existingImagePath`, `removeExistingImage`, `isSaving`, `errorMessage`; getters `canSave`, `hasImage`; `copyWith`), `QuickExpenseEditFormNotifier` (stub `build`, `_loadExisting`, `setName`, `setAmount`, `setCategory`, `setPickedImage`, `removeImage`, `save`, `deleteThis`), `quickExpensesStreamProvider` (`StreamProvider` wrapping `dao.watchAll()`), and `quickExpenseEditFormProvider` (`NotifierProvider.family.autoDispose<..., int?>`) in `my_apps/apps/sfinance/lib/providers/quick_expenses_provider.dart`
- [X] T014 [P] Write failing form notifier tests (`canSave` true only with valid name+amount+category; `setPickedImage` updates state without filesystem access; `removeImage` sets flag without filesystem access; `save()` create-mode happy path inserts row and copies image; `save()` create-mode no image inserts row with `imagePath=null`; `save()` edit-mode replace image copies new file, updates row, deletes old; `save()` edit-mode remove image updates row to null, deletes old; `save()` image copy failure sets `errorMessage` and skips DAO call; `deleteThis()` deletes row and image file) in `my_apps/apps/sfinance/test/providers/quick_expense_form_notifier_test.dart`
- [X] T015 Implement full `QuickExpenseEditFormNotifier.save()` (copy image via `ImageStorageService` if picked; insert or update DAO row; best-effort delete old image file on replace or remove; on `ImageCopyException` set `errorMessage` and return without touching DAO) and `deleteThis()` (`deleteById` then `deleteImageFile` best-effort) in `my_apps/apps/sfinance/lib/providers/quick_expenses_provider.dart`

**Checkpoint**: Run `melos run test` — T002→T003, T004→T005, T010→T011, T014→T015 all pass. Foundation ready.

---

## Phase 3: User Story 1 — Apply a Quick Expense shortcut (Priority: P1) 🎯 MVP

**Goal**: Pre-seeded quick expenses appear as tappable 64×64 cards at the top of the "+Gasto" modal; tapping fills name, amount, and category; the row is absent when no quick expenses exist.

**Independent Test**: Pre-seed one quick expense in the data store; open the expense form; verify card row appears; tap the card; verify form fields match the stored values.

- [X] T016 [US1] Write failing widget test for `QuickExpenseCardRow` (row absent when list is empty, single card appears for one item, tapping card invokes `onSelected` with the correct `QuickExpenseRow`) in `my_apps/apps/sfinance/test/ui/quick_expense_card_row_test.dart`
- [X] T017 [US1] Create `QuickExpenseCardRow` widget — `SizedBox(height: 80)` wrapping a horizontal `ListView`, one `InkWell`-wrapped 64×64 card per item showing `Image.file` when `imagePath != null` or `Icons.bolt_outlined` at 32 px in `AppColors.onBackgroundMuted` otherwise, tap calls `onSelected(row)` — in `my_apps/apps/sfinance/lib/ui/forms/quick_expense_card_row.dart`
- [X] T018 [US1] Modify `ExpenseForm` to watch `quickExpensesStreamProvider` and, when the snapshot has a non-empty list, render `QuickExpenseCardRow` above all other form fields; card tap calls `expenseFormNotifier.prefillFromQuickExpense(row)` (add this method to the expense form notifier to set name, amount, and category) in `my_apps/apps/sfinance/lib/ui/forms/expense_form.dart`

**Checkpoint**: Launch app; open "+Gasto" with a pre-seeded quick expense → card row is visible; tap it → form fields fill correctly; no card row when list is empty.

---

## Phase 4: User Story 2 — Save current expense form as quick expense (Priority: P2)

**Goal**: With name and amount filled in "+Gasto", the user taps "Guardar como gasto común"; an edit dialog opens pre-filled with current values; the user optionally picks an image and confirms; the new quick expense appears as a card on the next modal open.

**Independent Test**: Enter name and amount in expense form; tap "Guardar como gasto común"; confirm dialog; reopen "+Gasto"; verify new card appears with correct data.

- [X] T019 [US2] Create `ImagePickerService` — thin wrapper calling `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg','jpeg','png','webp','gif'], allowMultiple: false)` — returns the picked file path or `null` on cancel — in `my_apps/apps/sfinance/lib/services/image_picker_service.dart`
- [X] T020 [US2] Create `QuickExpenseEditDialog` widget — `showDialog`-based `AlertDialog` with name `TextFormField`, amount `TextFormField`, category `DropdownButtonFormField<ExpenseCategory>`, image-picker trigger `OutlinedButton` (calls `ImagePickerService` then `notifier.setPickedImage`), picked-image preview (`Image.file` when `state.pickedImagePath != null`), Confirmar `ElevatedButton` (enabled when `state.canSave && !state.isSaving`, calls `notifier.save()` then `Navigator.pop(context, true)`), Cancelar `TextButton` — in `my_apps/apps/sfinance/lib/ui/entradas/quick_expense_edit_dialog.dart`
- [X] T021 [US2] Add "Guardar como gasto común" `TextButton` to `ExpenseForm`: disabled (wrapped in `Tooltip` with message "Introduce un nombre y un importe para guardar este gasto") when either `expenseFormState.name.isEmpty` or `expenseFormState.amount.isEmpty`; on tap seed `quickExpenseEditFormProvider(null)` with current name/amount/category and `await showDialog<bool>(... QuickExpenseEditDialog(id: null) ...)` in `my_apps/apps/sfinance/lib/ui/forms/expense_form.dart`

**Checkpoint**: Quickstart §4 steps 4–9 pass end-to-end.

---

## Phase 5: User Story 3 — Manage quick expenses from Frecuentes tab (Priority: P3)

**Goal**: The Entradas view gains three tabs (Transacciones / Recurrentes / Frecuentes); the Frecuentes tab lists all quick expenses with edit and delete affordances; the top-level Recurrentes nav entry is removed.

**Independent Test**: Navigate to Entradas → Frecuentes; pre-seeded rows appear; tap a row to open edit dialog; edit and confirm; verify change persists; delete a row via confirmation; verify removal; empty-state message when list is empty.

- [X] T022 [P] [US3] Extract the existing Entradas list content (date range filter, category filter, transactions `ListView`) into `TransaccionesTab` stateless widget in `my_apps/apps/sfinance/lib/ui/entradas/tabs/transacciones_tab.dart`
- [X] T023 [P] [US3] Extract `RecurrentesView` body content (templates list, add-template flow) into `RecurrentesTab` stateless widget in `my_apps/apps/sfinance/lib/ui/entradas/tabs/recurrentes_tab.dart`
- [X] T024 [P] [US3] Create `FrecuentesTab` widget — watches `quickExpensesStreamProvider`; empty-state `Text("No hay gastos comunes guardados")` when list is empty; `ListView` of `ListTile` rows each showing name, amount formatted via `CurrencyFormatter`, category, and image thumbnail or `Icons.bolt_outlined`; trailing `IconButton(Icons.edit)` opens `QuickExpenseEditDialog(id: row.id)` in edit mode; another `IconButton(Icons.delete_outline)` shows `ConfirmationDialog` and on confirm calls `ref.read(quickExpenseEditFormProvider(row.id).notifier).deleteThis()` — in `my_apps/apps/sfinance/lib/ui/entradas/tabs/frecuentes_tab.dart`
- [X] T025 [US3] Refactor `EntradasView` to wrap content in `DefaultTabController(length: 3)` with a `TabBar` (tabs: "Transacciones", "Recurrentes", "Frecuentes") and `TabBarView` using `TransaccionesTab`, `RecurrentesTab`, `FrecuentesTab` in `my_apps/apps/sfinance/lib/ui/entradas/entradas_view.dart`
- [X] T026 [US3] Remove the `/recurrentes` `GoRoute` from `app_router.dart` and replace any `context.go('/recurrentes')` or `context.push('/recurrentes')` call sites with `context.go('/entradas')` in `my_apps/apps/sfinance/lib/routing/app_router.dart`
- [X] T027 [US3] Remove the "Recurrentes" `NavigationRailDestination` (and its corresponding index/body entry) from `AppShell` in `my_apps/apps/sfinance/lib/ui/shell/app_shell.dart`
- [X] T028 [US3] Delete `my_apps/apps/sfinance/lib/ui/recurrentes/recurrentes_view.dart` (content now lives in `RecurrentesTab`); fix any remaining import errors

**Checkpoint**: Launch app; Entradas shows three tabs; Frecuentes tab lists quick expenses; quickstart §4 steps 10–11 pass.

---

## Phase 6: User Story 4 — Add or replace an image on an existing quick expense (Priority: P4)

**Goal**: The edit dialog (opened from Frecuentes tab or "+Gasto" button) shows the existing image preview when one is set, allows replacing it, shows "Eliminar imagen" when an image is present, and shows a retry banner on copy failure.

**Independent Test**: Open edit dialog for an image-less quick expense; pick image; confirm; verify card shows image. Open edit dialog for a quick expense with image; tap "Eliminar imagen"; confirm; verify card reverts to generic icon.

- [X] T029 [US4] Extend `QuickExpenseEditDialog` to show existing image preview (`Image.file(File(state.existingImagePath!))` when `state.existingImagePath != null && !state.removeExistingImage && state.pickedImagePath == null`) and an "Eliminar imagen" `TextButton` visible only when `state.hasImage` (calls `notifier.removeImage()`) in `my_apps/apps/sfinance/lib/ui/entradas/quick_expense_edit_dialog.dart`
- [X] T030 [US4] Add an error banner (red `Container` or `MaterialBanner` equivalent inside the dialog) with "Reintentar" `TextButton` (calls `notifier.save()` again), visible only when `state.errorMessage != null`, in `my_apps/apps/sfinance/lib/ui/entradas/quick_expense_edit_dialog.dart`

**Checkpoint**: Quickstart §4 steps 12–13 and §5 "Remove image" and "Image copy failure" edge-case tests pass.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final analysis, formatting, test verification, and manual smoke test.

- [X] T031 Run `flutter analyze` from `my_apps/apps/sfinance`, `my_apps/packages/shared_models`, and `my_apps/packages/shared_services`; fix all reported issues
- [X] T032 Run `dart format .` from `my_apps/` and commit any formatting changes
- [X] T033 Delete `my_apps/packages/shared_services/build/native_assets/windows/sqlite3.dll` if present (errno 183 workaround), then run `/c/Users/Sergio/AppData/Local/Pub/Cache/bin/melos.bat run test` and confirm all new test files pass with zero failures
- [ ] T034 Run quickstart.md §4 golden-path smoke test (steps 1–13) and §5 edge-case tests manually; confirm all pass and checklist items in `checklists/requirements.md` remain ticked

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — no dependency on US2/US3/US4
- **US2 (Phase 4)**: Depends on Phase 2 — no dependency on US1 (can start in parallel with Phase 3)
- **US3 (Phase 5)**: Depends on Phase 2 and US2 (needs `QuickExpenseEditDialog`)
- **US4 (Phase 6)**: Depends on US2 (dialog component) and US3 (Frecuentes entry point)
- **Polish (Phase 7)**: Depends on all user story phases being complete

### User Story Dependencies

- **US1 (P1)**: After Foundational — fully independent
- **US2 (P2)**: After Foundational — fully independent of US1
- **US3 (P3)**: After Foundational and US2 (reuses `QuickExpenseEditDialog`)
- **US4 (P4)**: After US2 (extends dialog) and US3 (opens dialog from Frecuentes tab)

### Within Each Phase

- Tests MUST be written and confirmed failing BEFORE implementation (Principle IV + spec requirement)
- Models before services before providers before UI
- T009 (build_runner) blocks T010 and T011 — Drift companion types must be generated before tests can reference them
- T022, T023, T024 are parallel within Phase 5; T025 depends on all three

### Parallel Opportunities

- **Phase 2**: T002 [P] and T004 [P] can start simultaneously (different packages)
- **Phase 2**: T003 and T005 can overlap (different files, no dependency between them)
- **Phase 2**: T006 [P] and T007 [P] can run in parallel (different files)
- **Phase 2**: T010 [P] (DAO tests) and T005 (image service) can overlap after T009
- **Phase 2**: T014 [P] (notifier tests) can start as soon as T013 is done
- **Phases 3+4**: US1 and US2 can be developed in parallel after Phase 2
- **Phase 5**: T022 [P], T023 [P], T024 [P] all run in parallel

---

## Parallel Example: Phase 2 (Foundational)

```
# Batch 1 — write failing tests first (parallel)
Task T002: QuickExpense model tests
Task T004: ImageStorageService tests

# Batch 2 — implement model + image service (can overlap)
Task T003: QuickExpense model implementation
Task T005: ImageStorageService implementation

# Batch 3 — Drift stubs (parallel, both independent files)
Task T006: QuickExpenses Drift table
Task T007: QuickExpenseDao stub

# Sequential — each depends on previous
Task T008: Modify AppDatabase (needs T006, T007)
Task T009: Run build_runner (needs T008)

# After build_runner
Task T010: Write failing DAO tests    ← can start writing while T011 is in progress
Task T011: Implement DAO methods

# Sequential providers
Task T012: Register DAO + image service providers
Task T013: Create provider file with stubs
Task T014: Write failing notifier tests
Task T015: Implement notifier fully
```

---

## Parallel Example: Phase 5 (US3)

```
# Batch 1 — tab extraction (fully parallel, independent files)
Task T022: TransaccionesTab
Task T023: RecurrentesTab
Task T024: FrecuentesTab

# Sequential — each depends on batch 1
Task T025: Refactor EntradasView (needs T022, T023, T024)
Task T026: Update app_router.dart
Task T027: Update app_shell.dart
Task T028: Delete recurrentes_view.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T015)
3. Complete Phase 3: US1 (T016–T018)
4. **STOP and VALIDATE**: Card row pre-fills the expense form from pre-seeded data
5. Demo and decide whether to continue with US2

### Incremental Delivery

1. Phase 1 + 2 → Foundation (model, storage, DAO, providers) ready
2. Phase 3 (US1) → Tappable card row in expense form; demonstrable speed win
3. Phase 4 (US2) → User can create quick expenses from the form
4. Phase 5 (US3) → User can manage quick expenses from Frecuentes tab
5. Phase 6 (US4) → Full image add/replace/remove lifecycle
6. Phase 7 → Polish and ship

---

## Notes

- Always invoke melos via its full path: `/c/Users/Sergio/AppData/Local/Pub/Cache/bin/melos.bat run test`
- If build_runner (T009) fails with errno 183 on Windows: delete `my_apps/packages/shared_services/build/native_assets/windows/sqlite3.dll` first
- All [P] tasks can run simultaneously; they touch different files with no cross-dependency
- Write tests and confirm they fail before implementing (Principle IV — also required by quickstart.md §3)
- Commit after each task or logical group to keep the branch history clean
- Stop at any checkpoint to validate the user story independently before proceeding

