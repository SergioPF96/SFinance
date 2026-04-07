import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable confirmation dialog for destructive actions.
///
/// Returns `true` if the user confirms, `false` if they cancel.
///
/// Usage:
/// ```dart
/// final confirmed = await showConfirmationDialog(
///   context: context,
///   title: 'Eliminar transaccion',
///   message: 'Esta accion no se puede deshacer.',
///   confirmLabel: 'Eliminar',
///   cancelLabel: 'Cancelar',
/// );
/// if (confirmed) { ... }
/// ```
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        title,
        style: const TextStyle(color: AppColors.onBackground),
      ),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.onBackgroundMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: AppColors.onBackgroundMuted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Convenience function to show [ConfirmationDialog] and await user response.
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmationDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}
