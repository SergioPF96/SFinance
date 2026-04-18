# Feature Specification: Open-Ended Subscriptions

**Feature Branch**: `007-open-ended-subscriptions`  
**Created**: 2026-04-18  
**Status**: Draft  

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create open-ended subscription (Priority: P1)

A user wants to register a Netflix subscription that runs indefinitely — they do not know when they will cancel. When filling the "Nuevo Gasto" form with Categoría=Suscripción and Periodicidad=Mensual, a "Sin fecha de fin" toggle appears. The user activates it, selects payDay=1, and submits. The subscription is saved with no end date and begins generating monthly entries every first of the month on each app launch, until the user manually deletes the template.

**Why this priority**: This is the core missing feature reported by the user. Without it, every subscription requires a mandatory end date that the user may not know, forcing workarounds.

**Independent Test**: Can be fully tested by filling the expense form with Suscripción + "Sin fecha de fin" active, verifying the template is saved with endDate=null, and confirming that RecurringGenerationService generates entries correctly.

**Acceptance Scenarios**:

1. **Given** the expense form is open with Categoría=Suscripción and Periodicidad=Mensual, **When** the user activates "Sin fecha de fin", **Then** the endDate selector disappears and the form can be submitted without an end date.
2. **Given** a submitted open-ended subscription form, **When** submit() completes without error, **Then** a RecurringTemplate is persisted with endDate=null.
3. **Given** a RecurringTemplate with endDate=null, **When** RecurringGenerationService runs, **Then** it generates entries up to today with no end cap.
4. **Given** a RecurringTemplate with endDate=null, **When** the FR-006 save-time validation runs, **Then** the validation is skipped (no rejection).

---

### User Story 2 - Toggle off restores empty endDate field (Priority: P1)

A user activates "Sin fecha de fin" and then changes their mind and deactivates it. The endDate field must reappear empty — no previously selected date should be remembered.

**Why this priority**: Correct toggle behavior already specified in spec 001 edge cases. Incorrect behavior here would silently allow submission with a null endDate that was intended as required.

**Independent Test**: Unit test: call `setOpenEnded(true)` then `setOpenEnded(false)` on the form notifier and verify `fechaFin` is null.

**Acceptance Scenarios**:

1. **Given** the user activates "Sin fecha de fin" (fechaFin becomes null), **When** the user deactivates the toggle, **Then** fechaFin is null and the endDate selector reappears empty.
2. **Given** the user had previously selected fechaFin=2027-12-31, **When** the user activates then deactivates "Sin fecha de fin", **Then** fechaFin is null (the previously selected date is NOT restored).

---

### User Story 3 - Recurrentes list shows "Sin fecha de fin" (Priority: P2)

When the user views the list of recurring templates, open-ended subscriptions display "Sin fecha de fin" in place of a formatted end date.

**Why this priority**: Lower than saving correctly, but a null date that crashes or renders blank is a regression.

**Independent Test**: Render a template with endDate=null in the Recurrentes list and verify "Sin fecha de fin" is displayed.

**Acceptance Scenarios**:

1. **Given** a RecurringTemplate with endDate=null, **When** the Recurrentes list renders it, **Then** the end date displays "Sin fecha de fin".
2. **Given** a RecurringTemplate with a real endDate, **When** the Recurrentes list renders it, **Then** the end date is displayed as a formatted date (existing behavior unchanged).

---

### Edge Cases

- What happens if the user activates "Sin fecha de fin" and then deactivates it? → fechaFin is cleared to null; the endDate selector reappears empty and must be filled before submitting.
- Does "Sin fecha de fin" apply to Financiación? → No. Financiación always requires endDate. The toggle only appears for Suscripción.
- Does "Sin fecha de fin" apply when Periodicidad=Anual? → Yes — the toggle is tied to Categoría=Suscripción, not to Periodicidad.
- What happens to existing templates after the schema migration? → The migration makes endDate nullable; existing rows keep their values unchanged.
- Does FR-006 (first occurrence > endDate rejection) fire for open-ended subscriptions? → No. When endDate is null, FR-006 validation is skipped entirely.
- What if RecurringGenerationService receives a template with endDate=null? → It treats it as unbounded and generates all due entries up to today.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When Categoría=Suscripción is selected and Periodicidad is set, a "Sin fecha de fin" toggle MUST appear in the expense form before the endDate selector.
- **FR-002**: When the "Sin fecha de fin" toggle is active, the endDate selector MUST be hidden and no endDate is required for submission.
- **FR-003**: When the "Sin fecha de fin" toggle is inactive (default), the endDate selector MUST be shown and behaves as currently (required, only future dates allowed).
- **FR-004**: The expense form state MUST include an `openEnded` boolean field. When `openEnded` is true, `fechaFin` is null.
- **FR-005**: `ExpenseFormNotifier.submit()` MUST persist a RecurringTemplate with `endDate = null` when `openEnded` is true.
- **FR-006**: The Drift database schema for `recurring_templates` MUST be updated so that `endDate` is nullable, with a schema version migration.
- **FR-007**: `PeriodGenerator.computeDueKeys()` MUST handle `endDate = null` by using `today` as the sole upper cap.
- **FR-008**: `RecurringGenerationService.generateForTemplate()` MUST handle templates with `endDate = null`.
- **FR-009**: The FR-006 save-time validation in `ExpenseFormNotifier.submit()` MUST be skipped when `openEnded` is true (fechaFin == null).
- **FR-010**: The Recurrentes list widget MUST display "Sin fecha de fin" for templates with `endDate = null`.

### Key Entities

- **RecurringTemplate**: `endDate` changes from `DateTime` (non-null) to `DateTime?` (nullable). All other fields unchanged.
- **ExpenseFormState**: Add `openEnded` boolean field (default false). When set to true, `fechaFin` is cleared to null.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a Suscripción without an end date; template persisted with endDate=null and no error returned.
- **SC-002**: RecurringGenerationService generates entries for open-ended templates without crashing or early-capping.
- **SC-003**: Toggling "Sin fecha de fin" on then off results in fechaFin=null (verified by unit test).
- **SC-004**: Existing templates with endDate set continue to behave identically after schema migration.
- **SC-005**: The Recurrentes list renders "Sin fecha de fin" for open-ended templates without crashing.

## Assumptions

- "Sin fecha de fin" toggle is exclusive to Categoría=Suscripción (not Financiación, not income).
- Periodicidad=Anual + open-ended is allowed; no constraint prevents it.
- The schema migration is additive (ALTER COLUMN to nullable); no data loss.
- `PeriodGenerator` null-endDate path must be covered by unit tests before implementation (Constitution Principle IV).
- Income forms (Salario) are not affected — they use a system-set far-future endDate.
- The feature does not change paymentDay deferral logic (spec 006).
