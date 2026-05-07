import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputWidget extends StatelessWidget {
  const PinInputWidget({
    super.key,
    required this.controller,
    required this.onPinComplete,
    this.enabled = true,
    this.autofocus = false,
    this.labelText,
  });

  final TextEditingController controller;
  final VoidCallback onPinComplete;
  final bool enabled;
  final bool autofocus;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: true,
      // TODO(android-keypad): numeric keyboard may show alphabetic keys on
      // some Android soft keyboards; verify on Android when porting.
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: labelText),
      onChanged: (value) {
        if (value.length == 4) onPinComplete();
      },
      onSubmitted: (_) {
        if (controller.text.length == 4) onPinComplete();
      },
    );
  }
}
