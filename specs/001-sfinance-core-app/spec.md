# Feature Specification: SFinance Core Application

**Feature Branch**: `001-sfinance-core-app`  
**Created**: 2026-04-06  
**Status**: Draft  
**Input**: User description: "Build SFinance, a personal finance desktop application. The app helps a single user track income and expenses, understand spending patterns over time, and manage recurring subscriptions and financing — all with data stored entirely on-device."

## Clarifications

### Session 2026-04-06

- Q: Can the user edit or delete existing individual transaction entries? → A: Transactions are read-only; individual entries can only be deleted (no editing).
- Q: Can the user cancel/edit/delete a recurring template (e.g., a subscription that ended)? → A: Templates can be deleted; deletion stops future generation but all past generated entries are kept. No editing of templates after creation.
- Q: Does the recurring entry form include a start date field the user can set to a past date, or does the start date always default to today? → A: Start date always defaults to today; no user control; no back-dating. On first save, exactly one entry is generated (for today's period). Future entries are generated on subsequent app launches as each period arrives.
- Q: Do delete operations (transactions or templates) require a confirmation step? → A: Yes — a confirmation dialog is required before deleting a transaction or a template. No undo mechanism.
- Q: Where does the user view and manage (delete) recurring templates? → A: The Entradas view contains a toggle between "Transacciones" (transaction list) and "Recurrentes" (active recurring templates list); users delete a template from the Recurrentes list.
- Q: From which view(s) can the user delete an individual transaction? → A: Only from the Entradas → Transacciones tab. The Resumen "Transacciones Recientes" list is read-only (no delete affordance).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record a One-Off Expense (Priority: P1)

The user wants to log a one-time expense — for example, buying a laptop or dining out. They open the "+ Gasto" modal, fill in the name, amount, optional description, and select a category (Producto, Servicio, or Suministro variable). No recurrence fields appear. They confirm and the transaction is immediately visible in the Recent Transactions list on the Resumen view.

**Why this priority**: The ability to record a basic expense is the most fundamental action in any personal finance app. Without it, no other feature delivers value.

**Independent Test**: Can be fully tested by recording a one-off expense and verifying it appears in the Resumen "Transacciones Recientes" list with the correct name, category, date, and signed amount.

**Acceptance Scenarios**:

1. **Given** the app is open on Resumen, **When** the user clicks "+ Gasto" and fills in Nombre="Cena", Monto=25.50, Categoría=Servicio and confirms, **Then** the expense appears in "Transacciones Recientes" as "−€25,50" in red with the Servicio category label and today's date.
2. **Given** the expense form is open with Categoría=Producto, **When** the user inspects the form, **Then** no recurrence fields (Periodicidad, Fecha de fin) are visible.
3. **Given** a new expense is submitted with Monto left blank, **When** the user attempts to confirm, **Then** the form prevents submission and indicates the Monto field is required.
4. **Given** a new expense is submitted with a valid Monto, **When** the expense is saved, **Then** the monthly "Gastos" KPI card on Resumen increases by the submitted amount.

---

### User Story 2 - Record Income (Priority: P2)

The user wants to log a source of income. For a one-off sale or freelance service, they fill in name, amount, and select Venta or Servicio — no extra fields appear. For a salary, they additionally specify 12 or 14 pagas and, if 14, pick the two extra-payment months.

**Why this priority**: Income tracking alongside expenses is essential for computing the balance. Recording salary with recurrence also exercises the recurring-entry generation logic.

**Independent Test**: Can be fully tested by recording a Salario income entry with 14 pagas and verifying that individual monthly entries (including two extra-payment months) appear in the transaction list.

**Acceptance Scenarios**:

1. **Given** the user opens "+ Ingreso" and selects Categoría=Venta, **When** inspecting the form, **Then** only Nombre, Monto, Descripción, and Categoría fields are visible.
2. **Given** the user selects Categoría=Salario and Número de pagas=14, **When** inspecting the form, **Then** two month pickers appear: "Primera paga extra" and "Segunda paga extra".
3. **Given** a Salario with 14 pagas is saved with extra payments in July and December, **When** those months have passed, **Then** the transaction list contains one additional entry each for July and December equal to the regular monthly amount.
4. **Given** a Salario income is recorded, **When** the current month is reached, **Then** the monthly "Ingresos" KPI card reflects the salary amount for that month.

---

### User Story 3 - Record a Recurring Subscription or Financing Expense (Priority: P3)

The user wants to log a subscription (e.g. Claude Pro) or a financing plan (e.g. car instalments). They select Suscripción or Financiación and the form reveals Periodicidad (Mensual/Anual) and Fecha de fin. The start date is always today; one transaction entry is generated immediately on save, and subsequent entries are generated on future app launches as each period arrives.

**Why this priority**: Recurring entries are a key differentiator of this app. Subscriptions and financing are common in personal finance and require automatic generation logic.

**Independent Test**: Can be fully tested by recording a monthly subscription today and verifying that one transaction entry is generated immediately, with a second entry appearing the next time the app is launched after the following month's date has arrived.

**Acceptance Scenarios**:

1. **Given** the user selects Categoría=Suscripción in the expense form, **When** inspecting the form, **Then** Periodicidad and Fecha de fin fields appear; no start date field is present (start date is always today).
2. **Given** Periodicidad=Mensual, **When** the user views the Fecha de fin picker, **Then** it allows selecting a month within a year (e.g. "Octubre de 2027").
3. **Given** Periodicidad=Anual, **When** the user views the Fecha de fin picker, **Then** it allows selecting a year only (e.g. "2029").
4. **Given** a Suscripción is saved today with monthly periodicity, **When** the entry is confirmed, **Then** exactly one transaction entry is generated for today's period.
5. **Given** a Suscripción has a future occurrence, **When** the app launches on or after that occurrence date, **Then** a new transaction entry for that occurrence is generated automatically.
6. **Given** a recurring expense reaches its Fecha de fin, **When** the date after the end date arrives, **Then** no further entries are generated.

---

### User Story 4 - View the Resumen Dashboard (Priority: P4)

The user opens the app and immediately sees their financial health at a glance: current month income and expenses as KPI cards, an all-time balance, a grouped bar chart of the last several months, and a list of recent transactions.

**Why this priority**: The Resumen view is the default landing screen. It provides the primary at-a-glance summary the user sees every time they open the app.

**Independent Test**: Can be fully tested by recording a mix of income and expense entries and verifying that KPI cards, the bar chart, and the recent transactions list all display accurate, correctly formatted values.

**Acceptance Scenarios**:

1. **Given** the app is launched, **When** the Resumen view loads, **Then** three KPI cards are visible: Ingresos (green), Gastos (red), and Balance (accent color).
2. **Given** transactions exist for the current month, **When** viewing the Ingresos and Gastos KPI cards, **Then** they show only the current calendar month totals, formatted as "+€X,XX" and "−€X,XX" respectively.
3. **Given** transactions exist across multiple months, **When** viewing the "Resumen Mensual" chart, **Then** a grouped bar chart shows income (green) vs. expenses (red) for each of the recent months.
4. **Given** transactions exist, **When** viewing "Transacciones Recientes", **Then** each row shows a colored icon, transaction name, category and date, and signed amount; the list is ordered most recent first.
5. **Given** no transactions have been recorded yet, **When** viewing the Balance KPI card, **Then** it shows an editable field for entering initial capital; once entered and confirmed, the balance reflects that initial capital amount.
6. **Given** initial capital was set but no transactions saved, **When** the first transaction is saved, **Then** the initial capital is discarded and the balance is computed solely from transactions.

---

### User Story 5 - Analyse Trends Over Time (Priority: P5)

The user navigates to the Análisis view to see how their balance, expenses, and income have evolved over a chosen period. Three independent line charts give a visual breakdown with selectable time ranges.

**Why this priority**: Trend analysis is a key reason users maintain a personal finance tracker over time. It turns raw transaction data into insight.

**Independent Test**: Can be fully tested by switching to the Análisis view, selecting different time ranges for each chart, and verifying the lines update to reflect the correct data for the chosen period.

**Acceptance Scenarios**:

1. **Given** the user navigates to Análisis, **When** the view loads, **Then** the same KPI strip as Resumen is visible at the top.
2. **Given** the Análisis view is open, **When** viewing the charts, **Then** three stacked line charts appear: "Evolución del Balance" (blue), "Evolución de Gastos" (red), and "Evolución de Ingresos" (green).
3. **Given** each chart has a time range selector, **When** the user selects "Último año" for the Balance chart and "Últimos 7 días" for the Gastos chart, **Then** each chart updates independently to show data for its own selected range.
4. **Given** the default time range is "Últimos 7 días", **When** the Análisis view first loads, **Then** all three charts default to showing the last 7 days.

---

### User Story 6 - Browse All Transactions (Priority: P6)

The user navigates to the Entradas view to see all transactions in a filterable list, sorted most recent first, with a time range selector to narrow the view.

**Why this priority**: The complete transaction history is needed for reviewing past entries, auditing the data, and verifying automatic recurring-entry generation.

**Independent Test**: Can be fully tested by navigating to the Entradas view, changing the time range filter, and verifying the list updates to show only transactions within the chosen period.

**Acceptance Scenarios**:

1. **Given** the user opens the Entradas view, **When** the view loads, **Then** it defaults to "Últimos 7 días" and shows all transactions within that range, most recent first.
2. **Given** the user selects "Desde origen" in the time range selector, **When** the list updates, **Then** all transactions ever recorded are shown.
3. **Given** a transaction was recorded 2 months ago, **When** the user selects "Últimos 7 días", **Then** that transaction is not visible in the list.
4. **Given** any transaction row is visible, **When** inspecting it, **Then** it shows a colored icon, name, category + date, and signed amount — identical row layout to Resumen's recent transactions list.
5. **Given** a transaction row is visible in the Transacciones tab, **When** the user initiates deletion and confirms the dialog, **Then** the transaction is permanently removed and the KPI values update to reflect the deletion.
6. **Given** a transaction is visible in the Resumen "Transacciones Recientes" list, **When** the user inspects the row, **Then** no delete affordance is present.

---

### User Story 7 - Manage Recurring Templates (Priority: P7)

The user navigates to the Entradas view and switches to the "Recurrentes" tab to see all active recurring templates (subscriptions, financing plans, salary). From this list they can delete a template — for example, to cancel a subscription that is no longer active — after confirming the action.

**Why this priority**: Without a way to view and delete templates, the user has no means to clean up cancelled recurring entries. P7 because viewing and recording transactions is higher value, but template management is necessary for long-term data hygiene.

**Independent Test**: Can be fully tested by creating a recurring template, navigating to Entradas → Recurrentes, verifying it appears in the list, deleting it with confirmation, and verifying it no longer appears and generates no further entries.

**Acceptance Scenarios**:

1. **Given** the user is on the Entradas view, **When** they switch to the "Recurrentes" tab, **Then** a list of all active recurring templates is shown, each row displaying the template name, category, periodicity, and end date.
2. **Given** the Recurrentes list is shown and a template exists, **When** the user initiates deletion of a template, **Then** a confirmation dialog appears before any deletion is carried out.
3. **Given** the confirmation dialog is shown, **When** the user confirms the deletion, **Then** the template is removed from the list and no further transaction entries will be generated from it.
4. **Given** a template has been deleted, **When** the user switches to the "Transacciones" tab, **Then** all previously generated transaction entries from that template remain visible and unchanged.

---

### Edge Cases

- What happens when there are no transactions yet? → All KPI values display as €0,00; charts show empty state; Resumen shows the editable initial capital Balance field.
- What happens when a recurring entry's end date is in the past and all occurrences have already been generated? → No new entries are generated; existing entries remain.
- What happens when a 14-paga salary selects the same month for both extra payments? → The form must prevent this; the two month pickers must enforce distinct selections.
- What happens when Monto is entered as zero? → The form must reject zero amounts; amounts must be strictly positive.
- How does the system handle a Financiación end date set in the past (before today)? → Since start date is always today and end date must be provided, the system should prevent saving a template with an end date earlier than today; the Fecha de fin picker MUST only allow future dates.
- What happens when the Balance KPI would be negative (lifetime expenses exceed income)? → The balance displays with an explicit "−" sign in red; the negative state is never hidden.
- What happens when the app is launched for the first time with no data? → Resumen shows zero KPIs and an empty chart; the Balance card is editable for initial capital.
- What happens when the user deletes a transaction that was auto-generated from a recurring template? → The individual entry is deleted; the template is unaffected and will continue generating future entries on subsequent app launches.
- What happens when the user attempts to edit a saved transaction? → No editing affordance is provided; transactions are immutable after creation.
- What happens when the user cancels the delete confirmation dialog? → The deletion is aborted; the transaction or template remains unchanged.
- What happens when the user deletes a recurring template? → The template is removed; no future entries will be generated from it on subsequent app launches. All previously generated transaction entries for that template remain unchanged in the transaction list.

## Requirements *(mandatory)*

### Functional Requirements

#### Transaction Entry

- **FR-001**: The system MUST provide a "+ Gasto" modal for recording expense transactions with fields: Nombre (required), Monto (required, positive numeric), Descripción (optional), and Categoría (required, dropdown of predefined expense categories).
- **FR-002**: The system MUST provide a "+ Ingreso" modal for recording income transactions with fields: Nombre (required), Monto (required, positive numeric), Descripción (optional), and Categoría (required, dropdown of predefined income categories).
- **FR-003**: The expense form MUST show Periodicidad (Mensual/Anual) and Fecha de fin fields if and only if Categoría is Suscripción or Financiación; these fields MUST be hidden for all other expense categories.
- **FR-004**: The income form MUST show a "Número de pagas" dropdown (12 pagas / 14 pagas) if and only if Categoría is Salario.
- **FR-005**: When "14 pagas" is selected on the Salario income form, the system MUST show two independent month pickers labeled "Primera paga extra" and "Segunda paga extra".
- **FR-006**: The two extra-payment month pickers for 14-paga salaries MUST enforce distinct month selections; the same month cannot be selected for both pickers.
- **FR-007**: The Fecha de fin picker for Periodicidad=Mensual MUST allow selecting a month within a year (e.g. "Octubre de 2027"). The picker for Periodicidad=Anual MUST allow selecting a year only (e.g. "2029").
- **FR-008**: Fecha de fin MUST always be required when Periodicidad is specified; open-ended recurrences are not permitted. The Fecha de fin picker MUST only allow future dates (today or later) since the start date is always today.
- **FR-009**: Monto MUST be stored in integer cents; the form MUST reject zero or negative amounts.
- **FR-009b**: Individual transaction entries are read-only after creation; the user MUST NOT be able to edit any field of a saved transaction. Deletion of individual entries MUST be supported exclusively from the Entradas → Transacciones tab and MUST require an explicit confirmation dialog before the deletion is carried out. The Resumen "Transacciones Recientes" list MUST NOT expose a delete affordance.

#### Category System

- **FR-010**: The system MUST provide exactly the following predefined expense categories and no others: Producto, Servicio, Suscripción, Suministro variable, Financiación.
- **FR-011**: The system MUST provide exactly the following predefined income categories and no others: Salario, Venta, Servicio.
- **FR-012**: Users MUST NOT be able to create, edit, or delete categories.
- **FR-012b**: Recurring templates (Suscripción, Financiación, Salario) are immutable after creation; the user MUST NOT be able to edit any field of a saved template. Deletion of a template MUST be supported, MUST require an explicit confirmation dialog before the deletion is carried out, and MUST permanently stop future entry generation for that template without affecting any already-generated transaction entries.

#### Recurring Entry Generation

- **FR-013**: When a Suscripción, Financiación, or Salario entry is saved, the start date is always today (no user-configurable back-dating). The system MUST immediately generate exactly one transaction entry for today's period. Subsequent entries are generated on future app launches as each period arrives.
- **FR-014**: Future occurrences MUST NOT be pre-generated at save time; they MUST be created on app launch when their date has arrived.
- **FR-015**: Generated recurring entries MUST appear in transaction lists and charts identically to one-off transactions, with no visual distinction.
- **FR-016**: For a 14-paga salary, extra-payment months MUST generate one additional transaction entry of the same monthly amount, in addition to the regular monthly entry for those months.

#### Resumen View

- **FR-017**: The Resumen view (default on launch) MUST display a KPI strip with three cards: Ingresos (current month total income, green), Gastos (current month total expenses, red), and Balance (all-time income minus all-time expenses, accent color).
- **FR-018**: The Balance KPI card MUST be editable before any transaction is recorded; the user can enter an initial capital amount that is added to the computed balance and persisted.
- **FR-019**: The initial capital MUST be automatically discarded the moment the first transaction is saved; it cannot be restored or edited after that point.
- **FR-020**: The Resumen view MUST display a "Resumen Mensual" grouped bar chart showing income (green) vs. expenses (red) per month for the most recent months.
- **FR-021**: The Resumen view MUST display a "Transacciones Recientes" list showing the most recent transactions, each row with a colored icon, name, category + date, and signed amount, ordered most recent first.

#### Análisis View

- **FR-022**: The Análisis view MUST display the same KPI strip as Resumen.
- **FR-023**: The Análisis view MUST display three stacked line charts: "Evolución del Balance" (blue), "Evolución de Gastos" (red), "Evolución de Ingresos" (green).
- **FR-024**: Each chart MUST have an independent time range selector with options: Últimos 7 días (default), Último mes, Últimos 3 meses, Último año, Desde origen.
- **FR-025**: Changing a time range selector MUST update only the chart it belongs to, without affecting the other charts.

#### Entradas View

- **FR-026**: The Entradas view MUST contain a toggle between two tabs: "Transacciones" (the transaction list) and "Recurrentes" (the active recurring templates list). The default tab on load MUST be "Transacciones".
- **FR-026b**: The "Transacciones" tab MUST display all transactions matching the selected time range, ordered most recent first, with the same row layout as the Resumen recent transactions list.
- **FR-026c**: The "Recurrentes" tab MUST display all active recurring templates, each row showing the template name, category, periodicity, and end date. Each row MUST provide a delete affordance that triggers a confirmation dialog before deletion.
- **FR-027**: The Entradas view MUST provide a time range filter (applied to the Transacciones tab only) with the same five options as the Análisis charts; default MUST be "Últimos 7 días".

#### Financial Accuracy

- **FR-028**: All monetary values MUST be stored and calculated in integer cents to avoid floating-point errors.
- **FR-029**: Currency symbol MUST always be €; formatting MUST be locale-aware (e.g. thousands/decimal separators).
- **FR-030**: Positive amounts (income) MUST always display as "+€X,XX" in green; negative amounts (expenses) MUST always display as "−€X,XX" in red. Both sign and color MUST be used simultaneously; color alone is never sufficient.
- **FR-031**: The Balance KPI MUST always be computed as lifetime income minus lifetime expenses (plus initial capital if no transactions exist); it MUST NOT be stored as a cached derived value.
- **FR-032**: The Ingresos and Gastos KPI cards MUST reflect the current calendar month only.
- **FR-033**: The Balance KPI MUST reflect the all-time total (desde origen).

#### Data & Privacy

- **FR-034**: All data MUST be stored on-device only; no network calls, no sync, no telemetry, no analytics of any kind are permitted.
- **FR-035**: The application MUST function fully offline at all times.
- **FR-036**: Sensitive values (balances, amounts, category names) MUST NOT appear in any log output or error messages.

#### UX & Accessibility

- **FR-037**: The application MUST use a dark theme throughout, matching the provided mockups.
- **FR-038**: All interactive elements MUST be keyboard-navigable.
- **FR-039**: All text and interactive elements MUST meet WCAG AA minimum color contrast.
- **FR-040**: All actions MUST have a touch-compatible equivalent; no hover-only or right-click-only primary affordances.
- **FR-041**: The application MUST provide three main views accessible via a top navigation bar: Resumen, Análisis, Entradas.

### Key Entities

- **Transaction**: Represents a single financial event. Attributes: unique identifier, name, amount (integer cents), description (optional), category, date, source (one-off or generated from a recurring template).
- **RecurringTemplate**: Represents the definition of a recurring income or expense. Attributes: name, amount (integer cents), category, periodicity (monthly/annual), start date (always the save date — system-set, not user-configurable), end date (user-selected future date). For 14-paga salary: also stores the two extra-payment months. Immutable after creation; can be deleted to stop future generation. Acts as the blueprint from which individual Transaction entries are generated.
- **InitialCapital**: A single persisted value (integer cents) representing the user's starting balance before any transactions are recorded. Automatically cleared when the first transaction is saved; cannot be modified after that point.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The user can record any transaction (one-off or recurring) in under 60 seconds from opening the entry modal to seeing it confirmed in the transaction list.
- **SC-002**: All KPI values (Ingresos, Gastos, Balance) always reflect the correct calculated totals; no stale or cached values are ever displayed.
- **SC-003**: Every displayed monetary amount includes an explicit currency symbol (€), locale-formatted separators, and an explicit sign (+ or −); no amount is displayed without all three elements.
- **SC-004**: On first save, a recurring entry generates exactly one transaction entry (for today's period). On each subsequent app launch, exactly one new entry is created per due period, with zero duplicate entries ever created for already-generated periods.
- **SC-005**: The application launches and displays the Resumen view with correct data within 3 seconds on the target desktop hardware, regardless of transaction volume.
- **SC-006**: All interactive elements in the application can be reached and activated using only keyboard input, with no mouse or pointer device required.
- **SC-007**: All text elements and interactive controls pass WCAG AA contrast ratio validation (minimum 4.5:1 for normal text, 3:1 for large text and UI components).
- **SC-008**: The application operates fully without any network connectivity; all features remain functional while offline.
- **SC-009**: No financial data (amounts, balances, category names) appears in any log output or error display visible to the user or captured in the system log.

## Assumptions

- The app targets a single user; there are no multi-user, sharing, or export features in this version.
- The currency is fixed to € (Euro); there is no multi-currency support in this version.
- The app targets desktop (Windows/macOS/Linux) as primary platform, with touch-compatibility built in as preparation for a planned Android version.
- The start date for recurring entries (Suscripción, Financiación, Salario) is always the date the entry is saved; the form contains no start date field and back-dating is not supported.
- The "most recent months" shown in the Resumen Mensual bar chart is the last 6 months (current month + 5 prior months), consistent with the mockups.
- The "Transacciones Recientes" list on Resumen shows the most recent 10 transactions; older entries are accessible via the Entradas view.
- Locale formatting (decimal separator, thousands separator) follows the device/system locale setting, since the app is local-only and targets a Spanish-speaking user.
- The mockups in the `mockups/` folder are the authoritative visual reference for layout, colors, spacing, and component styles; any detail not specified in this document defers to the mockups.
- Data persistence uses local on-device storage appropriate for the target platform; the specific storage mechanism is a technical implementation decision not constrained by this spec.
