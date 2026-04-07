# SFinance

Personal finance desktop app built with Flutter. Tracks income, expenses, and recurring entries (subscriptions, salary, financing). All data is stored locally on-device — no accounts, no cloud, no telemetry.

## Features

- **Resumen dashboard** — monthly KPI cards (Ingresos, Gastos, Balance), last 6-month bar chart, recent transactions
- **Análisis view** — independent line charts for Balance, Gastos, and Ingresos with selectable time ranges (7 days to all time)
- **Entradas view** — full transaction history with filters; manage recurring templates
- **Recurring entries** — subscriptions, financing, and salary (including 14-paga with bonus months) generated automatically on launch
- **One-off entries** — record any income or expense in a few keystrokes
- **Initial capital** — set a starting balance before your first transaction

## Setup

### Prerequisites

- Flutter SDK (stable channel): `flutter channel stable && flutter upgrade`
- Melos: `dart pub global activate melos`
- Windows desktop support enabled in Flutter

### Bootstrap

```bash
cd my_apps/
melos bootstrap
```

### Run

```bash
cd my_apps/apps/sfinance/
flutter run -d windows
```

## Development

### Run all tests

```bash
# From each package directory individually (Melos interactive mode is not supported in all terminals):
cd my_apps/packages/shared_services && flutter test
cd my_apps/packages/shared_ui       && flutter test
cd my_apps/apps/sfinance            && flutter test
```

### Analyze

```bash
cd my_apps/
melos exec -- flutter analyze
```

### Format

```bash
cd my_apps/
melos exec -- dart format .
```

### Regenerate Drift code

Run after any change to Drift table definitions in `packages/shared_services/lib/src/database/tables/`:

```bash
cd my_apps/packages/shared_services/
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure

```
my_apps/apps/sfinance/
├── lib/
│   ├── main.dart                          # Entry point, database init, RecurringGenerationService
│   ├── app.dart                           # MaterialApp.router + dark theme
│   ├── routing/
│   │   └── app_router.dart               # GoRouter: ShellRoute (3 tabs) + modal routes
│   ├── providers/                         # Riverpod providers (globally scoped)
│   │   ├── kpi_provider.dart             # Ingresos / Gastos / Balance KPIs
│   │   ├── chart_providers.dart          # Monthly bar chart + analysis line charts
│   │   ├── transaction_providers.dart    # Recent + filtered transaction streams
│   │   ├── template_providers.dart       # Active recurring templates stream
│   │   ├── form_providers.dart           # Expense and income form state + submission
│   │   └── dao_providers.dart            # DAO and database providers
│   ├── ui/                               # Presentational widgets only
│   │   ├── shell/app_shell.dart          # Nav bar, "+ Ingreso" / "+ Gasto" buttons
│   │   ├── resumen/                      # KPI strip, bar chart, recent list
│   │   ├── analisis/                     # Line charts, time range selectors
│   │   ├── entradas/                     # Transaction list, recurring templates
│   │   └── forms/                        # Expense form, income form
│   └── services/
│       └── recurring_generation_service.dart
└── test/
    ├── providers/                         # kpiProvider, chartProviders
    └── services/                          # RecurringGenerationService
```

## Shared Packages

| Package | Purpose |
|---------|---------|
| `shared_models` | Pure Dart models: Transaction, RecurringTemplate, InitialCapital, enums |
| `shared_ui` | Widgets (KpiCard, TransactionRow, ConfirmationDialog), theme, CurrencyFormatter, DateFormatter |
| `shared_services` | Drift database, DAOs, PeriodGenerator |

## Key Decisions

| Concern | Decision |
|---------|----------|
| State management | Riverpod 2.x — all providers globally scoped, `Notifier`/`AsyncNotifier` |
| Routing | go_router — `ShellRoute` for 3-tab nav, overlay modals for forms |
| Storage | Drift (SQLite) — local on-device, integer cents for all monetary values |
| Recurring logic | `lastGeneratedPeriod` per template; generation runs once at app launch |
| Formatting | `intl` — Spanish locale, `€` always prefixed, explicit +/− signs |
| Monorepo | Melos 7.x with Dart pub workspace (requires Dart ≥3.5) |
| Tests | Financial logic (KPIs, chart aggregation, period generation) uses Red-Green-Refactor |
