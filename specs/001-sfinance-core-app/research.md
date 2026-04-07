# Research: SFinance Core Application

**Branch**: `001-sfinance-core-app` | **Date**: 2026-04-06

## 1. Charting Library

**Decision**: `fl_chart ^0.69.0`

**Rationale**: MIT licensed, actively maintained (releases every 1-3 months), pure Flutter Canvas rendering with no platform-channel or web overhead. Supports grouped bar charts natively via `BarChartGroupData` with multiple `BarChartRodData` per group, and line charts via `LineChart` with `FlSpot` + dot renderer. All colors are explicitly set per-chart (no system-theme coupling), which fits the dark-first design. Mouse hover tooltips work on desktop.

**Alternatives considered**:
- `syncfusion_flutter_charts`: Feature-rich but carries license friction (community license requires attribution, commercial above $1M revenue). Overkill for an indie app with 4 chart instances.
- `community_charts_flutter`: Apache 2.0 but effectively unmaintained (last release 2023). Desktop support is secondary.

## 2. Storage Layer (Drift / SQLite)

**Decision**: `drift ^2.x` + `drift_dev` (dev) + `sqlite3_flutter_libs` + `build_runner`

**Rationale**: Drift is the most mature Dart SQLite ORM, maintained by a single active author (Simon Binder) with synchronized releases. Provides type-safe queries, code generation, and migration tooling.

**Key patterns adopted**:
- **Enums**: `TextColumn` with `EnumNameConverter` — stores enum `.name` as string. Human-readable, survives reordering (unlike integer index).
- **Dates**: Use Drift's `dateTime()` column shorthand (stores as Unix seconds). Sub-second precision not needed for finance dates.
- **Single-row InitialCapital**: Fixed primary key (`id = 1`) + `insertOnConflictUpdate` (upsert). Expose only `get()` and `set()` methods via DAO.
- **DAOs**: One DAO per table. Keeps query logic out of providers/services (Principle III compliance). Trivially testable.
- **Migrations**: Start with `schemaVersion: 1`. Use `drift_dev schema dump` from day one. Use `stepByStep` migrations for future versions. Treat enum string values as serialization contracts.

**Alternatives considered**:
- `sqflite`: Lower-level, no type-safe queries, no code generation. More boilerplate for the same result.
- `hive` / `isar`: Key-value/NoSQL stores. Poor fit for relational data (transactions linked to templates) and range queries (time-based filtering).

## 3. Recurring Entry Generation Strategy

**Decision**: Period-key based generation with `lastGeneratedPeriod` field per template.

**Rationale**: Deterministic, idempotent, and crash-safe. No separate "generated periods" table needed because the ordered period sequence is fully deterministic from `startDate + periodicity + endDate`.

**Algorithm**:
1. On app launch, load all non-deleted `RecurringTemplate` records.
2. For each template, compute ordered list of period keys from `startDate` through `min(today, endDate)`, excluding keys `<= lastGeneratedPeriod`.
3. For each due period key, insert one `Transaction` and update `lastGeneratedPeriod`.
4. Atomic updates per template for crash safety.

**Period key format**:
- Monthly: `"YYYY-MM"` (e.g., `"2026-04"`)
- Annual: `"YYYY"` (e.g., `"2026"`)
- 14-paga extra months: `"YYYY-MM-extra"` (e.g., `"2026-07-extra"`) — suffixed, distinct from regular monthly key

**14-paga salary handling**: For a bonus month M, two period keys are generated in order: `"YYYY-MM"` (regular) then `"YYYY-MM-extra"` (bonus). Both produce transactions of equal amount. Sorted key ordering `"2026-07" < "2026-07-extra" < "2026-08"` ensures correct sequencing.

**Edge cases**:
| Scenario | Behavior |
|---|---|
| App not opened for months | Generates all due periods in order, one transaction per key |
| End date passed | `min(today, endDate)` caps range; no generation beyond end |
| Template deleted | Filtered out in step 1; past transactions untouched |
| Same-day re-launch | `lastGeneratedPeriod == currentPeriod` → zero new entries |
| Crash mid-generation | `lastGeneratedPeriod` not advanced → next launch retries cleanly |

**Alternatives considered**:
- Storing a `lastGeneratedDate` as DateTime: Less precise — doesn't distinguish regular vs. extra-pay periods in the same month. Period keys are unambiguous.
- Separate `GeneratedPeriod` join table: Unnecessary overhead. The ordered sequence is deterministic, so a single high-water mark suffices.

## 4. Monorepo Setup (Melos)

**Decision**: Melos 6.x with flat dependency graph.

**Rationale**: Melos handles cross-package resolution via symlinks, runs `pub get` across all packages simultaneously, and provides workspace-level script execution.

**Dependency graph**:
```
shared_models   ← pure Dart, no Flutter, no internal dependencies
shared_ui       ← Flutter + shared_models
shared_services ← shared_models + drift (storage layer lives here)
sfinance app    ← all three directly
```

The app depends directly on all three packages. Hiding `shared_models` behind `shared_services` would force awkward re-exports and violate simplicity (Principle VII).

**melos.yaml structure**:
```yaml
name: my_apps
packages:
  - apps/**
  - packages/**
scripts:
  test:
    run: melos exec --fail-fast -- flutter test
    packageFilters:
      dirExists: test
  analyze:
    run: melos exec -- flutter analyze
  format:
    run: melos exec -- dart format .
```

**Alternatives considered**:
- No monorepo tooling (plain path dependencies): Works but loses workspace-level commands (`melos run test`), consistent bootstrapping, and future scalability for the dashboard app.

## 5. Routing (go_router)

**Decision**: `go_router` (latest stable) for centralized, declarative routing.

**Rationale**: Confirmed in plan_prompt as the chosen routing solution. go_router is Flutter's officially recommended router, supports deep linking, and provides a single route configuration. For a 3-view desktop app with modal dialogs, the configuration is minimal.

**Navigation structure**:
- `ShellRoute` wrapping the three main views (Resumen, Analisis, Entradas) with a persistent top navigation bar.
- Modal routes for "+ Ingreso" and "+ Gasto" forms (dialog overlays, not full-page routes).
- Tab state within Entradas (Transacciones / Recurrentes) managed locally via the route or a Riverpod provider — not a separate route.

**Alternatives considered**: None — go_router was a confirmed decision in the plan_prompt.

## 6. State Management Architecture (Riverpod)

**Decision**: Riverpod with globally-scoped providers, organized by domain concern.

**Provider architecture**:
- **Database providers**: Expose DAO instances from the Drift database.
- **Repository/service providers**: Wrap DAOs with business logic (recurring generation, KPI computation).
- **View-state providers**: Expose formatted data for each view (Resumen KPIs, chart data, transaction lists). These watch lower-level providers and transform data for the UI.
- **Form-state providers**: Manage form validation and submission for income/expense modals.

All providers globally scoped per Principle II. No `StateNotifier` or `ChangeNotifier` — use `Notifier` / `AsyncNotifier` (Riverpod 2.x generated families).

**Alternatives considered**: None — Riverpod-only is a constitutional mandate.
