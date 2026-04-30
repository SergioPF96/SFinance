# UI Contracts: SFinance Core Application

**Branch**: `001-sfinance-core-app` | **Date**: 2026-04-06

This document defines the interface contracts between the UI layer and the provider/service layer. Each contract specifies what the UI expects to receive and what it sends back, without prescribing widget implementation details.

## Navigation Contract

### App Shell

The app shell provides:
- A persistent top navigation bar with three tabs: **Resumen**, **Analisis**, **Entradas**
- Two action buttons in the top-right: **"+ Ingreso"** (green), **"+ Gasto"** (red/pink)
- The action buttons are always visible regardless of the active tab
- Default route on launch: Resumen

### Routes

| Route | View | Notes |
|-------|------|-------|
| `/resumen` | Resumen dashboard | Default on launch |
| `/analisis` | Analisis charts | |
| `/entradas` | Entradas list | Query param `?tab=transacciones` (default) or `?tab=recurrentes` |

Modal dialogs for "+ Ingreso" and "+ Gasto" are overlay routes, not full-page navigations.

---

## View Contracts

### 1. KPI Strip (shared by Resumen and Analisis)

**Provider output** (KpiState):
```
ingresosCents: int        // Current month total income in cents
gastosCents: int          // Current month total expenses in cents
balanceCents: int         // All-time balance in cents (income - expenses + initial capital if active)
hasTransactions: bool     // Whether any transactions exist (controls initial capital editability)
initialCapitalActive: bool // Whether initial capital is currently contributing to balance
```

**Display rules**:
- Ingresos card: green, format as `+EUR X.XXX,XX` (locale-aware)
- Gastos card: red, format as `-EUR X.XXX,XX`
- Balance card: accent color; if negative, display in red with `-` sign

### 2. Resumen View

**Resumen Mensual Chart** — Provider output (MonthlyChartData):
```
months: List<MonthData>   // Last 6 months (current + 5 prior), ordered chronologically
  MonthData:
    label: String          // Month abbreviation (e.g., "Ene", "Feb")
    ingresosCents: int
    gastosCents: int
```

**Transacciones Recientes** — Provider output (RecentTransactions):
```
transactions: List<TransactionDisplay>  // Most recent 10, ordered by date DESC
  TransactionDisplay:
    id: int
    name: String
    category: String        // Display label (e.g., "Servicio", "Producto")
    date: DateTime
    amountCents: int        // Always positive
    transactionType: TransactionType  // Determines sign and color
    iconColor: Color        // Derived from transactionType (green=income, red=expense)
```

**Display rules**:
- Chart: grouped bars, green (income) and red (expenses) per month
- Transaction rows: colored circular icon, name, "category + date", signed amount
- No delete affordance on Resumen transaction rows (read-only)

### 3. Analisis View

**Chart Data** — Provider output (per chart, 3 independent instances):
```
chartType: ChartType        // balance, gastos, ingresos
timeRange: TimeRange        // Current selected range
dataPoints: List<DataPoint>
  DataPoint:
    date: DateTime
    valueCents: int
```

**TimeRange enum**:
```
ultimos7Dias, ultimoMes, ultimos3Meses, ultimoAnio, desdeOrigen
```

**Display rules**:
- Balance chart: blue line
- Gastos chart: red line
- Ingresos chart: green line
- Default time range on load: `ultimos7Dias`
- Each chart's time range selector is independent

### 4. Entradas View

**Transacciones Tab** — Provider output (FilteredTransactions):
```
transactions: List<TransactionDisplay>  // All matching time range, date DESC
timeRange: TimeRange                     // Current filter
```

**Display rules**:
- Same row layout as Resumen recent transactions
- Delete affordance present on each row (swipe or icon button)
- Deletion triggers confirmation dialog before executing
- Default time range: `ultimos7Dias`

**Recurrentes Tab** — Provider output (ActiveTemplates):
```
templates: List<TemplateDisplay>
  TemplateDisplay:
    id: int
    name: String
    category: String           // Display label
    periodicity: String        // "Mensual" or "Anual"
    endDate: DateTime
    transactionType: TransactionType
```

**Display rules**:
- Each row shows: name, category, periodicity, end date
- Delete affordance on each row
- Deletion triggers confirmation dialog; on confirm, soft-deletes the template

---

## Form Contracts

### Expense Form ("+ Gasto")

**Input fields**:
| Field | Type | Required | Visibility |
|-------|------|----------|------------|
| nombre | `String` | Yes | Always |
| monto | `double` (displayed) -> `int` (cents, stored) | Yes, > 0 | Always |
| descripcion | `String` | No | Always |
| categoria | `ExpenseCategory` dropdown | Yes | Always |
| periodicidad | `Periodicity` dropdown | Yes (when visible) | Only when categoria = suscripcion or financiacion |
| fechaFin | Date picker | Yes (when visible) | Only when periodicidad is visible |

**Fecha de fin picker behavior**:
- When periodicidad = mensual: month+year picker (e.g., "Octubre de 2027")
- When periodicidad = anual: year-only picker (e.g., "2029")
- Only allows future dates (>= today)

**Submission output** (ExpenseFormData):
```
name: String
amountCents: int           // Converted from user input (e.g., 25.50 -> 2550)
description: String?
category: ExpenseCategory
periodicity: Periodicity?  // null for one-off (non-recurring categories)
endDate: DateTime?         // null for one-off
```

**Validation**:
- Name: non-empty after trim
- Amount: > 0, valid numeric format
- Category: must be selected
- Periodicidad: required when category is suscripcion or financiacion
- FechaFin: required when periodicidad is present; must be >= today

### Income Form ("+ Ingreso")

**Input fields**:
| Field | Type | Required | Visibility |
|-------|------|----------|------------|
| nombre | `String` | Yes | Always |
| monto | `double` (displayed) -> `int` (cents, stored) | Yes, > 0 | Always |
| descripcion | `String` | No | Always |
| categoria | `IncomeCategory` dropdown | Yes | Always |
| numeroPagas | `PayFrequency` dropdown | Yes (when visible) | Only when categoria = salario |
| primeraPagaExtra | Month picker (1-12) | Yes (when visible) | Only when numeroPagas = catorcepagas |
| segundaPagaExtra | Month picker (1-12) | Yes (when visible) | Only when numeroPagas = catorcepagas |

**Submission output** (IncomeFormData):
```
name: String
amountCents: int
description: String?
category: IncomeCategory
payFrequency: PayFrequency?   // null for non-salary
extraPayMonth1: int?          // 1-12, null for non-14-pagas
extraPayMonth2: int?          // 1-12, must differ from extraPayMonth1
```

**Validation**:
- Same base validations as expense form
- NumeroPagas: required when category is salario
- Extra pay months: required when payFrequency = catorcepagas; must be distinct

### Confirmation Dialog

Used for all delete operations (transactions and templates).

**Input**:
```
title: String               // e.g., "Eliminar transaccion"
message: String             // e.g., "Esta accion no se puede deshacer."
confirmLabel: String        // e.g., "Eliminar"
cancelLabel: String         // e.g., "Cancelar"
```

**Output**: `bool` (confirmed or cancelled)

### Initial Capital Dialog (first-launch modal)

**Visibility**: Shown as a non-dismissable modal (`barrierDismissible: false`) on the first frame after Resumen loads, when `hasTransactions == false` AND `initialCapitalProvider.isActive == false` (i.e. no capital has been set yet). Once the user confirms, `isActive` becomes `true` and the dialog never reopens.

**Input**: Euro amount field with `EuroAmountFormatter` — thousands dots as display-only separators, comma as decimal separator (`.` also accepted and echoed as `,`), max 2 decimal places.

**Submission output**: `int` (amountCents); on success calls `Navigator.of(context).pop()`.

---

## Provider Contract Summary

| Provider | Watches | Exposes | Used by |
|----------|---------|---------|---------|
| `kpiProvider` | Transaction table, InitialCapital | `KpiState` | Resumen, Analisis |
| `monthlyChartProvider` | Transaction table | `MonthlyChartData` | Resumen |
| `recentTransactionsProvider` | Transaction table | `List<TransactionDisplay>` (limit 10) | Resumen |
| `analysisChartProvider(chartType)` | Transaction table, time range state | `List<DataPoint>` | Analisis |
| `filteredTransactionsProvider` | Transaction table, time range state | `List<TransactionDisplay>` | Entradas (Transacciones tab) |
| `activeTemplatesProvider` | RecurringTemplate table | `List<TemplateDisplay>` | Entradas (Recurrentes tab) |
| `expenseFormProvider` | — | Form state + validation | Expense modal |
| `incomeFormProvider` | — | Form state + validation | Income modal |
| `initialCapitalProvider` | InitialCapital table | `InitialCapitalState` | Resumen (Balance card) |
| `recurringGenerationService` | RecurringTemplate table | — (side-effect only) | App initialization |
