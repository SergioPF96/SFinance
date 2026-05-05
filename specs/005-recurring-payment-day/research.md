# Research: 005 — Recurring Payment Day

## R-001: Where does `paymentDay` belong in the data layer?

**Decision**: Add `paymentDay` as an `INTEGER` column to the `RecurringTemplates` Drift table (shared_services) and a matching `int paymentDay` field to the `RecurringTemplate` model (shared_models).

**Rationale**: The field is intrinsic to the recurring template concept — it determines when generated occurrences land in each period. It belongs alongside `periodicity`, `startDate`, and `endDate` in the same table. No new table or entity is needed.

**Alternatives considered**:
- Separate `PaymentSchedule` entity → rejected: over-engineering for a single integer field. Violates Constitution VII (simplicity).
- Store as part of `startDate` day component → rejected: conflates "when did the user create this" with "what day should payments land on". The spec explicitly decouples these (FR-003: first occurrence may skip to next month).

---

## R-002: Drift schema migration v1 → v2

**Decision**: Add `paymentDay` as a nullable `INTEGER` column via `ALTER TABLE recurring_templates ADD COLUMN payment_day INTEGER`. Backfill existing rows with `1` (spec edge case: "entradas sin día definido reciben día 1"). Then set `schemaVersion => 2` and implement `MigrationStrategy` with `onUpgrade` callback.

**Rationale**: Drift does not support altering a column to NOT NULL after creation with a default for existing rows in a single DDL statement on SQLite. The safe pattern is: (1) add nullable column, (2) UPDATE to backfill, (3) leave as nullable in Drift definition with application-level default. Alternatively, since all new inserts will always provide the value and the backfill sets existing rows to 1, the column can remain nullable at the DB level with the Dart model treating `null` as `1`.

**Alternatives considered**:
- Recreate table with NOT NULL constraint → rejected: requires copying all data, rebuilding foreign keys, and is fragile for a single column addition.
- Use Drift's `clientDefault` → only applies to new inserts, does not backfill existing rows.

---

## R-003: How should `_dateForPeriod` use `paymentDay`?

**Decision**: Modify `RecurringGenerationService._dateForPeriod()` to accept a `paymentDay` parameter (from the template). For monthly keys (`"YYYY-MM"`), generate `DateTime(year, month, clampedDay)` where `clampedDay = min(paymentDay, daysInMonth(year, month))`. For annual keys (`"YYYY"`), extract the month from `endDate` and use `DateTime(year, endDate.month, clampedDay)`. For extra keys (`"YYYY-MM-extra"`), use the same clamped day as the regular monthly key.

**Rationale**: This is the minimal change to the existing generation pipeline. `PeriodGenerator.computeDueKeys()` continues to return period keys unchanged — the keys identify *which* periods are due, not *what date* within each period. The date resolution stays in `_dateForPeriod()`.

**Alternatives considered**:
- Encode `paymentDay` into the period key (e.g., `"2026-04-15"`) → rejected: breaks lexicographic ordering assumptions, requires changes to `_compareKeys`, and mixes concerns (period identification vs. date resolution).
- Move date resolution into `PeriodGenerator` → rejected: `PeriodGenerator` is pure computation in shared_services; `_dateForPeriod` is in the app service. Adding template-specific knowledge to `PeriodGenerator` increases coupling unnecessarily.

---

## R-004: First occurrence logic for monthly recurring (FR-003)

**Decision**: In `ExpenseFormNotifier.submit()` and `IncomeFormNotifier.submit()`, when creating the first transaction for a monthly recurring: compare `paymentDay` (clamped to current month length) with `today.day`. If `clampedDay < today.day`, the first occurrence date is `DateTime(nextMonth.year, nextMonth.month, clampedDay)` and `lastGeneratedPeriod` is set to next month's key. If `clampedDay >= today.day`, the first occurrence is `DateTime(today.year, today.month, clampedDay)` and `lastGeneratedPeriod` is set to the current month's key.

**Rationale**: The spec says "si el día ya pasó en el mes actual, la primera entrada se genera el mes siguiente". The edge case "día == hoy → no ha pasado" is explicitly called out. This logic only runs at form submit time; subsequent generation uses `PeriodGenerator` + `_dateForPeriod` as usual.

**Alternatives considered**:
- Let `PeriodGenerator` handle first occurrence specially → rejected: PeriodGenerator uses `startDate` as lower bound. Setting `startDate` to today and letting the generator decide would work but requires the generator to understand paymentDay, increasing its responsibility. The form submit already handles first-occurrence creation inline.

---

## R-005: Day selector UI widget

**Decision**: Use a `DropdownButtonFormField<int>` with values 1–31 for monthly recurring, or 1–N (N = days in end-date month) for annual recurring. Place it immediately after the Periodicidad dropdown in both expense and income forms. The selector is only visible when `periodicidad != null`. For annual, the max day updates dynamically when `fechaFin` changes (FR-009).

**Rationale**: A dropdown is consistent with the existing form patterns (Periodicidad, NumeroPagas, MonthPicker all use `DropdownButtonFormField`). 31 items is a reasonable dropdown size on desktop. No new dependency needed.

**Alternatives considered**:
- NumberPicker / spinner widget → requires a new dependency; violates Constitution VII (justify every package).
- Free-text input with validation → error-prone UX; inconsistent with existing dropdowns.
- Slider → poor precision for exact day selection.

---

## R-006: Badge display in Entradas list (FR-008)

**Decision**: Extend `TransactionRow` in shared_ui with an optional `String? recurringDetail` parameter. When non-null, display it as a small text label below or beside the repeat icon. The entradas view constructs this string: `"Día $paymentDay de cada mes"` for monthly, `"$paymentDay de $monthName"` for annual. This requires `TransactionDisplay` to carry `paymentDay` and `periodicity` from the template.

**Rationale**: The spec says "el badge o detalle muestra 'Día 15 de cada mes'" — this is a text label, not just an icon. The existing repeat icon stays; we add a text detail. The data flows through the LEFT JOIN that already resolves template status.

**Alternatives considered**:
- Show day info only in a detail panel (not in the list row) → rejected: spec SC-005 says "visible sin necesidad de abrir un detalle adicional".
- Encode day info in the subtitle string → rejected: mixes category/date subtitle with recurrence detail; harder to style distinctly.

---

## R-007: Impact on existing templates (backward compatibility)

**Decision**: Existing templates (created before this feature) have `payment_day = NULL` in the database after migration backfill sets them to `1`. The model and generation logic treat `null` / `1` equivalently. No recalculation of already-generated transactions.

**Rationale**: Spec assumption: "entradas recurrentes ya existentes sin día definido reciben el día 1 como valor retroactivo por defecto; sus ocurrencias pasadas ya generadas no se recalculan." Since the current code already generates all occurrences on day 1 (`DateTime(year, month, 1)`), setting `paymentDay = 1` for existing templates is semantically a no-op — future generated transactions will continue to land on day 1.

**Alternatives considered**:
- Retroactively update existing transactions' dates → rejected: spec explicitly forbids this.
- Leave existing templates at `null` and treat `null` as "use startDate.day" → rejected: inconsistent behavior; spec says default is day 1.

---

## R-008: Salary (income) templates and paymentDay

**Decision**: Salary templates also get `paymentDay`. When creating a salary via `IncomeFormNotifier`, the day selector appears after the NumeroPagas dropdown (since salary is always mensual). The same first-occurrence logic (R-004) applies.

**Rationale**: Salaries are the canonical "same day every month" use case. Excluding them would be a significant UX gap. The income form already shows conditional fields based on category — adding one more conditional field is consistent.

**Alternatives considered**:
- Separate salary day logic from expense day logic → rejected: the underlying mechanism is identical (paymentDay on RecurringTemplate). No reason to diverge.
