import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_services/shared_services.dart';
import '../../providers/auth_provider.dart';
import 'widgets/pin_input_widget.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.length != 4) return;
    final pin = _controller.text;
    _controller.clear();
    ref.read(authProvider.notifier).submitPin(pin);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isVerifying = authState is AuthStateVerifying;
    final error =
        authState is AuthStateNeedsAuth ? authState.error : null;

    String? errorText;
    if (error != null) {
      final attemptsInBlock = error.failedAttempts % 3;
      final remainingBeforeLockout = attemptsInBlock == 0 ? 3 : 3 - attemptsInBlock;
      errorText = 'Wrong PIN. '
          '$remainingBeforeLockout more wrong attempt${remainingBeforeLockout == 1 ? '' : 's'} '
          'before lockout.';
    }

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter Your PIN',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinInputWidget(
                controller: _controller,
                onPinComplete: _submit,
                enabled: !isVerifying,
                autofocus: true,
                labelText: 'PIN',
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (isVerifying) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
