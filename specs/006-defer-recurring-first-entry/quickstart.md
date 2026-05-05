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

---

## Addendum — 2026-04-18 clarification deltas

The three clarification sessions on 2026-04-18 added three follow-up items on top of the original implementation:

### What additionally changes

| Item | Scope |
|------|-------|
| **FR-006 save-time validation** | Reject template persistence when the calculated first occurrence falls after `endDate`. Inline Spanish error message surfaced via the existing `errorMessage` channel. |
| **Open-ended Suscripción tolerance** | Pure helpers must cope with `endDate = null` from spec 001's amendment. No schema work here — only a null-safe short-circuit in FR-006 validation. |
| **Extra-paga paymentDay** | Confirmed already correct; regression tests added. |

### Additional files touched

| File | What changes |
|------|-------------|
| `packages/shared_services/lib/src/generation/period_generator.dart` | Add `firstOccurrenceDate({today, paymentDay})` static helper |
| `apps/sfinance/lib/providers/form_providers.dart` | Call `firstOccurrenceDate`; reject save when result > `endDate` (monthly templates with non-null `endDate` only) |
| `packages/shared_services/test/generation/period_generator_test.dart` | `firstOccurrenceDate` cases; extra-paga regression cases |
| `apps/sfinance/test/providers/expense_form_provider_test.dart` | FR-006 rejection case for Suscripción + Financiación |
| `apps/sfinance/test/providers/income_form_provider_test.dart` | FR-006 rejection case for Salario |

### Hand-verification walkthrough

1. Open the app on 2026-04-18 (day 18).
2. Create a **Financiación** with `paymentDay = 10`, `endDate = 2026-04-30`.
3. Expected: save is rejected with the Spanish error message — no template persisted, no entry generated.
4. Change `endDate` to `2026-05-31` and retry — save succeeds, no entry appears immediately, entry arrives on app launch on/after 2026-05-10.

### Still true

- No schema changes.
- No network calls.
- No new packages.
