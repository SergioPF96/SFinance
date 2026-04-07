import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/form_providers.dart';

/// Income entry modal form ("+ Ingreso").
///
/// Always shown: nombre, monto, descripcion, categoria.
/// When categoria=Salario: numeroPagas dropdown.
/// When numeroPagas=catorcepagas: two month pickers for extra pay.
class IncomeForm extends ConsumerWidget {
  const IncomeForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incomeFormProvider);
    final notifier = ref.read(incomeFormProvider.notifier);

    return Dialog(
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nuevo Ingreso',
                      style: TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.onBackgroundMuted),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                _CategoriaDropdown(
                  value: state.categoria,
                  onChanged: notifier.setCategoria,
                ),

                // NumeroPagas — only for Salario
                if (state.isSalario) ...[
                  const SizedBox(height: 12),
                  _NumeroPagasDropdown(
                    value: state.numeroPagas,
                    onChanged: notifier.setNumeroPagas,
                  ),
                ],

                // Extra pay month pickers — only for 14 pagas
                if (state.isSalario && state.isCatorcepagas) ...[
                  const SizedBox(height: 12),
                  _MonthPicker(
                    label: 'Primer mes de paga extra',
                    value: state.primeraPagaExtra,
                    exclude: state.segundaPagaExtra,
                    onChanged: notifier.setPrimeraPagaExtra,
                  ),
                  const SizedBox(height: 12),
                  _MonthPicker(
                    label: 'Segundo mes de paga extra',
                    value: state.segundaPagaExtra,
                    exclude: state.primeraPagaExtra,
                    onChanged: notifier.setSegundaPagaExtra,
                  ),
                ],

                // Error
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    style:
                        const TextStyle(color: AppColors.expense, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Cancelar',
                        style:
                            TextStyle(color: AppColors.onBackgroundMuted),
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
                        backgroundColor: AppColors.income,
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

class _CategoriaDropdown extends StatelessWidget {
  const _CategoriaDropdown({required this.value, required this.onChanged});

  final IncomeCategory? value;
  final ValueChanged<IncomeCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<IncomeCategory>(
      value: value,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.onBackground),
      decoration: const InputDecoration(labelText: 'Categoria'),
      items: IncomeCategory.values
          .map((c) => DropdownMenuItem(value: c, child: Text(c.displayLabel)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _NumeroPagasDropdown extends StatelessWidget {
  const _NumeroPagasDropdown({required this.value, required this.onChanged});

  final PayFrequency? value;
  final ValueChanged<PayFrequency?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PayFrequency>(
      value: value,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.onBackground),
      decoration: const InputDecoration(labelText: 'Numero de pagas'),
      items: PayFrequency.values
          .map((p) => DropdownMenuItem(value: p, child: Text(p.displayLabel)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.label,
    required this.value,
    required this.onChanged,
    this.exclude,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final int? exclude;

  static const _months = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.onBackground),
      decoration: InputDecoration(labelText: label),
      items: List.generate(12, (i) => i + 1)
          .where((m) => m != exclude)
          .map((m) => DropdownMenuItem(value: m, child: Text(_months[m])))
          .toList(),
      onChanged: onChanged,
    );
  }
}
