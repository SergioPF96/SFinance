import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_services/shared_services.dart';
import 'dao_providers.dart';

// ---------------------------------------------------------------------------
// Stream provider — used by QuickExpenseCardRow and FrecuentesTab
// ---------------------------------------------------------------------------

final quickExpensesStreamProvider =
    StreamProvider<List<QuickExpenseRow>>((ref) {
  return ref.watch(quickExpenseDaoProvider).watchAll();
});

// ---------------------------------------------------------------------------
// Edit-form state
// ---------------------------------------------------------------------------

class QuickExpenseEditFormState {
  const QuickExpenseEditFormState({
    this.name = '',
    this.amount = '',
    this.category,
    this.pickedImagePath,
    this.existingImagePath,
    this.removeExistingImage = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final String name;

  /// Raw string as typed by the user (may use comma as decimal separator).
  final String amount;

  final ExpenseCategory? category;

  /// Path selected by the OS file picker (not yet copied to internal storage).
  final String? pickedImagePath;

  /// Path of the image already stored in internal storage (edit mode only).
  final String? existingImagePath;

  /// True when the user tapped "Eliminar imagen" but has not yet saved.
  final bool removeExistingImage;

  final bool isSaving;
  final String? errorMessage;

  /// Confirmar button is enabled exactly when this is true.
  bool get canSave {
    if (name.trim().isEmpty) return false;
    final parsed = double.tryParse(amount.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return false;
    if (category == null) return false;
    return true;
  }

  /// True when the dialog should show an image (picked or existing, not removed).
  bool get hasImage =>
      !removeExistingImage &&
      (pickedImagePath != null || existingImagePath != null);

  QuickExpenseEditFormState copyWith({
    String? name,
    String? amount,
    ExpenseCategory? category,
    Object? pickedImagePath = _sentinel,
    Object? existingImagePath = _sentinel,
    bool? removeExistingImage,
    bool? isSaving,
    Object? errorMessage = _sentinel,
  }) {
    return QuickExpenseEditFormState(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      pickedImagePath: pickedImagePath == _sentinel
          ? this.pickedImagePath
          : pickedImagePath as String?,
      existingImagePath: existingImagePath == _sentinel
          ? this.existingImagePath
          : existingImagePath as String?,
      removeExistingImage: removeExistingImage ?? this.removeExistingImage,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// Edit-form notifier
// ---------------------------------------------------------------------------

class QuickExpenseEditFormNotifier
    extends AutoDisposeFamilyNotifier<QuickExpenseEditFormState, int?> {
  @override
  QuickExpenseEditFormState build(int? id) {
    if (id != null) {
      Future.microtask(() => _loadExisting(id));
    }
    return const QuickExpenseEditFormState();
  }

  Future<void> _loadExisting(int id) async {
    final row = await ref.read(quickExpenseDaoProvider).findById(id);
    if (row == null) return;
    final parsed = (row.amountCents / 100).toStringAsFixed(2);
    state = state.copyWith(
      name: row.name,
      amount: parsed.replaceAll('.', ','),
      category: ExpenseCategory.values.byName(row.category),
      existingImagePath: row.imagePath,
    );
  }

  void setName(String v) => state = state.copyWith(name: v);
  void setAmount(String v) => state = state.copyWith(amount: v);
  void setCategory(ExpenseCategory? v) => state = state.copyWith(category: v);

  void setPickedImage(String? path) => state = state.copyWith(
        pickedImagePath: path,
        removeExistingImage: false,
      );

  void removeImage() => state = state.copyWith(
        removeExistingImage: true,
        pickedImagePath: null,
      );

  /// Orchestrates image copy → DAO insert/update → old-image cleanup.
  ///
  /// Returns null on success, error message string on failure.
  Future<String?> save(int? id) async {
    if (!state.canSave) return 'Datos incompletos';

    state = state.copyWith(isSaving: true, errorMessage: null);

    final imageService = ref.read(imageStorageServiceProvider);
    final dao = ref.read(quickExpenseDaoProvider);

    final trimmedName = state.name.trim();
    final amountCents =
        (double.parse(state.amount.replaceAll(',', '.')) * 100).round();
    final categoryName = state.category!.name;

    String? newImagePath;
    String? oldImagePath;

    try {
      // --- Image copy (if a new image was picked) ---
      if (state.pickedImagePath != null) {
        if (id == null) {
          // Create mode: copy to temp; rename after insert
          final tempPath = await imageService.copyImageForNewQuickExpense(
            sourcePath: state.pickedImagePath!,
          );
          oldImagePath = state.existingImagePath;

          // Insert row
          final newId = await dao.insert(QuickExpensesCompanion.insert(
            name: trimmedName,
            amountCents: amountCents,
            category: categoryName,
            imagePath: const Value(null),
          ));

          final canonical =
              await imageService.assignTempFileToId(newId, tempPath);

          await dao.updateById(
            newId,
            QuickExpensesCompanion(imagePath: Value(canonical)),
          );

          state = const QuickExpenseEditFormState();
          _deleteOldImage(imageService, oldImagePath);
          return null;
        } else {
          // Edit mode with new image
          newImagePath = await imageService.copyImageForQuickExpense(
            quickExpenseId: id,
            sourcePath: state.pickedImagePath!,
          );
          oldImagePath = state.existingImagePath;
        }
      } else if (state.removeExistingImage) {
        oldImagePath = state.existingImagePath;
        newImagePath = null;
      } else {
        newImagePath = state.existingImagePath;
      }

      // --- DAO insert/update ---
      if (id == null) {
        // Create mode, no image
        await dao.insert(QuickExpensesCompanion.insert(
          name: trimmedName,
          amountCents: amountCents,
          category: categoryName,
          imagePath: Value(newImagePath),
        ));
      } else {
        // Edit mode
        await dao.updateById(
          id,
          QuickExpensesCompanion(
            name: Value(trimmedName),
            amountCents: Value(amountCents),
            category: Value(categoryName),
            imagePath: Value(newImagePath),
          ),
        );
      }

      state = const QuickExpenseEditFormState();
      _deleteOldImage(imageService, oldImagePath);
      return null;
    } on ImageCopyException catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al copiar la imagen: ${e.cause}',
      );
      return state.errorMessage;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar. Inténtalo de nuevo.',
      );
      return state.errorMessage;
    }
  }

  /// Deletes the quick expense row and its associated image (edit mode only).
  Future<void> deleteThis(int id) async {
    final imageService = ref.read(imageStorageServiceProvider);
    final dao = ref.read(quickExpenseDaoProvider);
    final row = await dao.findById(id);
    await dao.deleteById(id);
    if (row?.imagePath != null) {
      await imageService.deleteImageFile(row!.imagePath!);
    }
  }

  void _deleteOldImage(ImageStorageService service, String? path) {
    if (path != null) {
      service.deleteImageFile(path); // fire-and-forget best-effort
    }
  }
}

final quickExpenseEditFormProvider = NotifierProvider.family
    .autoDispose<QuickExpenseEditFormNotifier, QuickExpenseEditFormState, int?>(
  QuickExpenseEditFormNotifier.new,
);
