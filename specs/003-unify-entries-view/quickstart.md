# Quickstart: Unified Entries View

**Branch**: `003-unify-entries-view` | **Date**: 2026-04-12

## What this feature does

Replaces the tabbed Entradas view (Transacciones / Recurrentes) with a single flat list of all entries. Recurring-generated entries show a small repeat-icon badge. Deleting a recurring entry cancels the template; deleting a one-off entry removes it permanently. Each deletion path has its own confirmation dialog.

## Files to modify

| File | Change | Layer |
|------|--------|-------|
| `packages/shared_services/lib/src/database/daos/transaction_dao.dart` | Add `watchFilteredWithTemplateStatus()` query (left join) | Data |
| `apps/sfinance/lib/providers/transaction_providers.dart` | Add `isRecurring`/`templateId` to `TransactionDisplay`, new `unifiedEntriesProvider`, new `selectedTimeRangeProvider` | Provider |
| `packages/shared_ui/lib/src/widgets/transaction_row.dart` | Add optional `isRecurring` param + badge overlay on CircleAvatar | Widget |
| `apps/sfinance/lib/ui/entradas/entradas_view.dart` | Rewrite: flat list with time range selector, no TabController | View |
| `apps/sfinance/lib/routing/app_router.dart` | Remove `?tab=` query param handling from `/entradas` route | Router |

## Files to delete

| File | Reason |
|------|--------|
| `apps/sfinance/lib/ui/entradas/transacciones_tab.dart` | Absorbed into `entradas_view.dart` |
| `apps/sfinance/lib/ui/entradas/recurrentes_tab.dart` | Absorbed into `entradas_view.dart` |

## Files to create

| File | Purpose |
|------|---------|
| `apps/sfinance/test/providers/transaction_providers_test.dart` | Unit tests for unified entries provider: isRecurring derivation, sort order, template cancellation reactivity |

## Key design decisions

1. **Single query, not stream merge**: All entries (one-off + recurring-generated) already live in the `Transactions` table. A left join to `RecurringTemplates` derives the `isRecurring` flag. No need to merge two separate streams.

2. **Badge on existing widget**: `TransactionRow` gets an additive `isRecurring` parameter. When true, `Icons.repeat` is overlaid on the existing CircleAvatar. Non-breaking change.

3. **Reactive indicator removal**: Drift's stream reactivity on the joined query means that when `softDelete(templateId)` fires, all entries from that template immediately lose their badge — no manual invalidation needed.

4. **Two confirmation paths, one dialog widget**: `showConfirmationDialog` is reused with different message text for one-off vs. recurring entries. No new widget.

5. **StateProvider for time range**: Replaces `setState` in the old tab, satisfying Constitution Principle II (Riverpod-only).

## Build & test commands

```bash
# From repo root — run all tests
/c/Users/Sergio/AppData/Local/Pub/Cache/bin/melos.bat run test

# From sfinance app — run provider tests only
cd my_apps/apps/sfinance && flutter test test/providers/

# Analyze
cd my_apps/apps/sfinance && flutter analyze

# Run the app
cd my_apps/apps/sfinance && flutter run -d windows
```

## Dependency on existing code

- `TransactionDao.watchFiltered()` — existing, used by current Transacciones tab. The new `watchFilteredWithTemplateStatus()` extends this pattern.
- `TemplateDao.softDelete()` — existing, used by current Recurrentes tab. Reused unchanged.
- `showConfirmationDialog()` — existing in shared_ui. Reused with different message strings.
- `TimeRangeSelector` widget — existing in analisis module. Reused unchanged.
- `TimeRange` enum and `.toDateRange()` — existing in analisis module.
