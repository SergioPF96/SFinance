import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import '../../providers/initial_capital_provider.dart';

// ---------------------------------------------------------------------------
// Usage — call from ResumenView once, after the first frame:
//
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     if (!kpi.hasTransactions && mounted) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const InitialCapitalDialog(),
//       );
//     }
//   });
// ---------------------------------------------------------------------------

class InitialCapitalDialog extends ConsumerStatefulWidget {
  const InitialCapitalDialog({super.key});

  @override
  ConsumerState<InitialCapitalDialog> createState() =>
      _InitialCapitalDialogState();
}

class _InitialCapitalDialogState extends ConsumerState<InitialCapitalDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Auto-focus so the user can start typing immediately.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final raw = _controller.text
        .replaceAll('.', '') // strip thousands separators
        .replaceAll(',', '.'); // normalise decimal separator
    final value = double.tryParse(raw);

    if (value == null || value <= 0) {
      setState(() => _error = 'Introduce un importe válido.');
      return;
    }

    setState(() { _saving = true; _error = null; });

    try {
      final cents = (value * 100).round();
      await ref
          .read(initialCapitalProvider.notifier)
          .setInitialCapital(cents);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Error al guardar.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              const Text(
                '¿Cuál es tu saldo actual?',
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu punto de partida para calcular el balance.',
                style: TextStyle(
                  color: AppColors.onBackgroundMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),

              // ── Input ────────────────────────────────────────────────────
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  EuroAmountFormatter(),
                ],
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  prefixText: '€  ',
                  prefixStyle: const TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  hintText: '0,00',
                  hintStyle: const TextStyle(
                    color: AppColors.onBackgroundMuted,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                  errorText: _error,
                  errorStyle: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.surfaceVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.surfaceVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.balance, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.expense, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppColors.expense, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _confirm(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 20),

              // ── Confirm button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.balance,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirmar saldo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              // ── Lock note ─────────────────────────────────────────────
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: AppColors.onBackgroundMuted,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Esto no se puede cambiar después',
                    style: TextStyle(
                      color: AppColors.onBackgroundMuted,
                      fontSize: 12,
                    ),
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

// ---------------------------------------------------------------------------
// EuroAmountFormatter
//
// Rules:
//   - Only digits, one comma (decimal separator), and up to 2 decimal places.
//   - Dot is accepted as decimal separator and converted to comma.
//   - Thousands are formatted with dots for readability (e.g. 1.200,50).
//   - Cursor position is preserved after reformatting.
// ---------------------------------------------------------------------------
class EuroAmountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String raw = newValue.text;

    // A trailing '.' or ',' means the user just typed a decimal separator.
    // Our formatted output never ends with '.' (only thousands-interior dots),
    // so a trailing '.' is always user intent. A trailing ',' is also decimal
    // intent (either freshly typed or kept after backspacing the decimal digits).
    final bool trailingDecimal = raw.endsWith('.') || raw.endsWith(',');

    // Strip ALL dots — in our output format dots are ALWAYS thousands separators,
    // never decimal separators. This is the key invariant that makes backspace work:
    // backspacing "1.234" yields "1.23"; stripping dots gives "123", not "1,23".
    raw = raw.replaceAll('.', '');

    // Find the decimal comma (if present).
    final int commaIdx = raw.indexOf(',');
    String intDigits;
    String? decDigits;

    if (commaIdx >= 0) {
      intDigits = raw.substring(0, commaIdx).replaceAll(RegExp(r'[^0-9]'), '');
      decDigits = raw.substring(commaIdx + 1).replaceAll(RegExp(r'[^0-9]'), '');
      if (decDigits.length > 2) decDigits = decDigits.substring(0, 2);
    } else {
      intDigits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      decDigits = null;
    }

    // Open decimal part when user typed a separator but no comma was extracted yet.
    if (trailingDecimal && decDigits == null) {
      decDigits = '';
    }

    final String formatted = decDigits != null
        ? '${_formatThousands(intDigits)},$decDigits'
        : _formatThousands(intDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatThousands(String digits) {
    if (digits.isEmpty) return digits;
    final buffer = StringBuffer();
    final length = digits.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
