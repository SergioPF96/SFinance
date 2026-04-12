# Research: Unified Entries View

**Branch**: `003-unify-entries-view` | **Date**: 2026-04-12

## R1: How to determine if a transaction is recurring (for badge display)

**Decision**: Join `transactions.templateId` with `recurring_templates.isDeleted` at the query level.

**Rationale**: The `Transactions` table already has a nullable `templateId` FK to `RecurringTemplates`. A transaction is "recurring" when `templateId IS NOT NULL` AND the referenced template has `isDeleted = false`. This can be resolved with a single Drift query using a left join, returning a boolean `isRecurring` flag per row. No schema migration needed.

**Alternatives considered**:
- *Add a boolean column `isRecurring` to `Transactions` table*: Rejected — adds redundant state that must be kept in sync when templates are soft-deleted. The join approach derives the status from the template's live `isDeleted` flag, ensuring FR-009 (reactive indicator removal) is satisfied automatically.
- *Load all active template IDs into memory and filter client-side*: Rejected — unnecessary complexity; the join is straightforward in Drift and keeps the logic in the data layer.

## R2: How to merge one-off and recurring entries in a single sorted list

**Decision**: A single Drift query on the `Transactions` table with a left join to `RecurringTemplates`, filtered by date range, ordered by `date DESC`. The left join provides the `isDeleted` flag to derive `isRecurring`.

**Rationale**: All entries — both one-off and recurring-generated — are already stored as rows in the `Transactions` table. The `templateId` column distinguishes their origin. No "merge" of two separate streams is needed; it's one query.

**Alternatives considered**:
- *Two separate streams (transactions + templates) merged client-side in the provider*: Rejected — unnecessary complexity. The Transacciones and Recurrentes tabs existed because the Recurrentes tab showed template metadata, not generated entries. Now that we show only generated entries with a badge, a single query suffices.
- *Custom SQL view*: Rejected — overkill for a single left join. Drift's query builder handles this cleanly.

## R3: Reactive update of recurrence indicator after template cancellation (FR-009)

**Decision**: Drift's `.watch()` on the joined query automatically re-emits when either `transactions` or `recurring_templates` table changes. When `softDelete(templateId)` sets `isDeleted = true`, the stream re-fires and all affected entries lose their `isRecurring = true` flag.

**Rationale**: Drift stream queries track table-level changes. A write to `recurring_templates` triggers re-evaluation of any stream query that references that table via a join. This gives us reactive, immediate UI update without manual invalidation.

**Alternatives considered**:
- *Manually invalidate the provider via `ref.invalidate()`*: Rejected — unnecessary; Drift's built-in reactivity handles this. Adding manual invalidation would be redundant and fragile.

## R4: TransactionRow widget change (shared_ui public API)

**Decision**: Add an optional `bool isRecurring` parameter (default `false`) to the existing `TransactionRow` widget. When `true`, overlay a small recurrence badge (Icons.repeat, sized 14, positioned at bottom-right of the CircleAvatar). The badge uses the existing category color.

**Rationale**: This is an additive, non-breaking change. All existing call sites pass no `isRecurring` argument and get the current behavior. The badge overlays the existing icon rather than replacing it, keeping the income/expense arrow visible. The `Icons.repeat` icon is the same one used in the current `RecurrentesTab`.

**Alternatives considered**:
- *Replace the CircleAvatar icon entirely for recurring entries*: Rejected — loses the income/expense visual distinction (arrow up/down).
- *Add a text badge like "Recurrente" after the category label*: Rejected — takes horizontal space in the subtitle and could cause overflow. An icon badge is more compact and language-neutral.

## R5: Confirmation dialog differentiation

**Decision**: Reuse the existing `showConfirmationDialog` function with different `title` and `message` strings depending on entry type. No new widget needed.

**Rationale**: The existing `ConfirmationDialog` already accepts arbitrary `title` and `message` strings. The recurring-entry dialog just needs longer, more descriptive message text covering the three consequences. This keeps the codebase simple — one dialog widget, two invocation patterns.

**Alternatives considered**:
- *New dedicated `RecurringDeleteDialog` widget*: Rejected — the only difference is the message text. Creating a separate widget violates Principle VII (no premature abstractions).

## R6: setState in TransaccionesTab for time range

**Decision**: The existing `setState` call in `TransaccionesTab` for `_selectedRange` will be replaced with a `StateProvider<TimeRange>` in the new `entradas_view.dart`. This satisfies Principle II (Riverpod-only state).

**Rationale**: The old `TransaccionesTab` used `ConsumerStatefulWidget` with `setState` to track the selected time range. In the unified view, this state moves to a globally-scoped Riverpod `StateProvider`, which the `entradas_view.dart` reads and the `TimeRangeSelector` updates.

**Alternatives considered**:
- *Keep `setState` since it's UI-only state*: Rejected — Constitution Principle II explicitly prohibits `setState`.

## R7: Router cleanup

**Decision**: Remove the `?tab=` query parameter from the `/entradas` route in `app_router.dart`. The `EntradasView` constructor no longer needs an `initialTab` parameter since there are no tabs.

**Rationale**: Dead code removal. No other part of the app navigates with `?tab=recurrentes` after the tabs are removed.

**Alternatives considered**: None — straightforward cleanup.
