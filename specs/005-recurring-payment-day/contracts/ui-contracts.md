# UI Contracts: 005 — Recurring Payment Day

## Day Selector Widget Contract

The day selector appears in both expense and income forms as a `DropdownButtonFormField<int>`.

### Visibility Rules

| Form | Condition to show day selector |
|------|-------------------------------|
| Expense | `categoria ∈ {suscripcion, financiacion}` AND `periodicidad != null` |
| Income (salary) | `categoria == salario` (salary is implicitly mensual) |

### Value Range

| Periodicity | Min | Max | Dynamic update |
|-------------|-----|-----|----------------|
| Mensual | 1 | 31 | Fixed range |
| Anual | 1 | `daysInMonth(fechaFin.month)` | Recalculates when `fechaFin` changes (FR-009); clamps current value if it exceeds new max |

### Default Value

- `1` when selector first appears (FR-007)

### Immutability

- Day selector is **not shown** in edit mode (FR-010)
- Once saved, `paymentDay` cannot be changed

---

## TransactionRow Badge Contract

### Input

| Parameter | Type | When provided |
|-----------|------|---------------|
| `recurringDetail` | `String?` | Non-null for active recurring entries |

### Display Strings

| Periodicity | Format | Example |
|-------------|--------|---------|
| Mensual | `"Día {paymentDay} de cada mes"` | `"Día 15 de cada mes"` |
| Anual | `"{paymentDay} de {monthName}"` | `"10 de junio"` |
| Pre-feature (null paymentDay) | `"Día 1 de cada mes"` | Default fallback |

### Layout

- Text appears as a small label (fontSize ~10) below the existing repeat icon badge
- Inherits the transaction type color (green for income, red for expense)
- Must not overflow the leading avatar area — truncate with ellipsis if needed

---

## Form State Contract

### ExpenseFormState additions

```
paymentDay: int?   // null when not recurring or not yet selected
```

### IncomeFormState additions

```
paymentDay: int?   // null when not salary or not yet selected
```

### Reset behavior

- `setCategoria()` → clears `paymentDay` (along with existing `periodicidad`/`fechaFin` reset)
- `setPeriodicidad()` → clears `paymentDay` (along with existing `fechaFin` reset)
- `setFechaFin()` → if annual and `paymentDay > daysInMonth(newFechaFin)`, clamp `paymentDay` to `daysInMonth(newFechaFin)` (FR-009)

### Validation on submit

- If recurring, `paymentDay` must be non-null and in `[1, 31]`
- If annual, `paymentDay` must be `<= daysInMonth(fechaFin.month)` (enforced by selector range)
