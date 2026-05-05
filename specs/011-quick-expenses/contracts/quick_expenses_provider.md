# Contract: `quickExpensesProvider` and edit-form provider

**Location**: `apps/sfinance/lib/providers/quick_expenses_provider.dart`

Two globally-scoped Riverpod providers expose QuickExpense data to widgets.

## Provider 1 — `quickExpensesStreamProvider`

```dart
/// Stream of all quick expenses, ordered by createdAt ASC (oldest first).
/// Re-emits on every DB mutation.
final quickExpensesStreamProvider =
    StreamProvider<List<QuickExpenseRow>>((ref) {
  return ref.watch(quickExpenseDaoProvider).watchAll();
});
```

Used by:
- `QuickExpenseCardRow` widget (inside the +Gasto modal): to render one card
  per quick expense at the top of the form
- `FrecuentesTab` widget: to render the list with edit/delete affordances

## Provider 2 — `quickExpenseEditFormProvider`

```dart
/// Form state for the create-or-edit dialog.
/// `int?` parameter: null ⇒ create mode, non-null ⇒ edit mode (load existing).
final quickExpenseEditFormProvider = NotifierProvider.family
    .autoDispose<QuickExpenseEditFormNotifier, QuickExpenseEditFormState, int?>(
        QuickExpenseEditFormNotifier.new);

class QuickExpenseEditFormState {
  const QuickExpenseEditFormState({
    this.name = '',
    this.amount = '',                 // raw string the user typed
    this.category,
    this.pickedImagePath,             // path the user just picked (not yet copied)
    this.existingImagePath,           // path stored in the DB (edit mode only)
    this.removeExistingImage = false, // user pressed "Eliminar imagen"
    this.isSaving = false,
    this.errorMessage,
  });

  final String name;
  final String amount;
  final ExpenseCategory? category;
  final String? pickedImagePath;
  final String? existingImagePath;
  final bool removeExistingImage;
  final bool isSaving;
  final String? errorMessage;

  bool get canSave =>
      name.trim().isNotEmpty &&
      double.tryParse(amount.replaceAll(',', '.')) != null &&
      double.parse(amount.replaceAll(',', '.')) > 0 &&
      category != null;

  bool get hasImage =>
      !removeExistingImage &&
      (pickedImagePath != null || existingImagePath != null);

  QuickExpenseEditFormState copyWith({...});
}

class QuickExpenseEditFormNotifier
    extends FamilyNotifier<QuickExpenseEditFormState, int?> {
  @override
  QuickExpenseEditFormState build(int? id) {
    if (id != null) {
      // load row asynchronously and seed state
      // (uses a microtask to avoid build-time async; widget shows spinner)
      _loadExisting(id);
    }
    return const QuickExpenseEditFormState();
  }

  Future<void> _loadExisting(int id);
  void setName(String v);
  void setAmount(String v);
  void setCategory(ExpenseCategory? v);
  void setPickedImage(String? path);
  void removeImage();          // sets removeExistingImage=true, clears picked

  /// Returns null on success, error message on failure.
  /// Orchestrates: image copy → DAO insert/update → old-image cleanup.
  Future<String?> save();
  Future<void> deleteThis();   // edit mode only; for the delete-from-dialog flow
}
```

## Provider 3 — helper for "Save current expense form as quick expense"

```dart
/// Captures the +Gasto form's current name/amount/category and opens the
/// edit dialog in CREATE mode pre-loaded with those values.
/// Returns the new QuickExpense id on success, or null if the user cancelled.
Future<int?> openSaveAsQuickExpenseDialog(
  BuildContext context,
  WidgetRef ref,
);
```

Implementation reads `expenseFormProvider.state` for name/amount/category,
seeds the `quickExpenseEditFormProvider(null)` with those values, and shows
the dialog.

## Behavioral contract

- The disabled state of "Guardar como gasto común" in the +Gasto modal is
  derived from `expenseFormProvider`'s state, not from this provider. The
  spec wording (FR-004) only references the +Gasto form's name and amount
  fields, not the QuickExpenseEditFormState.
- The edit dialog's "Confirmar" button is enabled exactly when
  `state.canSave == true`. Same validation rule as +Gasto's button.
- `save()` on success: dialog closes via `Navigator.pop(context, true)`. UI
  shows a success snackbar (handled by the caller, not the notifier).
- `save()` on image copy failure: dialog stays open, error banner shown,
  "Reintentar" button re-runs `save()`.
- `deleteThis()` is invoked only after `ConfirmationDialog` returns true
  (the modal confirmation step from spec clarification Q5).

## Test contract (`quick_expense_form_notifier_test.dart`)

Tests use a `ProviderContainer` with overrides for `quickExpenseDaoProvider`
(in-memory Drift) and `imageStorageServiceProvider` (using a temp dir).

- `canSave` becomes true only when name+amount+category are all valid
- `setPickedImage` updates state without touching the filesystem
- `removeImage()` sets the flag without touching the filesystem
- `save()` create-mode happy path: row inserted, image copied, state reset
- `save()` create-mode without image: row inserted with `imagePath = null`
- `save()` edit-mode replacing image: new file copied, row updated, old
  file deleted
- `save()` edit-mode removing image: row updated to `imagePath=null`,
  old file deleted
- `save()` image copy failure: state.errorMessage set, no DAO call made
- `deleteThis()`: row deleted, image file (if any) deleted
- Resetting form after save: state is freshly built on next dialog open
