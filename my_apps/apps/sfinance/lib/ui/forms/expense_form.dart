import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/form_providers.dart';

/// Expense entry modal form ("+ Gasto").
///
/// US1: shows Producto, Servicio, SuministroVariable categories only.
/// US3: adds Suscripcion, Financiacion with Periodicidad and FechaFin fields.
class ExpenseForm extends ConsumerWidget {
  const ExpenseForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseFormProvider);
    final notifier = ref.read(expenseFormProvider.notifier);

    return Dialog(
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nuevo Gasto',
                    style: TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onBackgroundMuted),
                    onPressed: () => context.pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre
              _FormField(
                label: 'Nombre',
                autofocus: true,
                onChanged: notifier.setNombre,
                value: state.nombre,
              ),
              const SizedBox(height: 12),

              // Monto
              _FormField(
                label: 'Importe (€)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: notifier.setMonto,
                value: state.monto,
              ),
              const SizedBox(height: 12),

              // Descripcion
              _FormField(
                label: 'Descripcion (opcional)',
                onChanged: notifier.setDescripcion,
                value: state.descripcion,
              ),
              const SizedBox(height: 12),

              // Categoria
              _CategoryDropdown(
                value: state.categoria,
                onChanged: notifier.setCategoria,
              ),

              // Periodicidad (only for recurring categories)
              if (state.isRecurring) ...[
                const SizedBox(height: 12),
                _PeriodicidadDropdown(
                  value: state.periodicidad,
                  onChanged: notifier.setPeriodicidad,
                ),
              ],

              // Fecha de fin (only when periodicidad is set)
              if (state.isRecurring && state.periodicidad != null) ...[
                const SizedBox(height: 12),
                _FechaFinPicker(
                  periodicidad: state.periodicidad!,
                  value: state.fechaFin,
                  onChanged: notifier.setFechaFin,
                ),
              ],

              // Error message
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.expense, fontSize: 13),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppColors.onBackgroundMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () async {
                            final error = await notifier.submit();
                            if (error == null && context.mounted) {
                              context.pop();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                    ),
                    child: state.isSubmitting
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.onChanged,
    required this.value,
    this.keyboardType,
    this.autofocus = false,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final String value;
  final TextInputType? keyboardType;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: autofocus,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.onBackground),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final ExpenseCategory? value;
  final ValueChanged<ExpenseCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExpenseCategory>(
      value: value,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.onBackground),
      decoration: const InputDecoration(labelText: 'Categoria'),
      items: ExpenseCategory.values
          .map((c) => DropdownMenuItem(value: c, child: Text(c.displayLabel)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _PeriodicidadDropdown extends StatelessWidget {
  const _PeriodicidadDropdown({required this.value, required this.onChanged});

  final Periodicity? value;
  final ValueChanged<Periodicity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Periodicity>(
      value: value,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.onBackground),
      decoration: const InputDecoration(labelText: 'Periodicidad'),
      items: Periodicity.values
          .map((p) => DropdownMenuItem(value: p, child: Text(p.displayLabel)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _FechaFinPicker extends StatelessWidget {
  const _FechaFinPicker({
    required this.periodicidad,
    required this.value,
    required this.onChanged,
  });

  final Periodicity periodicidad;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  String get _label {
    if (value == null) return 'Seleccionar fecha de fin';
    if (periodicidad == Periodicity.anual) return '${value!.year}';
    return '${_monthName(value!.month)} de ${value!.year}';
  }

  String _monthName(int month) {
    const names = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, color: AppColors.onBackgroundMuted, size: 16),
      label: Text(
        _label,
        style: const TextStyle(color: AppColors.onBackground),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.surfaceVariant),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () async {
        final now = DateTime.now();
        if (periodicidad == Periodicity.anual) {
          // Year-only picker: use showDatePicker restricted to Jan 1
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(now.year, 1, 1),
            firstDate: DateTime(now.year, 1, 1),
            lastDate: DateTime(now.year + 30, 12, 31),
            helpText: 'Seleccionar año de fin',
          );
          if (picked != null) onChanged(DateTime(picked.year, 12, 31));
        } else {
          // Month + year picker
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(now.year, now.month, 1),
            firstDate: DateTime(now.year, now.month, 1),
            lastDate: DateTime(now.year + 30, 12, 31),
            helpText: 'Seleccionar mes y año de fin',
          );
          if (picked != null) {
            onChanged(DateTime(picked.year, picked.month + 1, 0));
          }
        }
      },
    );
  }
}
