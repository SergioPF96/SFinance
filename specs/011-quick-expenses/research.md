# Phase 0: Research — Quick Expenses

This document records every architectural and dependency decision made before
Phase 1 design. Each entry has a Decision, a Rationale, and Alternatives
considered.

## R-1: File picker package

**Decision**: Add `file_picker ^8.x` to `apps/sfinance/pubspec.yaml`.

**Rationale**:
- The "+Gasto" form and the QuickExpense edit dialog need an OS-native file
  dialog to let the user pick an image. No existing dependency in the workspace
  exposes this capability.
- `file_picker` supports Windows and Android (the two target platforms) from a
  single Dart API and accepts an extension allow-list. With
  `FileType.custom` + `allowedExtensions: ['jpg','jpeg','png','webp','gif']`
  the picker shows only image files in the system dialog.
- It is widely used (>2M monthly pub downloads at the time of writing),
  actively maintained, and uses platform channels — no Skia or hardware quirks.

**Alternatives considered**:
- `image_picker`: oriented at mobile camera/gallery flows; on desktop it still
  delegates to a file dialog but with a more constrained API (no extension
  allow-list on Windows). Rejected because the desktop UX is what we ship
  first.
- Writing custom Win32 + Android channel code: duplicates exactly what
  `file_picker` already encapsulates. Rejected on Principle VII (Simplicity).
- `cross_file` / `desktop_drop`: solve different problems (passing files
  between isolates / drag-and-drop). Rejected because the spec asks for an
  explicit picker affordance.

**Where the dependency lives**: `apps/sfinance/pubspec.yaml` only. The picker
is invoked from app-layer UI code; `shared_services` receives the resulting
file path and owns the copy/delete behavior. This keeps `shared_services` free
of UI dependencies and aligned with Principle III (UI/Business Logic
Separation).

## R-2: Image storage location and naming

**Decision**: Internal images live in
`getApplicationDocumentsDirectory()/quick_expense_images/`. Each image is
renamed to `<quickExpenseId>_<timestamp>.<ext>` on copy.

**Rationale**:
- `getApplicationDocumentsDirectory()` is already used by `app_database.dart`
  for `sfinance.sqlite`, so re-using it keeps all on-disk state under one
  predictable root.
- Encoding the QuickExpense `id` and a copy timestamp in the filename gives:
  (a) collision-free names without needing a UUID dependency, (b) a way to
  detect leaked image files during a future cleanup, and (c) idempotent
  replacement (the new filename is different from the old one, so the copy
  succeeds before the old file is deleted, avoiding partial-state windows).
- The original file extension is preserved so OS thumbnailers and Flutter's
  default image decoder can route on extension when needed.

**Alternatives considered**:
- Storing images inside the SQLite blob column: simpler to back up but worse
  for performance (loading a list of 50 cards reads up to 50 MB into memory),
  and harder to inspect during development. Rejected.
- Using a UUID instead of `<id>_<timestamp>`: requires adding `uuid` as a new
  dependency. Rejected on Principle VII.
- Hashing image content (CAS-style): de-duplicates identical images but adds
  complexity and a hashing dependency. Rejected — not justified for
  ~dozens of cards.

## R-3: Image copy lifecycle (the trickiest part)

**Decision**: Two-phase save that respects spec FR-006 ("If the copy operation
fails, the save MUST be aborted, an error message MUST be shown, and a retry
option MUST be offered."):

1. **Pick** — user selects a file via `file_picker`. Path is held only in
   form state, not in the DB.
2. **Save** — `QuickExpenseEditFormNotifier.save()` performs:
   a. Copy picked file to internal directory under
      `<id-placeholder>_<timestamp>.<ext>` (the row hasn't been inserted yet,
      so we use a temp suffix and rename after insert), OR for **edits**, copy
      under `<id>_<timestamp>.<ext>` directly.
   b. If copy throws, surface a `SaveError.imageCopyFailed` to the UI; the UI
      shows an error banner with a "Reintentar" button. The DB row is **not**
      written.
   c. If copy succeeds, insert/update the DB row with the new internal path.
      For edits where the image was replaced, the **old** internal file is
      deleted only after the DB row update commits successfully (best-effort
      cleanup; orphaned old files are recoverable by the next cleanup pass —
      see R-7).
   d. For **deletes**, the DB row is removed first; the image file is deleted
      after. If file delete fails, the DB no longer references it, so the file
      is leaked — same recovery story as R-7.

**Rationale**:
- Insert-then-copy would require UPDATE-after-insert to write the path, and a
  copy failure mid-flight would leave an orphan row. Copy-then-insert is
  cleaner.
- For **edits**, the insert is replaced by an update; we still copy first,
  then update, then delete the old file.
- "Best-effort" old-file deletion (rather than wrapping copy+delete in a
  transaction) is acceptable because the DB is the source of truth: a leaked
  file with no DB reference is wasted disk space, never broken UI.

**Alternatives considered**:
- Wrapping copy+insert in a Drift transaction: Drift transactions don't span
  filesystem operations. Rejected.
- Persisting the original picked path and copying lazily on first display:
  violates the spec ("the original file path MUST NOT be retained or
  referenced after the copy"). Rejected.

## R-4: DAO pattern — hard delete vs. soft delete

**Decision**: Hard delete (`DELETE FROM quick_expenses WHERE id = ?`).

**Rationale**: A QuickExpense is a UI shortcut, not financial history. Unlike
`recurring_templates` (which use soft delete to preserve generated transaction
attribution per spec 007), deleting a quick expense has no downstream
implications — no transactions reference it, no analytics depend on it. The
simpler hard-delete API is appropriate.

**Alternatives considered**:
- Soft delete: would clutter the table with abandoned shortcuts forever.
  Rejected on Principle VII.

## R-5: Schema migration v3 → v4

**Decision**: Additive migration. In `AppDatabase.migration.onUpgrade`, add a
`from < 4` block that creates the `quick_expenses` table. No existing table is
touched.

**Rationale**:
- Principle I forbids breaking changes to package public APIs. Adding a new
  table is additive and does not affect any existing query, model, or DAO.
- Drift generates `m.createTable(quickExpenses)` automatically; the migration
  block invokes it for users on schemaVersion 3.

**Alternatives considered**:
- Bumping major version of `shared_services`: would propagate to all consumers
  unnecessarily. Rejected.

## R-6: Tab restructuring of EntradasView (architectural)

**Decision**: Convert `EntradasView` from its current single-list layout into a
`TabBar` + `TabBarView` with three tabs:
1. **Transacciones** — current Entradas list (time-range and category filters)
2. **Recurrentes** — content currently at `/recurrentes/recurrentes_view.dart`
3. **Frecuentes** — new (this feature)

Drop the top-level "Recurrentes" entry from `AppShell` and the
`/recurrentes` route from `app_router.dart`. The four top-level nav tabs
become: Resumen, Análisis, **Entradas**, (no Recurrentes).

**Rationale**:
- Spec FR-007 explicitly states: "The Entradas view MUST include a 'Frecuentes'
  tab as the last tab, after the existing 'Transacciones' and 'Recurrentes'
  tabs." The only way to satisfy that wording is to put all three under
  Entradas.
- Keeping a duplicate Recurrentes top-level nav would (a) be redundant, (b)
  break the user's mental model of "Entradas is where you manage entries,
  templates, and shortcuts", and (c) leave the spec partially unsatisfied.
- The refactor is mechanical: `RecurrentesView` widget is moved verbatim
  into `tabs/recurrentes_tab.dart`; the only changes are imports and
  potentially removing its outer Scaffold (TabBarView provides the body).

**Alternatives considered**:
- Add Frecuentes as a 5th top-level nav: contradicts the spec wording.
  Rejected.
- Add Frecuentes as the only inner tab in Entradas, leaving Recurrentes as a
  top-level nav: closer to the current structure but still contradicts the
  spec ("alongside Transacciones and Recurrentes"). Rejected.

**Risk to existing tests**: `recurrentes_view_test.dart` (if any) needs its
imports updated. Search confirms no other code imports `RecurrentesView`
externally besides the router.

## R-7: Orphaned image cleanup (deferred, but documented)

**Decision**: No proactive cleanup task is implemented in this feature.
Orphaned files (the rare case of a successful image copy followed by a failed
DB write, or a successful DB delete followed by a failed file delete) are
considered a tolerable and rare failure mode for a single-user desktop app.

A future maintenance task can scan `quick_expense_images/` and delete files
whose `<id>_*.ext` prefix doesn't match any row. Documented here so that
future me knows where the orphans come from and how to clean them up.

**Rationale**: Premature optimization (Principle VII). The expected failure
rate on a personal computer with adequate disk is essentially zero, and the
worst-case disk leak is bounded by the number of failed saves × image size —
trivially small.

## R-8: Card-row layout sizing

**Decision**: Each card is 64 × 64 logical pixels with 8 px padding between
cards, scrolled horizontally inside a `SizedBox(height: 80)` at the top of the
expense form. The image fills the card with `BoxFit.cover` and a 4 px border
radius. The generic icon is `Icons.bolt_outlined` rendered at 32 px in
`AppColors.onBackgroundMuted`.

**Rationale**:
- 64 px × 64 px is recognizable for product/service photos at desktop
  viewing distances and matches the "compact" wording in the spec.
- `BoxFit.cover` maximizes recognizability per spec SC-005 ("neither too
  small to distinguish nor cropped in a way that obscures the subject") at
  the cost of rare edge crops on extreme aspect-ratios — acceptable for
  user-supplied product photos.
- `bolt_outlined` is a neutral "shortcut" symbol that is already used
  elsewhere in Material design's quick-action language.

**Alternatives considered**:
- Larger cards (96 × 96): consume too much vertical space in an already-tall
  modal. Rejected.
- Square images with rounded squircles vs. true 4 px radius: cosmetic only.
  Going with the simpler 4 px radius for consistency with `KpiCard`.

## R-9: Form state for the edit/create dialog

**Decision**: Single `quickExpenseEditFormProvider` (a
`NotifierProvider.family<QuickExpenseEditFormState, int?>`) keyed by the
QuickExpense id. Passing `null` opens the dialog in **create** mode; passing an
existing id opens it in **edit** mode.

**Rationale**:
- A single provider handles both flows (Save-from-+Gasto and Edit-from-Frecuentes-tab)
  and matches the "same edit dialog component" assumption recorded in the
  spec.
- The `family` parameter (`int?`) lets us hold multiple form instances if the
  user opens the dialog twice (rare, but harmless).

**Alternatives considered**:
- Two separate providers (`quickExpenseCreateFormProvider`,
  `quickExpenseEditFormProvider`): code duplication. Rejected.

## R-10: Test data for the in-memory DAO

**Decision**: Use Drift's `NativeDatabase.memory()` directly with
`AppDatabase.forTesting`. Existing tests for `transaction_dao_test.dart` and
`template_dao_test.dart` already use this pattern; we mirror it for
`quick_expense_dao_test.dart`.

**Rationale**: Established pattern in the repo. No alternative considered.

---

## Summary of resolved unknowns

All unknowns from the spec and from inspection of the existing codebase are
resolved. No `[NEEDS CLARIFICATION]` markers remain. The plan is ready for
Phase 1 (Design & Contracts).
