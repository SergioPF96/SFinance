# Tasks: SFinance Core Application

**Input**: Design documents from `/specs/001-sfinance-core-app/`
**Branch**: `001-sfinance-core-app`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. Financial logic tasks include mandatory failing tests before implementation (constitution requirement).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared-state dependencies)
- **[Story]**: Which user story this task belongs to (US1–US7)
- Exact file paths are included in all task descriptions

## Path Conventions

- **App source**: `my_apps/apps/sfinance/lib/`
- **App tests**: `my_apps/apps/sfinance/test/`
- **Shared models**: `my_apps/packages/shared_models/lib/src/`
- **Shared UI**: `my_apps/packages/shared_ui/lib/src/`
- **Shared services**: `my_apps/packages/shared_services/lib/src/`
- **Providers**: `my_apps/apps/sfinance/lib/providers/` — globally scoped, no widget-local providers
- **Widgets**: `my_apps/apps/sfinance/lib/ui/` — presentational only, no business logic

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the monorepo skeleton and package manifests so every subsequent task has a valid project to build into.

- [ ] T001 Create monorepo directory structure (my_apps/, apps/sfinance/, packages/shared_models/, packages/shared_ui/, packages/shared_services/) and my_apps/melos.yaml with workspace + test/analyze/format scripts
- [ ] T002 Create my_apps/packages/shared_models/pubspec.yaml (pure Dart, no Flutter dependency, intl for formatting helpers)
- [ ] T003 [P] Create my_apps/packages/shared_ui/pubspec.yaml (Flutter, depends on shared_models; includes fl_chart, intl)
- [ ] T004 [P] Create my_apps/packages/shared_services/pubspec.yaml (depends on shared_models; includes drift, sqlite3_flutter_libs, riverpod; dev: drift_dev, build_runner)
- [ ] T005 [P] Create my_apps/apps/sfinance/pubspec.yaml (Flutter app; depends on all three packages, flutter_riverpod, go_router)

**Checkpoint**: `melos bootstrap` runs without errors; all packages resolve dependencies.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure — models, database layer, period generator, formatters, shared widgets, app shell, and routing. No user story can begin until this phase is complete.

**⚠️ CRITICAL**: All Phase 3+ work is blocked until this phase is complete.

### 2a — Shared Models (pure Dart, no Flutter imports)

- [ ] T006 Create enums (TransactionType, ExpenseCategory, IncomeCategory, Periodicity, PayFrequency) in my_apps/packages/shared_models/lib/src/enums/ (one file per enum, EnumNameConverter-compatible names)
- [ ] T007 [P] Create Transaction model (id, name, amountCents, description?, transactionType, category, date, templateId?, createdAt) in my_apps/packages/shared_models/lib/src/transaction.dart
- [ ] T008 [P] Create RecurringTemplate model (id, name, amountCents, transactionType, category, periodicity, startDate, endDate, payFrequency?, extraPayMonth1?, extraPayMonth2?, lastGeneratedPeriod?, isDeleted, createdAt) in my_apps/packages/shared_models/lib/src/recurring_template.dart
- [ ] T009 [P] Create InitialCapital model (id fixed=1, amountCents, isActive) in my_apps/packages/shared_models/lib/src/initial_capital.dart
- [ ] T010 Create shared_models barrel export in my_apps/packages/shared_models/lib/shared_models.dart (exports all enums and models)

### 2b — Shared Services: Database Layer

- [ ] T011 Create Drift transactions table definition (columns matching Transaction model, indexes on date DESC and templateId) in my_apps/packages/shared_services/lib/src/database/tables/transactions.dart
- [ ] T012 [P] Create Drift recurring_templates table definition (all RecurringTemplate fields, EnumNameConverter for category/periodicity/payFrequency) in my_apps/packages/shared_services/lib/src/database/tables/recurring_templates.dart
- [ ] T013 [P] Create Drift initial_capital table definition (fixed PK id=1, amountCents, isActive) in my_apps/packages/shared_services/lib/src/database/tables/initial_capital.dart
- [ ] T014 Create AppDatabase class (@DriftDatabase with all three tables, schemaVersion: 1) in my_apps/packages/shared_services/lib/src/database/app_database.dart
- [ ] T015 Run build_runner to generate Drift code in my_apps/packages/shared_services/ (`dart run build_runner build --delete-conflicting-outputs`); commit generated .g.dart files
- [ ] T016 Create TransactionDao (insert, watchRecent(limit), watchFiltered(dateRange), delete, watchMonthly(months), watchAll) in my_apps/packages/shared_services/lib/src/database/daos/transaction_dao.dart
- [ ] T017 [P] Create TemplateDao (insert, watchActive, softDelete(id), updateLastGeneratedPeriod) in my_apps/packages/shared_services/lib/src/database/daos/template_dao.dart
- [ ] T018 [P] Create InitialCapitalDao (get, upsert, deactivate) in my_apps/packages/shared_services/lib/src/database/daos/initial_capital_dao.dart
- [ ] T019 Create shared_services barrel export in my_apps/packages/shared_services/lib/shared_services.dart

### 2c — Shared Services: Period Generator (test-first — financial logic)

- [ ] T020 Write failing unit tests for PeriodGenerator: period key computation (monthly "YYYY-MM", annual "YYYY", 14-paga extra "YYYY-MM-extra"), ordered sequence from startDate to min(today,endDate), filtering keys ≤ lastGeneratedPeriod, edge cases (no-launch-gap, end-date-past, same-day-relaunch) in my_apps/packages/shared_services/test/generation/period_generator_test.dart
- [ ] T021 Implement PeriodGenerator (pure computation, no DB calls; takes startDate, endDate, periodicity, lastGeneratedPeriod?, extraPayMonths?; returns ordered List<String> of due period keys) in my_apps/packages/shared_services/lib/src/generation/period_generator.dart — T020 tests must be green before this task is done

### 2d — Shared UI: Formatters + Theme + Base Widgets (formatter tests first)

- [ ] T022 Write failing unit tests for CurrencyFormatter: EUR symbol always present, locale-aware separators (Spanish locale: comma decimal, period thousands), "+€X,XX" for income, "−€X,XX" for expense, zero formatted as "€0,00" in my_apps/packages/shared_ui/test/formatters/currency_formatter_test.dart
- [ ] T023 Implement CurrencyFormatter (formats int cents → locale string with explicit sign and € symbol using intl NumberFormat) in my_apps/packages/shared_ui/lib/src/formatters/currency_formatter.dart — T022 tests must be green before this task is done
- [ ] T024 [P] Implement DateFormatter (formats DateTime → unambiguous display string, e.g. "6 abr. 2026") in my_apps/packages/shared_ui/lib/src/formatters/date_formatter.dart
- [ ] T025 Create app dark theme and color constants (dark background, green income, red expense, blue balance, accent colors, WCAG AA contrast) in my_apps/packages/shared_ui/lib/src/theme/app_theme.dart
- [ ] T026 Create TransactionRow widget (colored circular icon, name, "category · date" subtitle, signed amount with color) in my_apps/packages/shared_ui/lib/src/widgets/transaction_row.dart
- [ ] T027 [P] Create KpiCard widget (label, formatted amount, color; accepts amountCents + sign rule) in my_apps/packages/shared_ui/lib/src/widgets/kpi_card.dart
- [ ] T028 [P] Create ConfirmationDialog widget (title, message, confirmLabel, cancelLabel; returns bool) in my_apps/packages/shared_ui/lib/src/widgets/confirmation_dialog.dart
- [ ] T029 Create shared_ui barrel export in my_apps/packages/shared_ui/lib/shared_ui.dart

### 2e — App Infrastructure (sfinance)

- [ ] T030 Create databaseProvider (Riverpod Provider exposing AppDatabase singleton, opened once at startup) in my_apps/apps/sfinance/lib/providers/database_provider.dart
- [ ] T031 Create main.dart (ProviderScope wrapping the app, async database initialization before runApp) in my_apps/apps/sfinance/lib/main.dart
- [ ] T032 [P] Create app.dart (MaterialApp.router with dark theme from shared_ui, GoRouter from app_router.dart) in my_apps/apps/sfinance/lib/app.dart
- [ ] T033 Create app_router.dart (ShellRoute with Resumen/Analisis/Entradas sub-routes; overlay modal routes for expense and income forms; default route /resumen) in my_apps/apps/sfinance/lib/routing/app_router.dart
- [ ] T034 Create AppShell widget (persistent top navigation bar with 3 tabs; "+ Ingreso" green button and "+ Gasto" red button always visible in top-right) in my_apps/apps/sfinance/lib/ui/shell/app_shell.dart

**Checkpoint**: App launches to empty Resumen shell. Shell nav and action buttons are visible. No providers wired yet.

---

## Phase 3: User Story 1 — Record a One-Off Expense (Priority: P1) 🎯 MVP

**Goal**: User opens "+ Gasto", fills in name/amount/category (Producto, Servicio, or Suministro variable), confirms, and the expense immediately appears in Resumen's Transacciones Recientes list with KPI cards updated.

**Independent Test**: Record "Cena" (Servicio, €25.50) → verify "−€25,50" appears in red in Transacciones Recientes with the Servicio label and today's date; verify Gastos KPI increases by €25.50.

### Tests for US1 (financial logic — constitution requirement)

- [ ] T035 [P] [US1] Write failing unit tests for kpiProvider: monthly Ingresos = sum of current-month income, monthly Gastos = sum of current-month expenses, Balance = all-time income minus all-time expenses (plus active initial capital), values update when transactions are added/deleted in my_apps/apps/sfinance/test/providers/kpi_provider_test.dart

### Implementation for US1

- [ ] T036 [US1] Create form_providers.dart with expenseFormProvider (Notifier; manages nombre, monto, descripcion, categoria fields; validates non-empty name, positive monto, required categoria; saves one-off transaction via TransactionDao on submit) in my_apps/apps/sfinance/lib/providers/form_providers.dart
- [ ] T037 [US1] Implement kpiProvider (AsyncNotifier watching TransactionDao streams and InitialCapitalDao; computes ingresosCents, gastosCents, balanceCents, hasTransactions, initialCapitalActive per KpiState contract) in my_apps/apps/sfinance/lib/providers/kpi_provider.dart — T035 tests must be green before this task is done
- [ ] T038 [US1] Implement recentTransactionsProvider (StreamProvider watching TransactionDao.watchRecent(limit: 10), maps rows to TransactionDisplay with iconColor derived from transactionType) in my_apps/apps/sfinance/lib/providers/transaction_providers.dart
- [ ] T039 [US1] Build expense form modal widget (text fields for nombre/descripcion, numeric field for monto, ExpenseCategory dropdown; for US1 shows Producto/Servicio/SuministroVariable only; submit wires to expenseFormProvider; keyboard-navigable) in my_apps/apps/sfinance/lib/ui/forms/expense_form.dart
- [ ] T040 [US1] Build Resumen view (KPI strip using KpiCard widgets from shared_ui watching kpiProvider; "Transacciones Recientes" section using TransactionRow widgets watching recentTransactionsProvider; read-only list, no delete affordance) in my_apps/apps/sfinance/lib/ui/resumen/resumen_view.dart

**Checkpoint**: US1 fully functional. "+ Gasto" records an expense; it appears in Resumen list; KPI cards update. No bar chart yet.

---

## Phase 4: User Story 2 — Record Income (Priority: P2)

**Goal**: User opens "+ Ingreso", records one-off income (Venta, Servicio) or a Salario with 14-paga configuration; income appears in Ingresos KPI and transaction list; recurring salary entries are generated automatically on app launch.

**Independent Test**: Record Salario (14 pagas, July + December extra) → verify a regular monthly entry is generated immediately; simulate a future app launch in July → verify one regular + one extra entry for July appear; Ingresos KPI reflects the salary.

### Tests for US2 (financial logic — constitution requirement)

- [ ] T041 [US2] Write failing unit tests for RecurringGenerationService: generates exactly one entry on first save (today's period), generates all due periods on subsequent launches, generates extra entry for 14-paga bonus months, does not duplicate already-generated periods, stops at endDate, skips soft-deleted templates in my_apps/apps/sfinance/test/services/recurring_generation_service_test.dart

### Implementation for US2

- [ ] T042 [US2] Add incomeFormProvider to form_providers.dart (Notifier; manages nombre, monto, descripcion, categoria, numeroPagas, primeraPagaExtra, segundaPagaExtra; validates distinct extra months when 14-paga selected; creates Transaction for one-off income or RecurringTemplate + first entry for Salario) in my_apps/apps/sfinance/lib/providers/form_providers.dart
- [ ] T043 [US2] Implement RecurringGenerationService (loads non-deleted templates via TemplateDao; uses PeriodGenerator to compute due keys; for each key inserts a Transaction and updates lastGeneratedPeriod atomically; runs on app startup) in my_apps/apps/sfinance/lib/services/recurring_generation_service.dart — T041 tests must be green before this task is done
- [ ] T044 [US2] Wire RecurringGenerationService.run() call in app initialization before the first frame renders in my_apps/apps/sfinance/lib/main.dart
- [ ] T045 [US2] Build income form modal widget (fields always shown: nombre, monto, descripcion, categoria; NumeroPagas dropdown visible only when categoria=Salario; extra month pickers visible only when 14 pagas selected; pickers enforce distinct months; keyboard-navigable) in my_apps/apps/sfinance/lib/ui/forms/income_form.dart

**Checkpoint**: US2 fully functional. Both one-off and salary income record correctly. Recurring salary generation runs on launch.

---

## Phase 5: User Story 3 — Record a Recurring Subscription or Financing Expense (Priority: P3)

**Goal**: User selects Suscripción or Financiación in the expense form; Periodicidad and Fecha de fin fields appear; one entry is generated on save; future entries are generated on subsequent app launches.

**Independent Test**: Record monthly Suscripción (Claude Pro, €20, end date 2027-12) → exactly one entry generated immediately; simulate app launch one month later → second entry appears; simulate app launch after end date → no further entries generated.

- [ ] T046 [US3] Extend expenseFormProvider in form_providers.dart to handle Suscripción and Financiación: add periodicidad and fechaFin fields to form state; validate fechaFin >= today when periodicidad is set; on submit, create RecurringTemplate + first Transaction entry (instead of bare Transaction) in my_apps/apps/sfinance/lib/providers/form_providers.dart
- [ ] T047 [US3] Update expense form modal to conditionally show Periodicidad dropdown and Fecha de fin picker when categoria is Suscripción or Financiación; hide both fields for all other categories in my_apps/apps/sfinance/lib/ui/forms/expense_form.dart
- [ ] T048 [US3] Add Fecha de fin date picker widget (month+year picker when Periodicidad=Mensual; year-only picker when Periodicidad=Anual; only allows dates >= today) in my_apps/apps/sfinance/lib/ui/forms/expense_form.dart

**Checkpoint**: US3 fully functional. Subscription/financing templates created; generation service handles them correctly.

---

## Phase 6: User Story 4 — View the Resumen Dashboard (Priority: P4)

**Goal**: Resumen view is complete: KPI strip (Ingresos, Gastos, Balance), editable Balance/initial capital before first transaction, Resumen Mensual grouped bar chart (last 6 months), Transacciones Recientes list.

**Independent Test**: Record a mix of income and expense entries across multiple months → KPI cards show correct current-month totals; bar chart shows last 6 months with correct green/red bars; recent list shows correctly formatted rows. On a fresh install with no transactions → Balance card is editable; entering initial capital updates the Balance KPI.

### Tests for US4 (financial logic — constitution requirement)

- [ ] T049 [US4] Write failing unit tests for monthlyChartProvider: last 6 months window computed correctly, each month's ingresosCents/gastosCents aggregated from Transaction table, months with no transactions appear as zero, current month is last in list in my_apps/apps/sfinance/test/providers/chart_providers_test.dart

### Implementation for US4

- [ ] T050 [US4] Implement monthlyChartProvider (AsyncNotifier watching TransactionDao; computes MonthlyChartData for last 6 months; aggregates ingresosCents and gastosCents per calendar month; includes abbreviated Spanish month label) in my_apps/apps/sfinance/lib/providers/chart_providers.dart — T049 tests must be green before this task is done
- [ ] T051 [US4] Implement initialCapitalProvider (AsyncNotifier watching InitialCapitalDao; exposes amountCents and isActive; provides setInitialCapital action; automatically inactive once first transaction exists per hasTransactions from kpiProvider) in my_apps/apps/sfinance/lib/providers/initial_capital_provider.dart
- [ ] T052 [US4] Build ResumenMensual grouped bar chart widget (fl_chart BarChart with BarChartGroupData; green bars for ingresos, red bars for gastos; month labels on x-axis; watching monthlyChartProvider) in my_apps/apps/sfinance/lib/ui/resumen/monthly_bar_chart.dart
- [ ] T053 [US4] Integrate bar chart and initial capital editor into Resumen view: add MonthlyBarChart below KPI strip; add inline amount editor to Balance KpiCard when initialCapitalProvider reports active and no transactions exist in my_apps/apps/sfinance/lib/ui/resumen/resumen_view.dart

**Checkpoint**: US4 fully functional. Resumen dashboard is complete and correct.

---

## Phase 7: User Story 5 — Analyse Trends Over Time (Priority: P5)

**Goal**: Análisis view shows the same KPI strip as Resumen plus three stacked, independent line charts (Balance blue, Gastos red, Ingresos green), each with its own time range selector defaulting to Últimos 7 días.

**Independent Test**: Open Análisis → set Balance chart to "Último año" and Gastos chart to "Últimos 7 días" → verify each chart updates independently with correct data for its selected range; all default to "Últimos 7 días" on first load.

### Tests for US5 (financial logic — constitution requirement)

- [ ] T054 [US5] Write failing unit tests for analysisChartProvider: correct data points for each TimeRange option, balance data points computed as running cumulative total, each chart type (balance/gastos/ingresos) aggregates the correct transaction subset, independent state per chart type in my_apps/apps/sfinance/test/providers/chart_providers_test.dart

### Implementation for US5

- [ ] T055 [US5] Implement analysisChartProvider (family AsyncNotifier parameterized by ChartType; maintains independent TimeRange state per chart; queries TransactionDao with date filter; computes List<DataPoint> — balance as cumulative running total, gastos/ingresos as per-day sums) in my_apps/apps/sfinance/lib/providers/chart_providers.dart — T054 tests must be green before this task is done
- [ ] T056 [US5] Build TimeRangeSelector widget (segmented control with 5 options: Últimos 7 días, Último mes, Últimos 3 meses, Último año, Desde origen; callbacks on selection change; keyboard-accessible) in my_apps/apps/sfinance/lib/ui/analisis/time_range_selector.dart
- [ ] T057 [US5] Build AnalysisLineChart widget (fl_chart LineChart; accepts List<DataPoint> and a color; shows dots and tooltip on hover/tap; handles empty state) in my_apps/apps/sfinance/lib/ui/analisis/analysis_line_chart.dart
- [ ] T058 [US5] Build Analisis view (KPI strip watching kpiProvider; three stacked AnalysisLineChart widgets each paired with an independent TimeRangeSelector; each chart watches its own analysisChartProvider(chartType) instance) in my_apps/apps/sfinance/lib/ui/analisis/analisis_view.dart

**Checkpoint**: US5 fully functional. Análisis charts update independently per selected time range.

---

## Phase 8: User Story 6 — Browse All Transactions (Priority: P6)

**Goal**: Entradas view (Transacciones tab) shows all transactions filtered by a time range selector; user can permanently delete a transaction after confirmation; Resumen list does not expose a delete affordance.

**Independent Test**: Navigate to Entradas → default shows last 7 days; switch to "Desde origen" → all transactions visible; delete a transaction after confirmation → entry removed, KPI cards update; switch to Resumen → no delete affordance on rows there.

- [ ] T059 [US6] Implement filteredTransactionsProvider (StreamProvider.family accepting TimeRange; queries TransactionDao.watchFiltered(dateRange); maps rows to TransactionDisplay; date DESC order) in my_apps/apps/sfinance/lib/providers/transaction_providers.dart
- [ ] T060 [US6] Build Entradas view shell (tab controller toggling between "Transacciones" and "Recurrentes" tabs; default tab = Transacciones; time range selector visible only on Transacciones tab) in my_apps/apps/sfinance/lib/ui/entradas/entradas_view.dart
- [ ] T061 [US6] Build Transacciones tab (TransactionRow list watching filteredTransactionsProvider; delete icon on each row; no delete affordance added to Resumen list; keyboard-accessible delete action) in my_apps/apps/sfinance/lib/ui/entradas/transacciones_tab.dart
- [ ] T062 [US6] Wire transaction delete in Transacciones tab: show ConfirmationDialog on delete icon tap; on confirm call TransactionDao.delete(id); kpiProvider and filteredTransactionsProvider auto-refresh via Drift streams in my_apps/apps/sfinance/lib/ui/entradas/transacciones_tab.dart

**Checkpoint**: US6 fully functional. Full transaction history browseable and deletable.

---

## Phase 9: User Story 7 — Manage Recurring Templates (Priority: P7)

**Goal**: Entradas Recurrentes tab lists all active recurring templates (subscriptions, financing, salary); user can delete a template after confirmation; past entries from deleted templates are preserved.

**Independent Test**: Create a subscription → navigate to Entradas → Recurrentes → verify row shows name, category, periodicity, end date; delete with confirmation → template disappears; switch to Transacciones → previously generated entries are still present.

- [ ] T063 [US7] Implement activeTemplatesProvider (StreamProvider watching TemplateDao.watchActive(); maps rows to TemplateDisplay with display-formatted category, periodicity, endDate) in my_apps/apps/sfinance/lib/providers/template_providers.dart
- [ ] T064 [US7] Build Recurrentes tab (TemplateDisplay list watching activeTemplatesProvider; each row shows name, category, periodicity, end date; delete icon on each row; keyboard-accessible) in my_apps/apps/sfinance/lib/ui/entradas/recurrentes_tab.dart
- [ ] T065 [US7] Wire template soft-delete in Recurrentes tab: show ConfirmationDialog on delete icon tap; on confirm call TemplateDao.softDelete(id); activeTemplatesProvider auto-refreshes; previously generated Transaction entries are unaffected in my_apps/apps/sfinance/lib/ui/entradas/recurrentes_tab.dart

**Checkpoint**: US7 fully functional. Templates manageable; deletion stops future generation without touching past entries.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: End-to-end validation and accessibility hardening across all user stories.

- [ ] T066 [P] Audit all monetary amount displays across the app for compliance with FR-030 (explicit +/− sign, € symbol, locale-aware separators, green/red color) in my_apps/apps/sfinance/lib/ui/ and my_apps/packages/shared_ui/lib/src/
- [ ] T067 [P] Keyboard navigation audit — verify all interactive elements (forms, buttons, tab controls, delete icons, pickers, dialogs) are reachable and activatable via Tab/Enter/Space without a pointer in my_apps/apps/sfinance/lib/ui/
- [ ] T068 [P] WCAG AA contrast audit — verify all text and UI controls meet 4.5:1 (normal text) and 3:1 (large text, UI components) contrast ratios against dark theme background in my_apps/packages/shared_ui/lib/src/theme/app_theme.dart
- [ ] T069 Verify no sensitive data (amounts, balances, category names) appears in Flutter logs, exception messages, or Drift error output; add redaction wrappers where needed in my_apps/apps/sfinance/lib/ and my_apps/packages/shared_services/lib/
- [ ] T070 Run full quickstart.md validation end-to-end: `melos bootstrap`, `build_runner build`, `flutter run -d windows` (or target platform), `melos run test` — all tests pass, app launches within 3 seconds, Resumen view is correct

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS all user stories**
- **Phase 3–9 (User Stories)**: All depend on Phase 2; stories proceed in priority order (single developer)
- **Phase 10 (Polish)**: Depends on all user stories complete

### User Story Dependencies

| Story | Depends on | Notes |
|-------|-----------|-------|
| US1 (P1) | Phase 2 | Independent — no story dependencies |
| US2 (P2) | Phase 2 | Independent — builds on RecurringTemplate infrastructure from Phase 2 |
| US3 (P3) | US2 | Extends expenseFormProvider + RecurringGenerationService introduced in US2 |
| US4 (P4) | US1 | Completes the Resumen view started in US1 |
| US5 (P5) | Phase 2, US1 | Independent chart view; KPI strip reuses kpiProvider from US1 |
| US6 (P6) | US1 | Entradas view; reuses TransactionRow from US1; adds delete |
| US7 (P7) | US2, US6 | Recurrentes tab; requires templates from US2 and Entradas shell from US6 |

### Within Each User Story

- Tests (where included) **MUST** be written and **confirmed failing** before implementation
- Models/providers before widgets
- Widgets composed from shared_ui components
- Story complete before moving to next priority

### Parallel Opportunities

- **Phase 1**: T002–T005 can all run in parallel (different package manifests)
- **Phase 2a**: T007, T008, T009 in parallel (different model files, after T006 completes)
- **Phase 2b**: T012, T013 in parallel (different table files); T017, T018 in parallel (different DAOs, after T015)
- **Phase 2d**: T024, T025 in parallel (different formatter files, after T023 green); T027, T028 in parallel (different widget files)
- **Phase 2e**: T032 in parallel with T033 (different files)
- **Phase 3**: T035 (test writing) can overlap with T036 (form provider) since they are different files
- **Phase 10**: T066, T067, T068 can run in parallel (different concerns)

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Run in parallel after T006 completes:
Task T007: Create Transaction model
Task T008: Create RecurringTemplate model
Task T009: Create InitialCapital model

# Run in parallel after T014 + T015 complete:
Task T017: Create TemplateDao
Task T018: Create InitialCapitalDao

# Run in parallel after T023 test is green:
Task T024: Implement DateFormatter  (independent file)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (critical — blocks everything)
3. Complete Phase 3: User Story 1 — Record a One-Off Expense
4. **STOP and VALIDATE**: Record an expense, verify it appears in Resumen, verify KPI updates
5. The app is deployable as a read/write expense tracker at this point

### Incremental Delivery

1. Phase 1 + 2 → Project scaffolded and building
2. + US1 → Expense tracking MVP — demo-ready
3. + US2 → Income tracking + salary recurring entries
4. + US3 → Subscription/financing recurring expenses
5. + US4 → Complete Resumen dashboard with bar chart
6. + US5 → Trend analysis view
7. + US6 → Full transaction history + delete
8. + US7 → Template management — full feature complete

---

## Notes

- `[P]` tasks operate on different files with no shared-state dependencies — safe to implement in the same pass
- `[Story]` label maps each task to a specific user story for traceability
- Financial logic tasks (period generator, KPI computations, chart aggregation, currency formatting) **must** have failing tests before implementation — this is a constitution requirement, not optional
- Soft-delete pattern for templates (isDeleted flag) is required to preserve FK integrity with generated Transaction rows
- Re-run `build_runner` after any change to Drift table definitions (T011–T014)
- Integer-cents arithmetic throughout — never store or compute with `double` for monetary values
- Commit generated `.g.dart` files from build_runner alongside the table definitions that produced them
