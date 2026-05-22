import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/features/auth/presentation/providers/auth_provider.dart';
import 'package:ruta_viva/features/user_profile/presentation/pages/profile_screen.dart';

void main() {
  group('ProfileScreen estados', () {
    testWidgets('muestra skeleton durante carga', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _NotifierWithState(const AuthState(isLoading: true)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('muestra error banner cuando hay error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _NotifierWithState(
                const AuthState(errorMessage: 'No se pudo cargar el perfil.'),
              ),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('No se pudo cargar el perfil.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}

class _NotifierWithState extends AuthNotifier {
  final AuthState _fakeState;

  _NotifierWithState(this._fakeState);

  @override
  AuthState build() => _fakeState;
}
