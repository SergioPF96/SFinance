import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/auth_provider.dart';
import 'package:sfinance/ui/auth/pin_setup_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer(AuthState initial) {
  return ProviderContainer(
    overrides: [
      authProvider.overrideWith(() => _StubAuthNotifier(initial)),
    ],
  );
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;

  @override
  Future<void> completeSetup(String pin) async {}
}

Widget _buildScreen(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: PinSetupScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests — T039
// ---------------------------------------------------------------------------

void main() {
  group('PinSetupScreen', () {
    testWidgets('submit button is disabled when PIN field has fewer than 4 digits',
        (tester) async {
      final container = _makeContainer(const AuthStateNeedsSetup());
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('submit button is disabled when confirm field has fewer than 4 digits',
        (tester) async {
      final container = _makeContainer(const AuthStateNeedsSetup());
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));

      // Fill only the first PIN field
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '1234');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('mismatched PINs show error and clear both fields', (tester) async {
      final container = _makeContainer(const AuthStateNeedsSetup());
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '1234');
      await tester.pump();
      await tester.enterText(textFields.at(1), '5678');
      await tester.pump();

      // Tap submit
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('PINs do not match. Try again.'), findsOneWidget);

      // Both fields should be cleared
      final firstField = tester.widget<TextField>(textFields.at(0));
      final secondField = tester.widget<TextField>(textFields.at(1));
      expect(firstField.controller?.text, isEmpty);
      expect(secondField.controller?.text, isEmpty);
    });

    testWidgets('irrecoverability warning text is visible', (tester) async {
      final container = _makeContainer(const AuthStateNeedsSetup());
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));

      expect(find.textContaining('cannot be recovered'), findsOneWidget);
    });
  });
}
