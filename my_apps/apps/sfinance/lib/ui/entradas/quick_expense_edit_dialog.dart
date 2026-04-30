import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/quick_expenses_provider.dart';
import '../../services/image_picker_service.dart';

/// Dialog for creating or editing a quick expense shortcut.
///
/// Create mode (id == null): shows only the image picker. Pass
/// [initialName], [initialAmount], [initialCategory] so the provider is seeded
/// in initState — before the first build — avoiding the AutoDispose race where
/// pre-seeding from the caller's ref.read is lost across a frame boundary.
/// Edit mode (id != null): shows all fields for full editing.
///
/// Pops with `true` on successful save, `false` on cancel.
class QuickExpenseEditDialog extends ConsumerStatefulWidget {
  const QuickExpenseEditDialog({
    super.key,
    required this.id,
    this.initialName,
    this.initialAmount,
    this.initialCategory,
  });

  final int? id;

  // Only used in create mode (id == null).
  final String? initialName;
  final String? initialAmount;
  final ExpenseCategory? initialCategory;

  @override
  ConsumerState<QuickExpenseEditDialog> createState() =>
      _QuickExpenseEditDialogState();
}

class _QuickExpenseEditDialogState
    extends ConsumerState<QuickExpenseEditDialog> {
  // Controllers only used in edit mode.
  TextEditingController? _nameCtrl;
  TextEditingController? _amountCtrl;
  final _imagePicker = const ImagePickerService();

  bool get _isEditMode => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final s = ref.read(quickExpenseEditFormProvider(widget.id));
      _nameCtrl = TextEditingController(text: s.name);
      _amountCtrl = TextEditingController(text: s.amount);
    } else {
      // Seed the provider after the first build via microtask — Riverpod forbids
      // state mutation inside initState. The microtask runs before the next frame
      // is painted so the button is enabled before the user can interact.
      Future.microtask(() {
        if (!mounted) return;
        final n = ref.read(quickExpenseEditFormProvider(null).notifier);
        if (widget.initialName != null) n.setName(widget.initialName!);
        if (widget.initialAmount != null) n.setAmount(widget.initialAmount!);
        if (widget.initialCategory != null) n.setCategory(widget.initialCategory);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl?.dispose();
    _amountCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickExpenseEditFormProvider(widget.id));
    final notifier =
        ref.read(quickExpenseEditFormProvider(widget.id).notifier);

    // Sync text controllers when edit-mode async load completes.
    if (_isEditMode) {
      ref.listen<QuickExpenseEditFormState>(
        quickExpenseEditFormProvider(widget.id),
        (prev, next) {
          if ((prev == null || prev.name.isEmpty) && next.name.isNotEmpty) {
            _nameCtrl?.text = next.name;
            _amountCtrl?.text = next.amount;
          }
        },
      );
    }

    final showExistingImage = state.existingImagePath != null &&
        !state.removeExistingImage &&
        state.pickedImagePath == null;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        _isEditMode ? 'Editar gasto común' : 'Guardar como gasto común',
        style: const TextStyle(color: AppColors.onBackground),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error banner
            if (state.errorMessage != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.expense.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.expense.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.expense, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.expense, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => notifier.save(widget.id),
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(color: AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Edit-mode fields (name / amount / category)
            if (_isEditMode) ...[
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.onBackground),
                decoration: const InputDecoration(labelText: 'Nombre'),
                onChanged: notifier.setName,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.onBackground),
                decoration: const InputDecoration(labelText: 'Importe (€)'),
                onChanged: notifier.setAmount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                key: ValueKey(state.category),
                initialValue: state.category,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.onBackground),
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: ExpenseCategory.values
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.displayLabel)))
                    .toList(),
                onChanged: notifier.setCategory,
              ),
              const SizedBox(height: 12),
            ],

            // Existing image preview (edit mode)
            if (showExistingImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(state.existingImagePath!),
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Image picker button
            OutlinedButton.icon(
              icon: const Icon(Icons.image_outlined,
                  color: AppColors.onBackgroundMuted),
              label: Text(
                state.hasImage ? 'Cambiar imagen' : 'Añadir imagen',
                style: const TextStyle(color: AppColors.onBackground),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.surfaceVariant),
              ),
              onPressed: () async {
                final path = await _imagePicker.pickImage();
                if (path != null) notifier.setPickedImage(path);
              },
            ),

            // Picked image preview
            if (state.pickedImagePath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(state.pickedImagePath!),
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            // Eliminar imagen
            if (state.hasImage) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.onBackgroundMuted, size: 18),
                label: const Text(
                  'Eliminar imagen',
                  style: TextStyle(color: AppColors.onBackgroundMuted),
                ),
                onPressed: notifier.removeImage,
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Cancelar — secondary text style
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onBackgroundMuted,
          ),
          child: const Text('Cancelar'),
        ),
        // Guardar — filled primary style; disabled state visually distinct from Cancelar
        ElevatedButton(
          onPressed: (state.canSave && !state.isSaving)
              ? () async {
                  final error = await notifier.save(widget.id);
                  if (error == null && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.balance,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceVariant,
            disabledForegroundColor: AppColors.onBackgroundMuted,
          ),
          child: state.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
