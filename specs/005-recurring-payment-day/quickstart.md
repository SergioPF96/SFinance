# Quickstart: 005 — Recurring Payment Day

## What this feature does

Allows users to select the exact day of month (1–31) when a recurring entry (expense or income) should occur. Currently, all recurring entries are generated on the 1st of each month. After this feature, users can set "day 15" for a monthly subscription or "day 28" for salary, and generated transactions will land on the correct date.

## Key files to modify

### Schema & model (shared packages)

| File | Change |
|------|--------|
| `packages/shared_models/lib/src/recurring_template.dart` | Add `int paymentDay` field (default 1) |
| `packages/shared_services/lib/src/database/tables/recurring_templates.dart` | Add `paymentDay` nullable integer column |
| `packages/shared_services/lib/src/database/app_database.dart` | Bump `schemaVersion` to 2, add migration v1→v2 |

### Generation logic

| File | Change |
|------|--------|
| `apps/sfinance/lib/services/recurring_generation_service.dart` | `_dateForPeriod()`: use `template.paymentDay` instead of hardcoded `1` |

### Form UI & providers

| File | Change |
|------|--------|
| `apps/sfinance/lib/providers/form_providers.dart` | Add `paymentDay` to both form states; first-occurrence skip logic |
| `apps/sfinance/lib/ui/forms/expense_form.dart` | Add day selector dropdown after Periodicidad |
| `apps/sfinance/lib/ui/forms/income_form.dart` | Add day selector dropdown after NumeroPagas (salary is always mensual) |

### Display

| File | Change |
|------|--------|
| `packages/shared_ui/lib/src/widgets/transaction_row.dart` | Add optional `recurringDetail` text near badge |
| `apps/sfinance/lib/providers/transaction_providers.dart` | Add `paymentDay`/`periodicity` to `TransactionDisplay`; construct detail string |
| `apps/sfinance/lib/ui/entradas/entradas_view.dart` | Pass `recurringDetail` to `TransactionRow` |

### Tests

| File | Change |
|------|--------|
| `packages/shared_services/test/` | Migration v1→v2 test |
| `apps/sfinance/test/` | `_dateForPeriod` with paymentDay, first-occurrence skip logic, month-clamping |

## How to run

```bash
# From repo root — regenerate Drift code after table change
cd my_apps/packages/shared_services
dart run build_runner build --delete-conflicting-outputs

# Run tests
cd my_apps/apps/sfinance
flutter test

# Run the app
flutter run -d windows
```

## Important constraints

- `paymentDay` is **immutable** after creation (FR-006)
- Month clamping: day 31 in February → day 28/29
- First occurrence logic: if selected day already passed this month → generate next month
- Existing templates get `paymentDay = 1` via migration backfill
- No recalculation of already-generated transactions
