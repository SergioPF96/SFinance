import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_services/shared_services.dart';
import 'package:sfinance/providers/auth_provider.dart';
import 'package:sfinance/ui/auth/pin_entry_screen.dart';

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
  Future<void> submitPin(String pin) async {}
}

Widget _buildScreen(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: PinEntryScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests — T040
// ---------------------------------------------------------------------------

void main() {
  group('PinEntryScreen', () {
    testWidgets('shows spinner and disabled input while AuthStateVerifying',
        (tester) async {
      final container = _makeContainer(const AuthStateVerifying());
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('shows remaining-attempts error when AuthStateNeedsAuth has error',
        (tester) async {
      const error = WrongPinException(failedAttempts: 1, newLockout: null);
      final container =
          _makeContainer(const AuthStateNeedsAuth(error: error));
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));

      expect(find.textContaining('Wrong PIN'), findsOneWidget);
      expect(find.textContaining('before lockout'), findsOneWidget);
    });

    testWidgets('no spinner when AuthStateNeedsAuth (no error)', (tester) async {
      final container = _makeContainer(const AuthStateNeedsAuth());
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildScreen(container));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
