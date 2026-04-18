# Tasks: Unified Entries View

**Input**: Design documents from `/specs/003-unify-entries-view/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, quickstart.md ✓

**Organization**: Tasks are grouped by user story to enable independent verification of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on in-progress tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

- **App source**: `my_apps/apps/sfinance/lib/`
- **App tests**: `my_apps/apps/sfinance/test/`
- **Shared UI widgets**: `my_apps/packages/shared_ui/lib/src/widgets/`
- **Shared services / DAOs**: `my_apps/packages/shared_services/lib/src/database/daos/`
- **Providers**: `my_apps/apps/sfinance/lib/providers/`
- **Entradas views**: `my_apps/apps/sfinance/lib/ui/entradas/`

---

## Phase 1: Foundational — Data Layer & Providers

**Purpose**: New query and provider layer that ALL user stories depend on. Must complete before any story work.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Add `watchFilteredWithTemplateStatus()` method to `TransactionDao` in `my_apps/packages/shared_services/lib/src/database/daos/transaction_dao.dart`. Use a Drift left-outer-join on `RecurringTemplates` keyed on `transactions.templateId`. Define a Dart record typedef at the top of the file: `typedef TransactionWithStatus = ({TransactionRow transaction, bool? templateIsDeleted});`. The method takes `DateTime start` and `DateTime end`, returns `Stream<List<TransactionWithStatus>>`, filters by `t.date.isBetweenValues(start, end)`, orders by `date DESC`. Use `row.readTable(transactions)` and `row.readTableOrNull(recurringTemplates)?.isDeleted` to populate the record.

- [x] T002 Extend `TransactionDisplay` in `my_apps/apps/sfinance/lib/providers/transaction_providers.dart` with two new fields: `final bool isRecurring` and `final int? templateId`. Update the `_toDisplay()` private function signature to `_toDisplay(TransactionWithStatus entry)` and compute `isRecurring = entry.transaction.templateId != null && entry.templateIsDeleted == false`. Forward all other fields from `entry.transaction`. Import `TransactionWithStatus` from `shared_services`.

- [x] T003 Add `selectedTimeRangeProvider` and `unifiedEntriesProvider` in `my_apps/apps/sfinance/lib/providers/transaction_providers.dart`. `selectedTimeRangeProvider` is a globally-scoped `StateProvider<TimeRange>` with default `TimeRange.ultimos7Dias`. `unifiedEntriesProvider` is a `StreamProvider.family<List<TransactionDisplay>, DateTimeRange>` that calls `ref.watch(transactionDaoProvider).watchFilteredWithTemplateStatus(start: range.start, end: range.end).map((rows) => rows.map(_toDisplay).toList())`. The existing `filteredTransactionsProvider` stays unchanged (used by other views).

- [x] T004 Write unit tests in `my_apps/apps/sfinance/test/providers/transaction_providers_test.dart` covering three `isRecurring` derivation cases: (a) `templateId == null` → `isRecurring = false`; (b) `templateId != null` and `templateIsDeleted == false` → `isRecurring = true`; (c) `templateId != null` and `templateIsDeleted == true` → `isRecurring = false`. Use `TransactionWithStatus` records directly to unit-test `_toDisplay` (make it package-visible or test via provider with a mock DAO).

**Checkpoint**: Foundation complete — `unifiedEntriesProvider` streams all entries with correct `isRecurring` flag. Run `flutter test test/providers/` to confirm T004 passes.

---

## Phase 2: User Story 1 — Single Unified Entries List (Priority: P1) 🎯 MVP

**Goal**: Replace the tabbed Entradas view with a single flat chronological list. Recurring entries show a repeat badge. No TabController.

**Independent Test**: Open Entradas → verify single list with no tabs, time range filter works, recurring entries show the repeat icon, one-off entries do not.

### Implementation for User Story 1

- [x] T005 [P] [US1] Add optional `bool isRecurring` parameter (default `false`) to `TransactionRow` in `my_apps/packages/shared_ui/lib/src/widgets/transaction_row.dart`. When `isRecurring` is `true`, wrap the existing `CircleAvatar` in a `Stack` and add a `Positioned` `Icon(Icons.repeat, size: 14, color: _color, semanticLabel: 'Recurrente')` at `bottom: 0, right: 0`. The existing income/expense arrow remains the primary icon.

- [x] T006 [US1] Rewrite `my_apps/apps/sfinance/lib/ui/entradas/entradas_view.dart` as a `ConsumerWidget` (remove `StatefulWidget`, `SingleTickerProviderStateMixin`, `TabController`). Read `selectedTimeRangeProvider` for the selected time range. Compute `dateRange` from the selected range and watch `unifiedEntriesProvider(DateTimeRange(...))`. Render a `Column` with: (1) `TimeRangeSelector` that calls `ref.read(selectedTimeRangeProvider.notifier).state = r` on change; (2) `Divider`; (3) `Expanded` → `AsyncValue.when` showing loading/error/data states. In the data state, render `ListView.separated` of `TransactionRow` with `isRecurring: entry.isRecurring`. The `onDelete` callback is a placeholder for now: `onDelete: () {}`.

- [x] T007 [P] [US1] Delete `my_apps/apps/sfinance/lib/ui/entradas/transacciones_tab.dart` (no longer needed; its logic is absorbed into the new `entradas_view.dart`).

- [x] T008 [P] [US1] Delete `my_apps/apps/sfinance/lib/ui/entradas/recurrentes_tab.dart` (no longer needed; template management now happens inline from entry rows).

- [x] T009 [US1] Remove dead code from routing: in `my_apps/apps/sfinance/lib/routing/app_router.dart`, replace the `/entradas` route builder with `builder: (context, state) => const EntradasView()` (remove `final tab = ...` and `initialTab:` usage). In `entradas_view.dart`, remove the `initialTab` constructor parameter entirely.

**Checkpoint**: User Story 1 complete. Open Entradas → single list, time range filter works, recurring entries show the repeat badge, no tabs visible.

---

## Phase 3: User Story 2 — Delete a Recurring Entry (Priority: P2)

**Goal**: Tapping delete on a recurring entry shows a differentiated confirmation dialog, then cancels the template (soft-delete) while preserving the entry.

**Independent Test**: Add a recurring template with generated entries → tap delete on one → confirm dialog text names all 3 consequences → confirm → template is cancelled, entry remains without badge.

### Implementation for User Story 2

- [x] T010 [US2] Add `_confirmDeleteRecurring()` private method in `my_apps/apps/sfinance/lib/ui/entradas/entradas_view.dart`. Signature: `Future<void> _confirmDeleteRecurring(BuildContext context, TransactionDisplay entry)`. Call `showConfirmationDialog` with: `title: 'Cancelar entrada recurrente'`, `message: 'Se cancelará la programación de "${entry.name}". No se generarán nuevas entradas en el futuro. Esta entrada y todas las anteriores generadas por esta programación se conservan.'`, `confirmLabel: 'Cancelar programación'`, `cancelLabel: 'Volver'`. On `confirmed`, call `await ref.read(templateDaoProvider).softDelete(entry.templateId!)`. Guard with `if (mounted)` before the DAO call.

- [x] T011 [US2] Wire the `onDelete` callback in `entradas_view.dart` to call `_confirmDeleteRecurring()` for recurring entries. Replace the placeholder `onDelete: () {}` from T006 with `onDelete: entry.isRecurring ? () => _confirmDeleteRecurring(context, entry) : null`. Leave one-off `onDelete` as `null` for now (wired in T013).

**Checkpoint**: User Story 2 complete. Recurring delete dialog shows all 3 consequences. On confirm, template is soft-deleted and all its entries lose the badge in the current view (Drift reactivity handles this automatically).

---

## Phase 4: User Story 3 — Delete a One-Off Transaction (Priority: P3)

**Goal**: Tapping delete on a one-off transaction shows the standard confirmation and permanently removes the entry. Unchanged behavior from the old Transacciones tab.

**Independent Test**: Add a one-off transaction → tap delete → confirm standard dialog → entry is permanently removed from list.

### Implementation for User Story 3

- [x] T012 [US3] Add `_confirmDeleteOneOff()` private method in `my_apps/apps/sfinance/lib/ui/entradas/entradas_view.dart`. Signature: `Future<void> _confirmDeleteOneOff(BuildContext context, TransactionDisplay entry)`. Call `showConfirmationDialog` with: `title: 'Eliminar transacción'`, `message: '¿Eliminar "${entry.name}"? Esta acción no se puede deshacer.'`, `confirmLabel: 'Eliminar'`, `cancelLabel: 'Cancelar'`. On `confirmed`, call `await ref.read(transactionDaoProvider).deleteById(entry.id)`. Guard with `if (mounted)`.

- [x] T013 [US3] Update the `onDelete` wiring in `entradas_view.dart` to cover both cases. Replace the partial wiring from T011 with: `onDelete: entry.isRecurring ? () => _confirmDeleteRecurring(context, entry) : () => _confirmDeleteOneOff(context, entry)`.

**Checkpoint**: All three user stories complete. Both delete paths work. Entry type correctly determines dialog text and action.

---

## Phase 5: Polish & Verification

**Purpose**: Ensure code quality across all affected packages.

- [x] T014 [P] Run `flutter analyze` in `my_apps/apps/sfinance`, `my_apps/packages/shared_ui`, and `my_apps/packages/shared_services`. Fix all reported errors and warnings (unused imports, missing `const`, deprecated APIs).

- [x] T015 Run `flutter test` in `my_apps/apps/sfinance` to confirm all existing tests still pass and the new T004 provider tests pass. Command: `cd my_apps/apps/sfinance && flutter test`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — can start immediately. BLOCKS all user stories.
- **User Story 1 (Phase 2)**: Depends on Foundational complete. T005 and T006 are independent files — can run in parallel. T007/T008/T009 depend on T006 being complete.
- **User Story 2 (Phase 3)**: Depends on T006 (view exists to add method to). T010 and T011 are sequential (T011 calls T010).
- **User Story 3 (Phase 4)**: Depends on T011 (replaces partial wiring). T012 can run in parallel with T010.
- **Polish (Phase 5)**: Depends on all stories complete.

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational phase only.
- **US2 (P2)**: Depends on US1 (entradas_view.dart must exist as flat view).
- **US3 (P3)**: Depends on US2 (T013 replaces T011's partial wiring — both delete methods must exist).

### Within-Phase Parallel Opportunities

- T005 (widget, shared_ui) and T006 (view, sfinance app) are in different packages — can run in parallel once Phase 1 is done.
- T007 and T008 (file deletions) can run in parallel after T006.
- T014 analyze tasks across packages can run in parallel.

---

## Parallel Example: Phase 1 → Phase 2

```
# After Phase 1 complete, start these simultaneously:
Task T005: "Add isRecurring badge to TransactionRow widget in shared_ui"
Task T006: "Rewrite entradas_view.dart as flat ConsumerWidget"
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 1 (Foundational)
2. Complete Phase 2 (US1): flat list with badges, no tabs
3. **STOP and VALIDATE**: Open Entradas, verify flat list renders, time range filter works, badges appear on recurring entries
4. Proceed to US2/US3 for delete functionality

### Incremental Delivery

1. Phase 1 → verify `isRecurring` derivation correct (run T004 tests)
2. Phase 2 → flat list with badges visible in app (**MVP delivered**)
3. Phase 3 → recurring delete path works end-to-end
4. Phase 4 → one-off delete path works end-to-end
5. Phase 5 → clean analyze + all tests green

---

## Notes

- `filteredTransactionsProvider` is **preserved unchanged** — it is still used by other views (Resumen, Análisis). Do not remove or modify it.
- `TemplateDisplay` and `activeTemplatesProvider` in `template_providers.dart` become unused after deleting `recurrentes_tab.dart`. They can be left in place for now or removed — defer to Polish phase.
- The Drift stream reactivity on `watchFilteredWithTemplateStatus()` means FR-009 (immediate badge removal after template cancel) is handled automatically — no manual `ref.invalidate()` calls needed.
- `TransactionWithStatus` uses Dart record syntax (`({TransactionRow transaction, bool? templateIsDeleted})`). Confirm the project's Dart SDK version is ≥ 3.0.
