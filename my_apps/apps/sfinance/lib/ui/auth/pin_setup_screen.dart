import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import '../../providers/auth_provider.dart';
import 'widgets/pin_input_widget.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;
  String _pin = '';
  String _confirm = '';

  @override
  void initState() {
    super.initState();
    _pinController.addListener(() => setState(() => _pin = _pinController.text));
    _confirmController.addListener(
        () => setState(() => _confirm = _confirmController.text));
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pin.length != 4 || _confirm.length != 4) return;
    if (_pin != _confirm) {
      setState(() => _errorText = 'PINs do not match. Try again.');
      _pinController.clear();
      _confirmController.clear();
      return;
    }
    setState(() => _errorText = null);
    ref.read(authProvider.notifier).completeSetup(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isVerifying = authState is AuthStateVerifying;
    final canSubmit = !isVerifying && _pin.length == 4 && _confirm.length == 4;

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Your PIN',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠ Warning: if you forget your PIN, your financial data '
                'cannot be recovered. There is no password reset.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinInputWidget(
                controller: _pinController,
                onPinComplete: () {},
                enabled: !isVerifying,
                autofocus: true,
                labelText: 'PIN',
              ),
              const SizedBox(height: 16),
              PinInputWidget(
                controller: _confirmController,
                onPinComplete: _submit,
                enabled: !isVerifying,
                labelText: 'Confirm PIN',
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (isVerifying)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  child: const Text('Set PIN'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
