# Quickstart: 006-defer-recurring-first-entry

**Branch**: `006-defer-recurring-first-entry`

## What this feature changes

When a user saves a new monthly recurring entry (Suscripción, Financiación, or Salario), the first transaction entry is no longer always generated immediately. Instead:

- **paymentDay == today**: entry generated now
- **paymentDay > today (this month)**: entry deferred until that day arrives
- **paymentDay < today (already passed)**: entry deferred to paymentDay of next month

## Files to modify

| File | What changes |
|------|-------------|
| `packages/shared_services/lib/src/generation/period_generator.dart` | Add `paymentDay` param, add `dateForKey()` method, add date-level filtering |
| `apps/sfinance/lib/services/recurring_generation_service.dart` | Extract `generateForTemplate()`, delegate `_dateForPeriod()` to PeriodGenerator |
| `apps/sfinance/lib/providers/form_providers.dart` | Remove manual first-entry generation from ExpenseFormNotifier and IncomeFormNotifier, call `generateForTemplate()` instead |
| `packages/shared_services/test/generation/period_generator_test.dart` | New tests for paymentDay-aware filtering |
| `apps/sfinance/test/services/recurring_generation_service_test.dart` | Update for new behavior |

## Key constraints

- **Test-first**: Financial logic (date calculation) requires failing tests before implementation (Constitution Principle IV)
- **No schema changes**: `paymentDay` field already exists from feature 005
- **No UI changes**: Pure business logic change
- **Backward-compatible**: `computeDueKeys()` default `paymentDay=1` preserves existing behavior for callers that don't pass it

## Build & test

```bash
# From repo root (use full melos path on this machine)
/c/Users/Sergio/AppData/Local/Pub/Cache/bin/melos.bat run test

# Or per-package:
cd my_apps/packages/shared_services && flutter test
cd my_apps/apps/sfinance && flutter test
```
